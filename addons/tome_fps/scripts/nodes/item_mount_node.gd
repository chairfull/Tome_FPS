class_name ItemMountNode
extends InteractiveNode
## Hold's an item, for decoration or for devices, traps...

signal occupied()
signal unoccupied()

@export var item_node: ItemNode: set=set_item_node

func can_interact(data: Variant) -> bool:
	var ch: CharacterNode = data.character_node
	return ch.holding != null or item_node != null

func _interacted(data: Variant):
	var ch: CharacterNode = data.character_node
	
	# Mount item character is using.
	if ch.holding:
		var mount := ch.holding
		ch.holding = null
		UNode.remember_parent(mount)
		mount.reparent(self)
		var tw := get_tree().create_tween().set_parallel()
		tw.tween_property(mount, "position", Vector3(0, 0, 0.2), 0.25)
		tw.tween_property(mount, "rotation_degrees", Vector3(0, 90, 0), 0.25)
		mount.posession_state = ItemNode.PosessionState.MOUNTED
		item_node = mount
	
	# Unmount item.
	elif item_node:
		var mounted := item_node
		item_node = null
		UNode.reparent(mounted)
		ch.holding = mounted

func get_label(data: Variant) -> String:
	var ch: CharacterNode = data.character_node
	if ch.holding != null and item_node != null:
		return "Swap %s for %s" % [item_node.item, ch.holding.item]
	elif ch.holding != null:
		return "Mount %s" % [ch.holding.item]
	elif item_node != null:
		return "Unmount %s" % [item_node.item]
	return super(data)

func is_occupied() -> bool:
	return item_node != null

func set_item_node(it: ItemNode):
	if item_node == it:
		return
	if item_node:
		unoccupied.emit()
	item_node = it
	if item_node:
		occupied.emit()
