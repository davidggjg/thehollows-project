extends Node

# ═══════════════════════════════════════════════════════
#  SAVE SYSTEM — Global Autoload
#  Saves to: user://saves/save_slot_X.dat
#  Godot's user:// maps to AppData/Roaming on Windows
# ═══════════════════════════════════════════════════════

const SAVE_DIR  = "user://saves/"
const SAVE_FILE = "user://saves/save_slot_0.dat"
const SETTINGS_FILE = "user://settings.dat"

signal save_completed()
signal load_completed()

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# ── GAME SAVE ────────────────────────────────────────────
func save_game() -> bool:
	var data = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": GameManager.play_time,
		"death_count": GameManager.death_count,
		"current_level": GameManager.current_level,
		"checkpoint": GameManager.player_checkpoint,
		"collected_notes": GameManager.collected_notes,
		"unlocked_endings": GameManager.unlocked_endings,
	}
	var result = _write_file(SAVE_FILE, data)
	if result:
		save_completed.emit()
	return result

func load_game() -> bool:
	var data = _read_file(SAVE_FILE)
	if data.is_empty():
		return false
	GameManager.play_time       = data.get("play_time", 0.0)
	GameManager.death_count     = data.get("death_count", 0)
	GameManager.current_level   = data.get("current_level", 0)
	GameManager.player_checkpoint = data.get("checkpoint", "start")
	GameManager.collected_notes = data.get("collected_notes", [])
	GameManager.unlocked_endings = data.get("unlocked_endings", [])
	load_completed.emit()
	return true

func auto_save() -> void:
	save_game()

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func delete_save() -> void:
	if save_exists():
		DirAccess.remove_absolute(SAVE_FILE)

# ── SETTINGS ─────────────────────────────────────────────
func save_settings(settings: Dictionary) -> void:
	_write_file(SETTINGS_FILE, settings)

func load_settings() -> Dictionary:
	return _read_file(SETTINGS_FILE)

func default_settings() -> Dictionary:
	return {
		"master_volume": 0.8,
		"music_volume": 0.6,
		"sfx_volume": 0.9,
		"mouse_sensitivity": 0.3,
		"brightness": 1.0,
		"fullscreen": true,
		"vsync": true,
	}

# ── FILE HELPERS ──────────────────────────────────────────
func _write_file(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[SaveSystem] Cannot write: " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
