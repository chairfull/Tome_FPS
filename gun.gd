class_name Gun
extends Item

signal fired()
signal reload_started()
signal reloaded()

@export var aiming_fov: float = 40.0
@export var cooldown_time := 0.5
@export var charge_time := 0.0
@export var reload_time := 2.0
@export var clip_size := 10
var clip := 0
var cooldown := 0.0
var charge := 0.0
var _reload_time := 0.0

func _on_held_started(ch: CharacterNode):
	super(ch)
	_update_clip(ch)

func _update_clip(ch: CharacterNode):
	var dif := mini(clip_size - clip, ch.character.count("ammo"))
	clip += dif
	ch.character.lose("ammo", dif)

func _on_held(ch: CharacterNode, delta: float) -> void:
	super(ch, delta)
	if ch.is_aiming():
		ch.camera.fov = lerpf(ch.camera.fov, aiming_fov, delta * 10.0)
	else:
		ch.camera.fov = lerpf(ch.camera.fov, ch.default_fov, delta * 10.0)
	
	if cooldown > 0.0:
		cooldown -= delta
	
	elif ch.wants_reload():
		ch._reloading_start()
		_reload_time = reload_time
		reload_started.emit()
	
	elif ch.is_reloading():
		if _reload_time <= 0.0:
			_update_clip(ch)
			_reload_time = 0.0
			ch._reloading_end()
			reloaded.emit()
		else:
			_reload_time -= delta
	
	elif ch.is_firing():
		if charge >= charge_time:
			if clip > 0:
				clip -= 1
				ch.spawn_projectile(ch.holding.get_node("%ProjectileOrigin"))
				cooldown = cooldown_time
				fired.emit()
		
		charge = minf(charge + delta, charge_time)
	
	else:
		charge = maxf(charge - delta, 0.0)

func _on_held_ended(ch: CharacterNode):
	super(ch)
	# Return remainder of clip to inventory.
	if clip:
		ch.character.gain("ammo", clip)
	
	# Make sure to reset the field of view when we swap away from this item.
	var tween := ch.get_tree().create_tween()
	tween.tween_property(ch.camera, "fov", ch.default_fov, 0.25)
	
