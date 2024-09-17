@tool
extends OmniLight3D

@export var size := 5.0: set=set_size

func set_size(s):
	size = s
	omni_range = s
	if is_inside_tree():
		$Area/CollisionShape3D.shape.radius = size
