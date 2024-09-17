class_name Item
extends Resource

static var NONE := Item.new()

@export var name: String
@export var desc: String
@export var ui: StringName

## Called once when a character starts holding the item.
func _on_held_started(ch: CharacterNode):
	# Align with the camera.
	var t := ch.get_tree().create_tween().set_parallel()
	t.tween_property(ch.holding, "position", Vector3(0.5, -0.3, -1.0), 0.25)
	t.tween_property(ch.holding, "rotation_degrees", Vector3(0.0, 0.0, 0.0), 0.25)

## Called in _process while a character is holding this item.
func _on_held(_ch: CharacterNode, _delta: float) -> void:
	pass

## Called once when a character drops this item.
func _on_held_ended(_ch: CharacterNode):
	pass
