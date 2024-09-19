class_name Projectile3D
extends RayCast3D
## Base projectile class that flies forward until hitting something or timing out.

## Either hit or timed out.
signal finished(info: Dictionary)
## Damaged something.
signal committed_damage(event: DamageEvent)

const MAX_LIFE_SECONDS := 20.0

@export var damage_type: DamageType
@export var damage_amount := 10

static func create(at: Vector3, dir: Vector3) -> Projectile3D:
	var proj: Projectile3D = load("res://addons/tome_fps/scenes/projectile.tscn").instantiate()
	Scene.get_tree().current_scene.add_child(proj)
	proj.global_position = at
	proj.target_position = dir
	return proj

func _ready() -> void:
	await get_tree().create_timer(MAX_LIFE_SECONDS).timeout
	# Empty hit_info means we timed out.
	finish({})

func _physics_process(delta: float) -> void:
	var next_point := position + target_position * delta
	var collider := get_collider()
	if collider:
		var hit_point := get_collision_point()
		var hit_norm := get_collision_normal()
		if position.distance_to(hit_point) <= position.distance_to(next_point):
			if collider is Damagable3D:
				Event.DAMAGE.emit({
					source=self,
					target=collider,
					type=damage_type,
					amount=damage_amount,
					position=hit_point,
					normal=hit_norm,
				}, collider._damaged)
				
				committed_damage.emit(Event.DAMAGE)
			
			finish({
				collider=collider,
				position=hit_point,
				normal=hit_norm,
			})
			return
	position = next_point

func finish(state: Dictionary):
	set_process(false)
	finished.emit(state)
	queue_free()
	return
