extends LevelBase

# ═══════════════════════════════════════════════════════
#  LEVEL 1: VESPER TOWERS — The Apartment Complex
# ═══════════════════════════════════════════════════════

var _power_cut: bool = false
var _creature_spawned: bool = false
var _flicker_timer: float = 0.0
var _flickering_lights: Array = []

func _setup_environment() -> void:
	level_index = 0
	level_objectives = [
		"Find the building maintenance records",
		"Locate the basement access key",
		"Reach Sub-Level B2",
	]
	# Collect all flickering lights in scene
	for node in get_tree().get_nodes_in_group("flickering_light"):
		_flickering_lights.append(node)

func _process(delta: float) -> void:
	_handle_light_flicker(delta)
	_check_player_height()

func _handle_light_flicker(delta: float) -> void:
	if _flickering_lights.is_empty():
		return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		for light in _flickering_lights:
			if is_instance_valid(light):
				light.visible = not light.visible
		_flicker_timer = randf_range(0.05, 4.0)

func _check_player_height() -> void:
	if _power_cut:
		return
	# When player reaches Y > 5 (upper floors), trigger power cut
	var p = get_tree().get_first_node_in_group("player")
	if p and p.global_position.y > 5.0:
		_trigger_power_cut()

func _trigger_power_cut() -> void:
	_power_cut = true
	# Dim all lights
	for light in get_tree().get_nodes_in_group("corridor_light"):
		if is_instance_valid(light):
			var t = create_tween()
			t.tween_property(light, "light_energy", 0.0, 3.0)
	FearSystem.fear_spike(0.5)
	# Update objective via HUD
	var hud_node = get_tree().get_first_node_in_group("hud")
	if hud_node and hud_node.has_method("set_objective"):
		hud_node.set_objective("Something is here. Find the basement. NOW.")
