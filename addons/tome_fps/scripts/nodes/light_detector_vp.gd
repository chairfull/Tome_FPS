class_name LightDetectorViewport
extends SubViewport
## Detects brightness using a similar method to Thief.
## This is probably more expensive than raycasts, but ultimately easier and more robust.
## Every DELAY it scans either the top or bottom, then takes the brightest.

const DELAY := 0.25

@export var enabled := true: get=get_enabled, set=set_enabled
@onready var sphere: MeshInstance3D = $Sphere
@onready var top_camera: Camera3D = $Sphere/TopCamera
@onready var bottom_camera: Camera3D = $Sphere/BottomCamera
var brightness := 0.0 ## Lerps towards _brightness.
var _top := true
var _brightness := 0.0
var _top_lum := 0.0
var _bot_lum := 0.0
var _timer := 0.0

func get_enabled() -> bool:
	return is_processing()

func set_enabled(e: bool):
	set_process(e)

func _process(delta: float) -> void:
	# Align cameras to the characters world position.
	sphere.global_position = owner.global_position + Vector3(0.0, 0.5, 0.0)
	
	# Smoothly lerp brightness, since it is updating onces per second.
	brightness = lerpf(brightness, _brightness, 2.0 * delta)
	
	# Every second scan the top or bottom.
	_timer += delta
	if _timer >= DELAY:
		_timer -= DELAY
		_update_brightness()

func _update_brightness():
	render_target_update_mode = SubViewport.UPDATE_ONCE
	
	var img := get_texture().get_image()
	var max_lum := 0.0
	for x in img.get_width():
		for y in img.get_height():
			var clr := img.get_pixel(x, y)
			max_lum = maxf(max_lum, clr.get_luminance())
	
	if _top:
		_top_lum = max_lum
	else:
		_bot_lum = max_lum
	
	_brightness = maxf(_top_lum, _bot_lum)
	
	_top = not _top
	if _top:
		top_camera.make_current()
	else:
		bottom_camera.make_current()
