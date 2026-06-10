extends Interactable
class_name Door

@export var is_locked: bool = false
@export var required_key: String = ""
@export var open_angle: float = 90.0
@export var open_speed: float = 2.5
@export var locked_sound: AudioStream
@export var open_sound: AudioStream
@export var creak_sound: AudioStream

@onready var hinge: Node3D = $Hinge
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _is_open: bool = false
var _target_angle: float = 0.0
var _tween: Tween

func _ready() -> void:
	interaction_label = "Open" if not is_locked else "Locked"
	requires_item = required_key

func _on_interact(player: Node) -> void:
	if is_locked:
		AudioManager.play_sfx(locked_sound)
		FearSystem.fear_spike(0.05)
		return
	toggle()

func toggle() -> void:
	_is_open = !_is_open
	_target_angle = deg_to_rad(open_angle) if _is_open else 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(hinge, "rotation:y", _target_angle, 1.0 / open_speed)
	# Play creak halfway through
	await get_tree().create_timer(0.3 / open_speed).timeout
	AudioManager.play_sfx(creak_sound if creak_sound else open_sound, -8.0, randf_range(0.9, 1.1))

func unlock(key_id: String) -> bool:
	if key_id == required_key:
		is_locked = false
		interaction_label = "Open"
		return true
	return false
