class_name ItemNode
extends InteractiveNode
## Item that can be picked up, equipped, or mounted.

signal mounted()
signal unmounted()
signal held()
signal unheld()
signal equipped()
signal unequipped()

enum PosessionState {
	## Idle in the scene.
	IDLE,
	## Being picked up to be moved.
	HELD,
	## Currently in the hands of a character.
	EQUIPPED,
	## On an ItemMount.
	MOUNTED,
}

@export var item: Item: get=get_item
@export var quantity := 1
@export var state: Dictionary[StringName, Variant] = {}
@export var posession_state := PosessionState.IDLE: set=set_posession_state

func is_idle() -> bool: return posession_state == PosessionState.IDLE
func is_held() -> bool: return posession_state == PosessionState.HELD
func is_equipped() -> bool: return posession_state == PosessionState.EQUIPPED
func is_mounted() -> bool: return posession_state == PosessionState.MOUNTED

func get_item() -> Item:
	return item if item else Item.NONE

func _interacted(data: Variant):
	match posession_state:
		PosessionState.IDLE:
			var cn: CharacterNode = data.character_node
			cn.holding = self

func get_label(data: Variant) -> String:
	match posession_state:
		PosessionState.IDLE: return "Pickup x%s %s" % [quantity, item.name]
		PosessionState.MOUNTED: return "Unmount %s" % [item]
	return super(data)

func set_posession_state(ps):
	if ps == posession_state:
		return
	
	match posession_state:
		PosessionState.HELD: unheld.emit()
		PosessionState.EQUIPPED: unequipped.emit()
		PosessionState.MOUNTED: unmounted.emit()
	
	posession_state = ps
	
	var body: RigidBody3D = get_node(^".")
	match posession_state:
		PosessionState.IDLE:
			body.set_collision_layer_value(1, true)
			disabled = false
			body.freeze = false
		PosessionState.HELD:
			body.set_collision_layer_value(1, false)
			disabled = true
			body.freeze = false
			held.emit()
		PosessionState.EQUIPPED:
			body.set_collision_layer_value(1, false)
			disabled = true
			body.freeze = true
			equipped.emit()
		PosessionState.MOUNTED:
			body.set_collision_layer_value(1, false)
			disabled = true
			body.freeze = true
			mounted.emit()
