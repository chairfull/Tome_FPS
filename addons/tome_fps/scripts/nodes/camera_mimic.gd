extends Camera3D

@export var viewport: Viewport

func _ready() -> void:
	if not viewport:
		viewport = get_tree().current_scene.get_viewport()#.get_node("viewport_container").get_child(0)

func _process(_delta: float) -> void:
	var cam := get_tree().current_scene.get_viewport().get_camera_3d()# viewport.get_camera_3d()
	global_transform = cam.global_transform
	h_offset = cam.h_offset
	v_offset = cam.v_offset
	fov = cam.fov
	near = cam.near
	far = cam.far
