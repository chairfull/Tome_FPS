class_name Event
extends Resource

static var DAMAGE_3D := Damage3DEvent.new()

static var SOUND_3D_STARTED := Sound3DEvent.new()
static var SOUND_3D_ENDED := Sound3DEvent.new()

func emit(props: Dictionary, sig: Variant = null):
	for prop in props:
		if prop in self:
			self[prop] = props[prop]
	
	if sig is Signal:
		sig.emit(self)
	elif sig is Callable:
		sig.call(self)
