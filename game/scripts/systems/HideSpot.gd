extends StaticBody3D
class_name HideSpot

@export var hide_position: NodePath
@export var exit_position: NodePath
@export var hide_sound: AudioStream

var _hide_node: Node3D
var _exit_node: Node3D
var _player_original_pos: Vector3

func _ready() -> void:
	add_to_group("hide_spot")
	if hide_position:
		_hide_node = get_node(hide_position)
	if exit_position:
		_exit_node = get_node(exit_position)

func enter_hide(player: Node) -> void:
	_player_original_pos = player.global_position
	if _hide_node:
		player.global_position = _hide_node.global_position
	# Disable player collision so creature can't detect
	player.set_collision_layer_value(1, false)
	# Restrict camera to peek angle
	AudioManager.play_sfx(hide_sound)
	FearSystem.add_fear("hiding_fear", 0.4)  # Being still while hunted is terrifying

func exit_hide(player: Node) -> void:
	if _exit_node:
		player.global_position = _exit_node.global_position
	else:
		player.global_position = _player_original_pos
	player.set_collision_layer_value(1, true)
	FearSystem.remove_fear("hiding_fear")
