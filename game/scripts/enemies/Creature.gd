extends CharacterBody3D

# ═══════════════════════════════════════════════════════
#  THE CREATURE — Main Enemy AI
#  State machine: IDLE → PATROL → INVESTIGATE → HUNT → ATTACK
#  Uses NavigationAgent3D for pathfinding
#  Hears footsteps, sees light, smells fear
# ═══════════════════════════════════════════════════════

enum State { IDLE, PATROL, INVESTIGATE, HUNT, ATTACK, STUNNED }

@onready var nav_agent: NavigationAgent3D     = $NavigationAgent3D
@onready var sight_cone: Area3D               = $SightCone
@onready var hearing_area: Area3D             = $HearingArea
@onready var anim_player: AnimationPlayer     = $AnimationPlayer
@onready var audio: AudioStreamPlayer3D       = $AudioStreamPlayer3D
@onready var footstep_audio: AudioStreamPlayer3D = $FootstepAudio
@onready var eyes: Node3D                     = $Eyes

# ── Settings ───────────────────────────────────────────
@export_group("Movement")
@export var patrol_speed:  float = 1.8
@export var hunt_speed:    float = 5.5
@export var attack_range:  float = 1.8
@export var turn_speed:    float = 5.0

@export_group("Detection")
@export var sight_distance:    float = 12.0
@export var sight_angle:       float = 65.0   # degrees half-angle
@export var hearing_radius:    float = 18.0
@export var flashlight_range:  float = 25.0   # can see flashlight beam far away

@export_group("Patrol")
@export var patrol_points: Array[NodePath] = []
@export var wait_time_min: float = 2.0
@export var wait_time_max: float = 5.0

# ── Runtime state ──────────────────────────────────────
var current_state: State = State.PATROL
var player: CharacterBody3D = null
var _last_known_position: Vector3 = Vector3.ZERO
var _patrol_index: int = 0
var _wait_timer: float = 0.0
var _suspicion: float = 0.0       # 0-1, fills when suspicious
var _is_waiting: bool = false
var _stun_timer: float = 0.0
var _patrol_nodes: Array[Node3D] = []
var _step_timer: float = 0.0

# Suspicion rates
const SUSPICION_RISE_SIGHT  = 0.8   # per second when player is in sight
const SUSPICION_RISE_SOUND  = 0.4   # per second when loud sound detected
const SUSPICION_FALL        = 0.15  # per second when no stimulus
const HUNT_THRESHOLD        = 0.85  # suspicion level that triggers hunt
const INVESTIGATE_THRESHOLD = 0.3

signal player_spotted()
signal player_lost()
signal attack_player()

func _ready() -> void:
	for path in patrol_points:
		var node = get_node_or_null(path)
		if node:
			_patrol_nodes.append(node)
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.8
	# Find player
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:       _state_idle(delta)
		State.PATROL:     _state_patrol(delta)
		State.INVESTIGATE:_state_investigate(delta)
		State.HUNT:       _state_hunt(delta)
		State.ATTACK:     _state_attack(delta)
		State.STUNNED:    _state_stunned(delta)
	_update_fear_contribution()
	_handle_footstep(delta)
	move_and_slide()

# ════════════════════════════════════════════════════════
#  STATES
# ════════════════════════════════════════════════════════
func _state_idle(delta: float) -> void:
	_wait_timer -= delta
	if _wait_timer <= 0.0:
		_set_state(State.PATROL)

func _state_patrol(delta: float) -> void:
	if _patrol_nodes.is_empty():
		_set_state(State.IDLE)
		return
	if _is_waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_is_waiting = false
			_patrol_index = (_patrol_index + 1) % _patrol_nodes.size()
		return
	var target = _patrol_nodes[_patrol_index].global_position
	nav_agent.set_target_position(target)
	_move_toward_target(patrol_speed, delta)
	if nav_agent.is_navigation_finished():
		_is_waiting = true
		_wait_timer = randf_range(wait_time_min, wait_time_max)
		anim_player.play("idle")
	# Check for player during patrol
	_check_senses(delta)

func _state_investigate(delta: float) -> void:
	nav_agent.set_target_position(_last_known_position)
	_move_toward_target(patrol_speed * 1.4, delta)
	_check_senses(delta)
	# Reduce suspicion while investigating
	_suspicion = maxf(_suspicion - SUSPICION_FALL * 0.3 * delta, 0.0)
	if nav_agent.is_navigation_finished():
		# Arrived at last known pos — look around
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_set_state(State.PATROL)

func _state_hunt(delta: float) -> void:
	if not player:
		return
	_last_known_position = player.global_position
	nav_agent.set_target_position(_last_known_position)
	_move_toward_target(hunt_speed, delta)
	# Check for attack range
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range:
		_set_state(State.ATTACK)
	# Lose player if out of sight for long
	if not _can_see_player():
		_suspicion = maxf(_suspicion - SUSPICION_FALL * delta, 0.0)
		if _suspicion < 0.2:
			player_lost.emit()
			_set_state(State.INVESTIGATE)
			_wait_timer = 8.0

