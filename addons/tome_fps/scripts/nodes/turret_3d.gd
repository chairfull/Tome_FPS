extends Node3D

@export var fire_speed := 64.0
@export var fire_delay := 0.3
@export var turn_speed := 2.0
@onready var head: Node3D = $Head
@onready var fov: FieldOfView3D = $FOV
var _target: Node3D
var _delay := 0.0

func _ready() -> void:
	fov.spotted.connect(func(a): _target = a)
	fov.unspotted.connect(func(a): _target = null)
	
func _process(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
	
	if _target:
		var dir := _target.global_position - head.global_position
		var rot := -atan2(dir.x, -dir.z)
		head.rotation.y = lerp_angle(head.rotation.y, rot, turn_speed * delta)
		var dif := absf(angle_difference(rot, head.rotation.y))
		
		if dif < .1 and _delay <= 0.0:
			_delay = fire_delay
			var normal := -head.basis.z.normalized()
			Projectile3D.create(head.global_position + normal * 2.0, normal * fire_speed)
