extends Node

#func _notification(what):
	#match what:
		#NOTIFICATION_APPLICATION_FOCUS_IN:
			#print("focus in")
			##OS.set_low_processor_usage_mode(false)
		#NOTIFICATION_APPLICATION_FOCUS_OUT:
			#print("focus out")
			##OS.set_low_processor_usage_mode_sleep_usec(33000)
			##OS.set_low_processor_usage_mode(true)
		
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"restart_scene"):
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed(&"swap_character"):
		get_viewport().set_input_as_handled()
		var chars := get_tree().get_nodes_in_group("Character")
		var index := 0
		for i in len(chars):
			if chars[i].is_player():
				index = i
				break
		var new_index := (index + 1) % len(chars)
		for i in len(chars):
			chars[i].set_player.call_deferred(i == new_index)

func is_main_scene() -> bool:
	return get_tree().current_scene is MainScene

func get_main_scene() -> MainScene:
	return get_tree().current_scene as MainScene
