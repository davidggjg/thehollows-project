extends CharacterBody3D

# ═══════════════════════════════════════════════════════
#  PLAYER CONTROLLER
#  Third-person over-the-shoulder, full horror mechanics
# ═══════════════════════════════════════════════════════

# ── Node references ────────────────────────────────────
@onready var camera_pivot: Node3D       = $CameraPivot
@onready var camera: Camera3D           = $CameraPivot/SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D    = $CameraPivot/SpringArm3D
@onready var flashlight: SpotLight3D    = $CameraPivot/SpringArm3D/Camera3D/Flashlight
@onready var anim_tree: AnimationTree   = $AnimationTree
@onready var interact_ray: RayCast3D    = $CameraPivot/SpringArm3D/Camera3D/InteractRay
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@onready var breath_player: AudioStreamPlayer3D   = $BreathPlayer
@onready var hide_detector: Area3D      = $HideDetector

# ── Movement settings ─────────────────────────────────
@export_group("Movement")
@export var walk_speed:    float = 3.2
@export var sprint_speed:  float = 6.0
@export var crouch_speed:  float = 1.4
@export var gravity:       float = 18.0
@export var mouse_sensitivity: float = 0.25

# ── Camera settings ────────────────────────────────────
@export_group("Camera")
@export var camera_distance_normal: float = 2.2
@export var camera_distance_crouch: float = 1.6
@export var camera_height_normal:   float = 1.6
@export var camera_height_crouch:   float = 0.9
@export var camera_pitch_min: float = -45.0
@export var camera_pitch_max: float = 55.0

# ── Flashlight ──────────────────────────────────────────
@export_group("Flashlight")
@export var battery_max:        float = 180.0  # seconds
@export var battery_drain:      float = 1.0
@export var battery_critical:   float = 20.0

# ── State ──────────────────────────────────────────────
var is_crouching:  bool  = false
var is_sprinting:  bool  = false
var is_hiding:     bool  = false
var is_dead:       bool  = false
var flashlight_on: bool  = false
var battery:       float = 180.0
var health:        float = 100.0
var _camera_pitch: float = 0.0
var _step_timer:   float = 0.0
var _flicker_timer: float = 0.0
var _can_interact: bool = true
var _current_hide_spot = null

# Footstep intervals
const STEP_WALK   = 0.52
const STEP_SPRINT = 0.30
const STEP_CROUCH = 0.82

signal health_changed(new_health: float)
signal interacted(target: Node)
signal hiding_changed(hiding: bool)
signal flashlight_toggled(on: bool)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.spring_length = camera_distance_normal
	camera_pivot.position.y  = camera_height_normal
	if flashlight:
		flashlight.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_dead:
		_rotate_camera(event.relative)
	if Input.is_action_just_pressed("flashlight"):
		_toggle_flashlight()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("crouch"):
		_toggle_crouch()
	if Input.is_action_just_pressed("hide"):
		_try_hide()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_flashlight(delta)
	_handle_footsteps(delta)
	_handle_fear_visuals()
	_update_camera_smoothly(delta)
	move_and_slide()

# ── CAMERA ─────────────────────────────────────────────
func _rotate_camera(mouse_delta: Vector2) -> void:
	var sens = mouse_sensitivity
	# Horizontal — rotate whole body
	rotate_y(-mouse_delta.x * sens * 0.01)
	# Vertical — pitch only camera pivot
	_camera_pitch -= mouse_delta.y * sens * 0.01
	_camera_pitch = clampf(_camera_pitch,
		deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))
	camera_pivot.rotation.x = _camera_pitch

func _update_camera_smoothly(delta: float) -> void:
	var target_height = camera_height_crouch if is_crouching else camera_height_normal
	var target_dist   = camera_distance_crouch if is_crouching else camera_distance_normal
	camera_pivot.position.y = lerp(camera_pivot.position.y, target_height, delta * 8.0)
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_dist, delta * 8.0)

