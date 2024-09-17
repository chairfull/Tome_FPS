@tool
class_name Climable
extends InteractiveNode

@export var height := 1.0: set=set_height
@export var width := 1.0: set=set_width
@onready var restrainer_node: RestrainerNode = $RestrainerNode
@onready var bottom: MeshInstance3D = $Bottom
@onready var top: MeshInstance3D = $Top

func _ready() -> void:
	restrainer_node.occupied.connect(_occupied)
	restrainer_node.controller_input.connect(_controller_input)
	restrainer_node.controller_process.connect(_controller_process)
	set_height.call_deferred(height)
	set_width.call_deferred(width)

func _occupied():
	# Rotate into position.
	var tween := get_tree().create_tween()
	tween.tween_property(restrainer_node.character_node, "direction", global_rotation.y, 0.25)
	
func _controller_input(action: StringName, input: Variant):
	prints(action, input)
	match action:
		&"move":
			restrainer_node.character_node.global_position.y -= input.y * 0.01
			var minn := bottom.global_position.y
			var maxx := top.global_position.y
			var curr := restrainer_node.character_node.global_position.y
			if curr > maxx:
				restrainer_node.eject()
		&"jump":
			restrainer_node.eject()

func _controller_process(delta: float):
	var chr := restrainer_node.character_node
	# Move into position.
	chr.global_position.x = lerpf(chr.global_position.x, bottom.global_position.x, delta * 10.0)
	chr.global_position.z = lerpf(chr.global_position.z, bottom.global_position.z, delta * 10.0)
	

func set_height(h: float):
	height = h
	if not is_inside_tree():
		return
	$MeshInstance3D.mesh.size.y = height
	$MeshInstance3D.position.y = height * .5
	$CollisionShape3D.shape.size.y = height
	$CollisionShape3D.position.y = height * .5
	$Top.position.y = height

func set_width(w: float):
	width = w
	if not is_inside_tree():
		return
	$MeshInstance3D.mesh.size.x = width
	$CollisionShape3D.shape.size.x = width