func _state_attack(delta: float) -> void:
	if not player:
		return
	# Face the player
	var dir = (player.global_position - global_position).normalized()
	dir.y = 0
	if dir.length() > 0.01:
		var target_rot = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 10.0)
	velocity = Vector3.ZERO
	attack_player.emit()
	if player.has_method("take_damage"):
		player.take_damage(35.0)
	# After attack, go back to hunt
	await get_tree().create_timer(1.2).timeout
	_set_state(State.HUNT)

func _state_stunned(delta: float) -> void:
	_stun_timer -= delta
	velocity = Vector3.ZERO
	if _stun_timer <= 0.0:
		_set_state(State.PATROL)

# ════════════════════════════════════════════════════════
#  SENSING
# ════════════════════════════════════════════════════════
func _check_senses(delta: float) -> void:
	if not player:
		return
	var stimulus: float = 0.0
	if _can_see_player():
		stimulus += SUSPICION_RISE_SIGHT * delta
	if _can_hear_player():
		stimulus += SUSPICION_RISE_SOUND * delta
	if _can_see_flashlight():
		stimulus += SUSPICION_RISE_SIGHT * 0.5 * delta
	if stimulus > 0.0:
		_suspicion = minf(_suspicion + stimulus, 1.0)
	else:
		_suspicion = maxf(_suspicion - SUSPICION_FALL * delta, 0.0)
	if _suspicion >= HUNT_THRESHOLD:
		player_spotted.emit()
		_last_known_position = player.global_position
		_set_state(State.HUNT)
	elif _suspicion >= INVESTIGATE_THRESHOLD and current_state == State.PATROL:
		_last_known_position = player.global_position
		_set_state(State.INVESTIGATE)
		_wait_timer = 6.0

func _can_see_player() -> bool:
	if not player:
		return false
	var to_player = player.global_position - eyes.global_position
	if to_player.length() > sight_distance:
		return false
	var angle = rad_to_deg(to_player.normalized().angle_to(-eyes.global_transform.basis.z))
	if angle > sight_angle:
		return false
	# Raycast check for line of sight
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		eyes.global_position, player.global_position)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	if result.is_empty():
		return false
	return result.collider == player

func _can_hear_player() -> bool:
	if not player:
		return false
	var dist = global_position.distance_to(player.global_position)
	if dist > hearing_radius:
		return false
	# Crouching players are much quieter
	if player.has_method("is_crouching") and player.is_crouching():
		return dist < hearing_radius * 0.35
	# Sprinting players are loud
	if player.has_method("is_sprinting") and player.is_sprinting():
		return dist < hearing_radius * 1.0
	return dist < hearing_radius * 0.55

func _can_see_flashlight() -> bool:
	if not player or not player.has_method("is_flashlight_on"):
		return false
	if not player.is_flashlight_on():
		return false
	return global_position.distance_to(player.global_position) < flashlight_range

# ════════════════════════════════════════════════════════
#  MOVEMENT & HELPERS
# ════════════════════════════════════════════════════════
func _move_toward_target(speed: float, delta: float) -> void:
	var next = nav_agent.get_next_path_position()
	var dir  = (next - global_position).normalized()
	velocity = dir * speed
	# Smooth rotation toward movement direction
	dir.y = 0
	if dir.length() > 0.01:
		var target_angle = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * turn_speed)
	# Animation
	anim_player.play("walk" if speed <= patrol_speed else "run")

func _set_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:
			anim_player.play("idle")
			velocity = Vector3.ZERO
		State.HUNT:
			anim_player.play("run")
		State.STUNNED:
			anim_player.play("stun")
			velocity = Vector3.ZERO

func _update_fear_contribution() -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	match current_state:
		State.HUNT:
			var proximity_fear = 1.0 - clampf(dist / 15.0, 0.0, 1.0)
			FearSystem.add_fear("creature_hunting", proximity_fear * 0.9)
		State.INVESTIGATE:
			FearSystem.add_fear("creature_hunting", 0.3)
		State.PATROL:
			var ambient_fear = 1.0 - clampf(dist / 20.0, 0.0, 1.0)
			FearSystem.add_fear("creature_hunting", ambient_fear * 0.15)
		_:
			FearSystem.remove_fear("creature_hunting")

func _handle_footstep(delta: float) -> void:
	var speed = velocity.length()
	if speed < 0.5:
		return
	var interval = 0.55 if speed <= patrol_speed else 0.30
	_step_timer -= delta
	if _step_timer <= 0.0:
		footstep_audio.play()
		_step_timer = interval

# Called when player uses a distraction item
func alert_to_position(pos: Vector3) -> void:
	_last_known_position = pos
	_suspicion = 0.5
	_set_state(State.INVESTIGATE)
	_wait_timer = 5.0

func stun(duration: float) -> void:
	_stun_timer = duration
	_set_state(State.STUNNED)
