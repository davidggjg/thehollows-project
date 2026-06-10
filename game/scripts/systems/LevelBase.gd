extends Node3D
class_name LevelBase

# ═══════════════════════════════════════════════════════
#  LEVEL BASE — inherit for each level
#  Handles: checkpoints, objectives, level events,
#  creature spawning, environment triggers
# ═══════════════════════════════════════════════════════

@export var level_index: int = 0
@export var ambient_music: AudioStream
@export var ambient_sound: AudioStream
@export var level_objectives: Array[String] = []

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody3D = $Player
@onready var creature: CharacterBody3D = $Creature

var _current_objective_index: int = 0
var _checkpoints: Dictionary = {}   # "id" → Node3D

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.PLAYING)
	_register_checkpoints()
	_setup_environment()
	AudioManager.play_music(ambient_music)
	AudioManager.play_ambience(ambient_sound)
	# Restore from checkpoint if loading a save
	if GameManager.player_checkpoint != "start":
		_restore_checkpoint(GameManager.player_checkpoint)
	if level_objectives.size() > 0 and hud:
		hud.set_objective(level_objectives[0])
	GameManager.level_loaded.emit(level_index)

func _setup_environment() -> void:
	# Override in child levels for custom environment setup
	pass

func _register_checkpoints() -> void:
	for child in get_children():
		if child.is_in_group("checkpoint"):
			_checkpoints[child.name] = child

func _restore_checkpoint(checkpoint_id: String) -> void:
	if checkpoint_id in _checkpoints and player:
		player.global_position = _checkpoints[checkpoint_id].global_position

func advance_objective() -> void:
	_current_objective_index += 1
	if _current_objective_index < level_objectives.size():
		if hud:
			hud.set_objective(level_objectives[_current_objective_index])
	else:
		_on_level_complete()

func _on_level_complete() -> void:
	if hud:
		await hud.fade_out(2.0)
	var next = level_index + 1
	if next < GameManager.LEVELS.size():
		GameManager.load_level(next)
	else:
		_trigger_ending()

func _trigger_ending() -> void:
	# Check collected notes and choices to determine ending
	var notes = GameManager.collected_notes
	if "note_truth_found" in notes and "note_sacrifice_clue" in notes:
		if randf() > 0.5:
			GameManager.trigger_ending(GameManager.Ending.TRUTH)
		else:
			GameManager.trigger_ending(GameManager.Ending.SACRIFICE)
	else:
		GameManager.trigger_ending(GameManager.Ending.ESCAPE)
	get_tree().change_scene_to_file("res://scenes/ui/EndingScreen.tscn")
