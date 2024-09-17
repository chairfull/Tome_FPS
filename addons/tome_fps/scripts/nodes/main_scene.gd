class_name MainScene
extends Node

const RES_1920_1080 := Vector2i(1920, 1080)
const RES_1280_720 := Vector2i(1280, 720)

@onready var hilight: SubViewportContainer = %hilight
@onready var ui: Control = %ui

var active_ui: Dictionary[StringName, Node]
var outlines: Array[VisualInstance3D]
var fade_tween: Tween

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(RES_1280_720)

func get_random_patrol(inside: StringName = "") -> Variant:
	if inside:
		for node in get_tree().get_nodes_in_group("Patrol"):
			if node.name == inside:
				return node.get_random_position()
		return null
	else:
		var area: ZoneArea3D = get_tree().get_nodes_in_group("Patrol").pick_random()
		return area.get_random_position()

func get_world() -> Node3D:
	return $test_world

func has_ui(id: StringName):
	return active_ui.has(id)

func show_ui(id: StringName, props := {}) -> Node:
	if has_ui(id):
		return active_ui[id]
	var path := "res://addons/tome_fps/scenes/ui/ui_%s.tscn" % [id]
	if not FileAccess.file_exists(path):
		push_error("No UI %s." % id)
		return null
	var node: Node = load(path).instantiate()
	for prop in props:
		if prop in node:
			node[prop] = props[prop]
	ui.add_child(node)
	active_ui[id] = node
	node.name = id
	return node

func hide_ui(id: StringName):
	if not has_ui(id):
		return
	var node: Node = active_ui[id]
	ui.remove_child(node)
	node.queue_free()
	active_ui.erase(id)

func highlight(node: VisualInstance3D, on := true):
	if fade_tween:
		fade_tween.kill()
		
	if on and not node in outlines:
		node.set_layer_mask_value(19, true)
		outlines.append(node)
		
		hilight.material.set_shader_parameter("blend", 0.0)
		fade_tween = create_tween()
		fade_tween.tween_property(hilight, "material:shader_parameter/blend", 1.0, 0.25)
		hilight.visible = true
		hilight.process_mode = Node.PROCESS_MODE_INHERIT
		
	elif not on and node in outlines:
		fade_tween = create_tween()
		fade_tween.tween_property(hilight, "material:shader_parameter/blend", 0.0, 0.25)
		
		await fade_tween.finished
		
		node.set_layer_mask_value(19, false)
		outlines.erase(node)
		
		hilight.visible = false
		hilight.process_mode = Node.PROCESS_MODE_DISABLED
