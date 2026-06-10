extends StaticBody3D
class_name Interactable

# ═══════════════════════════════════════════════════════
#  INTERACTABLE BASE CLASS
#  Inherit from this for: doors, items, notes, levers,
#  hide spots, lockers, puzzles
# ═══════════════════════════════════════════════════════

@export var interaction_label: String = "Examine"
@export var interaction_distance: float = 2.5
@export var requires_item: String = ""        # Item ID needed to interact
@export var one_shot: bool = false             # Can only interact once

var _has_been_used: bool = false
var _is_highlighted: bool = false

signal interaction_started(player)
signal interaction_completed(player)

func interact(player: Node) -> void:
	if _has_been_used and one_shot:
		return
	if requires_item != "" and not _player_has_item(player, requires_item):
		_show_locked_message()
		return
	_has_been_used = true
	_on_interact(player)
	interaction_started.emit(player)

# Override in subclasses
func _on_interact(player: Node) -> void:
	pass

func get_label() -> String:
	return interaction_label

func _player_has_item(player: Node, item_id: String) -> bool:
	if player.has_method("has_item"):
		return player.has_item(item_id)
	return false

func _show_locked_message() -> void:
	# Emit to UI via signal bus
	pass

func highlight(on: bool) -> void:
	_is_highlighted = on
	# Pulse outline shader parameter
	if has_node("MeshInstance3D"):
		var mesh = get_node("MeshInstance3D")
		if mesh.get_surface_override_material(0):
			mesh.get_surface_override_material(0).set_shader_parameter("highlighted", on)
