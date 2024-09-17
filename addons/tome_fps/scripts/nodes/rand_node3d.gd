@tool
extends Node3D

@export_range(0.0, 1.0) var position_weight := 1.0
@export var position_speed := 1.0
@export var position_scale := Vector3.ONE
@export_range(1, 4) var position_octaves := 2

@export_range(0.0, 1.0) var rotation_weight := 1.0
@export var rotation_speed := 1.0
@export var rotation_scale := Vector3(0.0, 0.0, 0.0)
@export_range(1, 4) var rotation_octaves := 2

var _time_position: float = randf()
var _time_rotation: float = randf()

func _process(delta: float) -> void:
	_time_position += delta * position_speed
	position = URand.fbm_v3(Vector3(0.1, 0.2, 0.3) * _time_position, position_octaves)\
			* position_scale\
			* position_weight
	
	_time_rotation += delta * rotation_speed
	rotation_degrees = URand.fbm_v3(Vector3(0.3, 0.1, 0.2) * _time_rotation, rotation_octaves)\
			* rotation_scale\
			* rotation_weight
