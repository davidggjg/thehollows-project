extends Node

# ═══════════════════════════════════════════════════════
#  AUDIO MANAGER — Global Autoload
#  Manages music, ambience, SFX buses + adaptive horror audio
# ═══════════════════════════════════════════════════════

@onready var music_player: AudioStreamPlayer    = $MusicPlayer
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var heartbeat_player: AudioStreamPlayer = $HeartbeatPlayer
@onready var stinger_player: AudioStreamPlayer  = $StingerPlayer

var current_music: AudioStream = null
var current_ambience: AudioStream = null
var _tween: Tween = null

# Audio bus indices (set in AudioServer)
const BUS_MASTER  = "Master"
const BUS_MUSIC   = "Music"
const BUS_SFX     = "SFX"
const BUS_AMBIENCE = "Ambience"

func _ready() -> void:
	# Create audio players dynamically if not in scene
	if not has_node("MusicPlayer"):
		music_player    = _make_player("MusicPlayer",   BUS_MUSIC)
		ambience_player = _make_player("AmbiencePlayer", BUS_AMBIENCE)
		heartbeat_player = _make_player("HeartbeatPlayer", BUS_SFX)
		stinger_player  = _make_player("StingerPlayer",  BUS_SFX)

func _make_player(node_name: String, bus: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.name = node_name
	p.bus = bus
	add_child(p)
	return p

# ── MUSIC ─────────────────────────────────────────────────
func play_music(stream: AudioStream, fade_time: float = 2.0) -> void:
	if stream == current_music:
		return
	current_music = stream
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(music_player, "volume_db", -80.0, fade_time * 0.5)
	await _tween.finished
	music_player.stream = stream
	music_player.play()
	_tween = create_tween()
	_tween.tween_property(music_player, "volume_db", 0.0, fade_time * 0.5)

func stop_music(fade_time: float = 2.0) -> void:
	var t = create_tween()
	t.tween_property(music_player, "volume_db", -80.0, fade_time)
	await t.finished
	music_player.stop()

# ── AMBIENCE ──────────────────────────────────────────────
func play_ambience(stream: AudioStream, fade_time: float = 3.0) -> void:
	if stream == current_ambience:
		return
	current_ambience = stream
	ambience_player.stream = stream
	ambience_player.play()
	ambience_player.volume_db = -80.0
	var t = create_tween()
	t.tween_property(ambience_player, "volume_db", -6.0, fade_time)

# ── HEARTBEAT (driven by FearSystem) ─────────────────────
func set_heartbeat(fear_level: float) -> void:
	if fear_level <= 0.1:
		heartbeat_player.volume_db = -80.0
		return
	heartbeat_player.volume_db = lerp(-80.0, -6.0, fear_level)
	heartbeat_player.pitch_scale = lerp(0.85, 1.5, fear_level)
	if not heartbeat_player.playing and fear_level > 0.2:
		heartbeat_player.play()

# ── SFX ───────────────────────────────────────────────────
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not stream:
		return
	var p = AudioStreamPlayer.new()
	p.bus = BUS_SFX
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch + randf_range(-0.05, 0.05)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# ── STINGER (horror sting, no musical sting — silence IS horror) ──
func play_distant_sound(stream: AudioStream) -> void:
	stinger_player.stream = stream
	stinger_player.volume_db = -20.0
	stinger_player.play()

# ── VOLUME CONTROL ────────────────────────────────────────
func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_MASTER), linear_to_db(linear))

func set_music_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_MUSIC), linear_to_db(linear))

func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_SFX), linear_to_db(linear))
