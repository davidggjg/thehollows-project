extends Node

# ═══════════════════════════════════════════════════════
#  GAME MANAGER — Global Autoload
#  Handles scene transitions, game state, checkpoints
# ═══════════════════════════════════════════════════════

enum GameState { MENU, PLAYING, PAUSED, CUTSCENE, DEAD, LOADING }
enum Ending { NONE, ESCAPE, SACRIFICE, TRUTH }

var current_state: GameState = GameState.MENU
var current_level: int = 0
var player_checkpoint: String = "start"
var collected_notes: Array[String] = []
var unlocked_endings: Array[Ending] = []
var play_time: float = 0.0
var death_count: int = 0

# Level names in order
const LEVELS = [
	"res://scenes/levels/Level1_Apartment.tscn",
	"res://scenes/levels/Level2_Tunnel.tscn",
	"res://scenes/levels/Level3_Asylum.tscn"
]

const LEVEL_NAMES = ["Vesper Towers", "The Passage", "Ashford Institute"]

signal state_changed(new_state: GameState)
signal level_loaded(level_index: int)
signal note_collected(note_id: String)
signal checkpoint_reached(checkpoint_id: String)
signal game_over()
signal ending_triggered(ending: Ending)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		play_time += delta

func set_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
		GameState.LOADING:
			get_tree().paused = false

func load_level(index: int) -> void:
	if index < 0 or index >= LEVELS.size():
		push_error("Invalid level index: " + str(index))
		return
	current_level = index
	set_state(GameState.LOADING)
	# Fade out then load
	var tree = get_tree()
	await tree.create_timer(0.1).timeout
	tree.change_scene_to_file(LEVELS[index])
	level_loaded.emit(index)

func load_main_menu() -> void:
	set_state(GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func reach_checkpoint(id: String) -> void:
	player_checkpoint = id
	checkpoint_reached.emit(id)
	SaveSystem.auto_save()

func collect_note(note_id: String) -> void:
	if note_id not in collected_notes:
		collected_notes.append(note_id)
		note_collected.emit(note_id)

func trigger_ending(ending: Ending) -> void:
	if ending not in unlocked_endings:
		unlocked_endings.append(ending)
	ending_triggered.emit(ending)

func player_died() -> void:
	death_count += 1
	current_state = GameState.DEAD
	game_over.emit()

func get_level_name() -> String:
	if current_level < LEVEL_NAMES.size():
		return LEVEL_NAMES[current_level]
	return "Unknown"

func format_time(seconds: float) -> String:
	var h = int(seconds / 3600)
	var m = int(fmod(seconds, 3600) / 60)
	var s = int(fmod(seconds, 60))
	return "%02d:%02d:%02d" % [h, m, s]
