class_name Event
extends Resource

static var DAMAGE := DamageEvent.new()
static var HEALING := HealingEvent.new()

static var SOUND_STARTED := SoundEvent.new()
static var SOUND_ENDED := SoundEvent.new()

func emit(props: Dictionary, sig: Variant = null):
	for prop in props:
		if prop in self:
			self[prop] = props[prop]
	
	if sig is Signal:
		sig.emit(self)
	elif sig is Callable:
		sig.call(self)
