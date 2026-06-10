extends LevelBase

# ═══════════════════════════════════════════════════════
#  LEVEL 1: VESPER TOWERS — The Apartment Complex
#  Floors 1-9, basement entrance
#  Creature: not yet present — building dread
#  Horror: environmental, psychological
# ═══════════════════════════════════════════════════════

@onready var elevator: Node3D   = $Elevator
@onready var lights_flickering: Array = []
@onready var radio: Node3D      = $Floor3/Radio

var _creature_spawned: bool = false
var _power_cut: bool = false
var _flicker_timer: float = 0.0

func _setup_environment() -> void:
	level_index = 0
	level_objectives = [
		"Find the building maintenance records",
		"Locate the basement access key",
		"Reach the basement — Sub-Level B2",
	]
	# Start flickering lights on floors 4+
	for light in get_tree().get_nodes_in_group("flickering_light"):
		lights_flickering.append(light)

func _process(delta: float) -> void:
	_handle_lights(delta)
	_check_triggers()

func _handle_lights(delta: float) -> void:
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		for light in lights_flickering:
			if is_instance_valid(light):
				light.visible = not light.visible
		_flicker_timer = randf_range(0.05, 3.0)

func _check_triggers() -> void:
	# When player reaches floor 7, cut power and spawn creature
	if not _creature_spawned and player:
		if player.global_position.y > 18.0:   # floor 7 height
			_trigger_power_cut()

func _trigger_power_cut() -> void:
	if _power_cut:
		return
	_power_cut = true
	_creature_spawned = true
	# Darken all lights
	for light in get_tree().get_nodes_in_group("corridor_light"):
		var t = create_tween()
		t.tween_property(light, "light_energy", 0.0, 3.0)
	# Spawn creature on floor 8
	FearSystem.fear_spike(0.6)
	# Activate creature AI
	if creature:
		creature.visible = true
		creature.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().create_timer(5.0).timeout
	if hud:
		hud.set_objective("Something is in the building. Find the basement. NOW.")
