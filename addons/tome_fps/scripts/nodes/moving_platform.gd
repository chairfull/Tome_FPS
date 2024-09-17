extends Node3D

@export var restrainer: RestrainerNode

func _ready() -> void:
	restrainer.controller_input.connect(_controller)

func _controller(action: StringName, value: Variant):
	match action:
		&"move":
			position += Vector3(value.x, 0.0, value.y)
