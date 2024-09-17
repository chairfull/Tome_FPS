class_name ZoneArea3D
extends Area3D

func _ready() -> void:
	body_entered.connect(_entered)
	body_exited.connect(_exited)

func _entered(body: Node3D):
	if body is CharacterNode:
		body.area = name

func _exited(body: Node3D):
	pass
	#body.area = name

func get_random_position(_float: bool = true) -> Vector3:
	for child in get_children():
		if child is CollisionShape3D:
			if child.shape is CylinderShape3D:
				var cylinder: CylinderShape3D = child.shape
				var r := randf() * cylinder.radius
				var a := randf() * TAU
				return child.global_position + Vector3(sin(a) * r, 0.0, cos(a) * r)
	return global_position
