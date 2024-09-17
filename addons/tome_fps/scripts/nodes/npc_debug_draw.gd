extends Node2D

@export var color := Color.BLACK
@export var width := -1.0

var path: Array
var points: Array[Vector3]
var text := ""

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	
	for point in points:
		if cam.is_position_in_frustum(point):
			var a := cam.unproject_position(point)
			draw_circle(a, 16.0, color, false, width, true)
	
	for i in len(path)-1:
		if cam.is_position_in_frustum(path[i]) and cam.is_position_in_frustum(path[i+1]):
			var a := cam.unproject_position(path[i])
			var b := cam.unproject_position(path[i+1])
			draw_line(a, b, color, width, true)
	
	for i in len(path):
		if cam.is_position_in_frustum(path[i]):
			var a := cam.unproject_position(path[i])
			draw_circle(a, 4.0, color, false, width, true)
	
	var pos: Vector3 = owner.character_node.global_position + Vector3.UP
	if cam.is_position_in_frustum(pos):
		var fnt := ThemeDB.fallback_font
		var pos2d := cam.unproject_position(pos) - fnt.get_string_size(text, 0, -1, 24) * .5
		draw_string(fnt, pos2d, text, 0, -1, 24, Color.WHITE)
