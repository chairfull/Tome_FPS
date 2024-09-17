class_name Damagable3D
extends Area3D
## Takes damage of any kind.

signal damaged(event: DamageEvent)
signal healed(event: HealingEvent)

@export var damagable := Damagable.new()

func _damaged(event: DamageEvent):
	var amt := maxi(0, damagable.health - event.amount)
	damagable.health -= amt
	var nrm := (event.source.global_position - global_position).normalized()
	print("Took %s damange." % amt)
	damaged.emit(event)

func _healed(event: HealingEvent):
	pass

func _get(property: StringName) -> Variant:
	if property in damagable:
		return damagable[property]
	return
