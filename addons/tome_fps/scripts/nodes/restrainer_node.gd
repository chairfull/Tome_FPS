class_name RestrainerNode
extends Node3D
## Chairs, beds, work stations, traps...
## Anything that holds and takes control of a CharacterNode.

enum Mode { NONE, SNAP, SMOOTH }

signal occupied()
signal unoccupied()
signal controller_process(delta: float)
signal controller_input(action: StringName, value: Variant)

@export var interactive: InteractiveNode
@export var camera: Camera3D
@export var ui: StringName
@export var align_position := Mode.SMOOTH
@export var align_rotation := Mode.SMOOTH
@export var make_parent := true
## Applied to Character class.
@export var type: StringName
## Prevent the rotation of the characters head.
@export var lock_player_head := false

var character_node: CharacterNode:
	set=set_character_node

func _ready() -> void:
	if interactive:
		interactive.interacted.connect(func(e):
			character_node=e.character_node)

func is_occupied() -> bool:
	return character_node != null

func can_eject() -> bool:
	return false

func eject():
	set_character_node.call_deferred(null)

func set_character_node(c: CharacterNode):
	if c == character_node:
		return
	
	# Remove previous occupant.
	if is_occupied() and not Engine.is_editor_hint():
		var ch := character_node
		ch._restrainer = null
		character_node = null
		unoccupied.emit()
		
		if ch.has_meta("last_parent"):
			ch.reparent(ch.get_meta("last_parent"))
			ch.remove_meta("last_parent")
		
		if ch.is_player():
			var ui := get_node_or_null("user_interface")
			if ui:
				ui.queue_free()
	
	character_node = c
	
	# Add occupant.
	if is_occupied() and not Engine.is_editor_hint():
		var ch := character_node
		ch._restrainer = self
		occupied.emit()
		
		if make_parent:
			ch.set_meta("last_parent", ch.get_parent())
			ch.reparent(self)
		
		match align_position:
			Mode.SNAP:
				ch.global_position = global_position
				ch.direction = rotation_degrees.y
			Mode.SMOOTH:
				var tw := get_tree().create_tween().set_parallel()
				tw.tween_property(ch, "global_position", global_position, 0.25)
				tw.tween_property(ch, "direction", rotation_degrees.y, 0.25)
		
		if ch.is_player():
			if camera:
				camera.make_current()
			
			if ui:
				var ui_node: Node = Scene.get_main_scene().show_ui(ui, { restrainer=self })
				
				if ui_node.has_signal(&"closed"):
					ui_node.closed.connect(func():
						Scene.get_main_scene().hide_ui(ui)
						eject())
