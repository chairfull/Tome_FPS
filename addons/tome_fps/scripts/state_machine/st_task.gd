class_name STTask
extends Resource

enum Status { NONE, RUNNING, FAILED, SUCCEEDED }

func _enter():
	pass

func _exit():
	pass

func _tick(_delta: float) -> Status:
	return Status.SUCCEEDED
