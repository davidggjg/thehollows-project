extends Interactable
class_name PickupItem

@export var item_id: String = ""
@export var item_name: String = "Item"
@export var item_description: String = ""
@export var pickup_sound: AudioStream
@export var is_note: bool = false       # Notes go to journal, not inventory
@export var note_content: String = ""

func _ready() -> void:
	interaction_label = "Pick up " + item_name
	one_shot = true

func _on_interact(player: Node) -> void:
	AudioManager.play_sfx(pickup_sound)
	if is_note:
		GameManager.collect_note(item_id)
		# Show note UI
		var ui = get_tree().get_first_node_in_group("hud")
		if ui and ui.has_method("show_note"):
			ui.show_note(item_name, note_content)
	else:
		# Add to inventory
		if player.has_method("add_item"):
			player.add_item(item_id, item_name)
	queue_free()