# ── MOVEMENT ────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_movement(delta: float) -> void:
	if is_hiding:
		velocity = Vector3.ZERO
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir  = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and input_dir.y < 0
	var speed = crouch_speed if is_crouching else (sprint_speed if is_sprinting else walk_speed)

	# Sprinting increases fear (footsteps are louder → creature hears)
	if is_sprinting:
		FearSystem.add_fear("sprinting", 0.15)
	else:
		FearSystem.remove_fear("sprinting")

	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	# Animation state machine
	if anim_tree:
		anim_tree.set("parameters/blend_position", Vector2(input_dir.x, -input_dir.y))
		anim_tree.set("parameters/speed_scale", speed / walk_speed)

# ── CROUCH ──────────────────────────────────────────────
func _toggle_crouch() -> void:
	if is_crouching:
		# Check for ceiling before standing
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			global_position, global_position + Vector3.UP * 1.4)
		if not space.intersect_ray(query):
			is_crouching = false
	else:
		is_crouching = true

# ── FLASHLIGHT ──────────────────────────────────────────
func _toggle_flashlight() -> void:
	if not flashlight:
		return
	flashlight_on = !flashlight_on
	flashlight.visible = flashlight_on
	flashlight_toggled.emit(flashlight_on)
	# Flashlight attracts creature when on
	if flashlight_on:
		FearSystem.add_fear("using_flashlight", 0.05)
	else:
		FearSystem.remove_fear("using_flashlight")

func _handle_flashlight(delta: float) -> void:
	if not flashlight or not flashlight_on:
		return
	battery -= battery_drain * delta
	battery = maxf(battery, 0.0)
	if battery <= 0.0:
		flashlight_on = false
		flashlight.visible = false
		FearSystem.fear_spike(0.3)   # Darkness = fear spike
		return
	# Flicker near critical
	if battery < battery_critical:
		_flicker_timer -= delta
		if _flicker_timer <= 0.0:
			flashlight.light_energy = randf_range(0.2, 1.0)
			_flicker_timer = randf_range(0.04, 0.2)
	else:
		flashlight.light_energy = lerp(0.3, 1.0, battery / battery_max)

# ── FOOTSTEPS ───────────────────────────────────────────
func _handle_footsteps(delta: float) -> void:
	if not is_on_floor() or velocity.length() < 0.5:
		_step_timer = 0.0
		return
	var interval = STEP_CROUCH if is_crouching else (STEP_SPRINT if is_sprinting else STEP_WALK)
	_step_timer -= delta
	if _step_timer <= 0.0:
		_play_footstep()
		_step_timer = interval

func _play_footstep() -> void:
	# Volume scales with movement speed — affects creature hearing
	var vol = -20.0 if is_crouching else (-8.0 if is_sprinting else -14.0)
	footstep_player.volume_db = vol
	footstep_player.play()

# ── INTERACTION ─────────────────────────────────────────
func _try_interact() -> void:
	if not _can_interact or not interact_ray:
		return
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		if target and target.has_method("interact"):
			target.interact(self)
			interacted.emit(target)

# ── HIDING ──────────────────────────────────────────────
func _try_hide() -> void:
	# Look for a hide spot in range
	for body in hide_detector.get_overlapping_bodies():
		if body.has_method("enter_hide") and not is_hiding:
			body.enter_hide(self)
			is_hiding = true
			_current_hide_spot = body
			FearSystem.remove_fear("sprinting")
			hiding_changed.emit(true)
			return
	# Already hiding — exit
	if is_hiding and _current_hide_spot:
		_current_hide_spot.exit_hide(self)
		is_hiding = false
		_current_hide_spot = null
		hiding_changed.emit(false)

# ── FEAR VISUALS ────────────────────────────────────────
func _handle_fear_visuals() -> void:
	# These drive the post-process shader via shader parameters
	var intensity = FearSystem.get_visual_intensity()
	# Pass to WorldEnvironment via a global shader parameter
	RenderingServer.global_shader_parameter_set("fear_level", intensity)
	RenderingServer.global_shader_parameter_set("sanity_level", FearSystem.get_sanity() / 100.0)

# ── DAMAGE ──────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	health_changed.emit(health)
	FearSystem.fear_spike(amount / 100.0 * 0.5)
	if health <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	GameManager.player_died()

# ── PUBLIC API ───────────────────────────────────────────
func get_health() -> float:
	return health

func get_battery() -> float:
	return battery / battery_max

func is_flashlight_on() -> bool:
	return flashlight_on

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
