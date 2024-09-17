class_name InteractiveNode
extends CollisionObject3D
## Base node for anything the character can interact with.

## How long before this interactive can be used again.
const COOLDOWN := 0.05

enum HoldMode {
	INSTANT, ## Pressing interact will be instant.
	HOLD, ## Holding for a time will
}

## A CharacterNode interacted with this.
signal interacted(data: Variant)
## Label to display to player has changed.
signal label_changed()
## While selected this was assigned to a node.
## Used for NPC to have them walk to an object.
signal assigned(node_or_vector3: Variant)

## Block interaction and selection?
@export var disabled := false: set=set_disabled, get=get_disabled
## Can be selected to assign to things?
@export var selectable := true: set=set_selectable, get=get_selectable
## Can an NPC be assigned to this?
## The NPC will walk to it then press interact.
## Should have a Restrainer.
@export var assignable_to_node := true
## Can assign to an arbitrary point in the scene.
@export var assignable_to_point := true
@export var label := "Interact": set=set_label
## Node where the label is displayed at.
@export var label_node: Node3D
@export var label_offset := Vector3.ZERO
@export var mesh: VisualInstance3D
@export var hold_mode := HoldMode.INSTANT
@export var hold_time := 0.0
var _in_use := false
var _cooling := false

func set_label(l: String):
	label = l
	label_changed.emit()

func get_label(_data: Variant) -> String:
	return label

func can_interact(_data: Variant) -> bool:
	return true

func can_select(_data: Variant) -> bool:
	return selectable

func _selected(_data: Variant):
	pass

func can_assign_to_node(node: Node, event: Variant) -> bool:
	return assignable_to_node

## Called when selected and a node is chosen.
func assign_to_node(node: Node, _event: Variant):
	if not assigned.get_connections():
		print("%s assigned to node %s." % [self, node])
	assigned.emit(node)

func can_assign_to_point(point: Vector3) -> bool:
	return assignable_to_point

## Called when selected and a location is chosen.
func assign_to_point(point: Vector3, _event: Variant):
	if not assigned.get_connections():
		print("%s assigned to point %s." % [self, point])
	assigned.emit(point)

func interaction_start(data: Variant):
	if not _cooling and not _in_use:
		_in_use = true
		_start_cooldown()
		interacted.emit(data)
		_interacted(data)

func _interacted(_data: Variant):
	pass

func interaction_end():
	_in_use = false

func _start_cooldown():
	_cooling = true
	await get_tree().create_timer(COOLDOWN).timeout
	_cooling = false

func _focus_entered():
	if mesh:
		Scene.get_main_scene().highlight(mesh, true)

func _focus_exited():
	if mesh:
		Scene.get_main_scene().highlight(mesh, false)

func set_disabled(d: bool):
	set_collision_layer_value(9, not d)

func get_disabled() -> bool:
	return get_collision_layer_value(9)

func set_selectable(s: bool):
	set_collision_layer_value(10, s)

func get_selectable() -> bool:
	return get_collision_layer_value(10)
