class_name Damagable3D
extends Area3D
## Takes damage of any kind.

signal damaged(event)

@export var health: int = 100
@export var max_health: int = 100

func _damaged(event: Damage3DEvent):
	var amt := maxi(0, health - event.amount)
	health -= amt
	var nrm := (event.source.global_position - global_position).normalized()
	print("Took %s damange." % amt)
	damaged.emit(event)
