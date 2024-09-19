class_name Chatter3D
extends Node3D
## A speaker who can say things.
## Has to wait for one thing to finish before saying another.
## But can cut off previous chatter.

## New chat being said or may be cut off.
signal started()
## Chat ended.
signal ended()

@export_storage var _timer: float
@export_storage var _message: String
@export var speaker: String

func _ready() -> void:
	set_process(false)

func is_chatting() -> bool:
	return _timer > 0.0

func say(msg: String):
	if is_chatting():
		# End previous.
		ended.emit()
		Scene.get_main_scene().chatter_ended.emit(self)
	
	_timer = len(msg) * .1
	_message = msg
	
	set_process(true)
	started.emit()
	Scene.get_main_scene().chatter_started.emit(self)

func _process(delta: float) -> void:
	if _timer <= 0.0:
		ended.emit()
		Scene.get_main_scene().chatter_ended.emit(self)
		_timer = 0.0
		set_process(false)
		return
	_timer -= delta
