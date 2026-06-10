extends Node3D
class_name LevelBase

@export var level_index: int = 0
@export var ambient_music: AudioStream
@export var ambient_sound: AudioStream
@export var level_objectives: Array[String] = []

var _current_objective_index: int = 0
var _checkpoints: Dictionary = {}

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.PLAYING)
	_register_checkpoints()
	_setup_environment()
	if ambient_music:
		AudioManager.play_music(ambient_music)
	if ambient_sound:
		AudioManager.play_ambience(ambient_sound)
	# Restore from checkpoint
	if GameManager.player_checkpoint != "start":
		_restore_checkpoint(GameManager.player_checkpoint)
	# Set first objective
	await get_tree().process_frame
	if level_objectives.size() > 0:
		var hud_node = get_tree().get_first_node_in_group("hud")
		if hud_node and hud_node.has_method("set_objective"):
			hud_node.set_objective(level_objectives[0])

func _setup_environment() -> void:
	pass

func _register_checkpoints() -> void:
	for child in get_children():
		if child.is_in_group("checkpoint"):
			_checkpoints[child.name] = child

func _restore_checkpoint(checkpoint_id: String) -> void:
	if checkpoint_id in _checkpoints:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = _checkpoints[checkpoint_id].global_position

func advance_objective() -> void:
	_current_objective_index += 1
	if _current_objective_index < level_objectives.size():
		var hud_node = get_tree().get_first_node_in_group("hud")
		if hud_node and hud_node.has_method("set_objective"):
			hud_node.set_objective(level_objectives[_current_objective_index])
	else:
		_on_level_complete()

func _on_level_complete() -> void:
	var hud_node = get_tree().get_first_node_in_group("hud")
	if hud_node and hud_node.has_method("fade_out"):
		await hud_node.fade_out(2.0)
	var next = level_index + 1
	if next < GameManager.LEVELS.size():
		GameManager.load_level(next)
	else:
		GameManager.trigger_ending(GameManager.Ending.ESCAPE)
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
