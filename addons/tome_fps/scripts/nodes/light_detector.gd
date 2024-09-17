class_name LightDetectorRays
extends Area3D
## Detects brightness using colliders/rays.
## Currently disabled.

var brightness := 0.0
var _brightness := 0.0
var _omnilights: Array[OmniLight3D]

func _ready() -> void:
	area_entered.connect(_entered)
	area_exited.connect(_exited)
	set_process(false)

func get_total_light_count() -> int:
	return len(_omnilights)

func _process(delta: float) -> void:
	_brightness = 0.0
	for light in _omnilights:
		var dist := global_position.distance_to(light.global_position)
		_brightness += (1.0 - min(dist, light.omni_range) / light.omni_range) * light.light_energy

func _entered(light):
	if light.owner is OmniLight3D:
		_omnilights.append(light.owner)
		set_process(true)

func _exited(light):
	if light.owner is OmniLight3D:
		_omnilights.erase(light.owner)
		set_process(len(_omnilights) > 0)
