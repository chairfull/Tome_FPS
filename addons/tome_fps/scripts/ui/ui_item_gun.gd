extends Node

var character_node: CharacterNode

func _ready() -> void:
	character_node.character.items_changed.connect(_update_label)
	(character_node.holding_state as Gun).fired.connect(_update_label)
	(character_node.holding_state as Gun).reload_started.connect(_update_label)
	(character_node.holding_state as Gun).reloaded.connect(_update_label)
	_update_label()

func _update_label():
	var gun: Gun = character_node.holding_state
	if character_node._reloading:
		%ammo.text = "Ammo: Reloading/%s (%s)" % [gun.clip_size, character_node.character.count("ammo")]
	else:
		%ammo.text = "Ammo: %s/%s (%s)" % [gun.clip, gun.clip_size, character_node.character.count("ammo")]
