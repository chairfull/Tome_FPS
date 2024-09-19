extends Node

@onready var message_box: VBoxContainer = %MessageBox
@onready var message: Label = %Message

func _ready() -> void:
	message_box.remove_child(message)
	Scene.get_main_scene().chatter_started.connect(_chatter_started)
	Scene.get_main_scene().chatter_ended.connect(_chatter_ended)

func _chatter_started(chatter: Chatter3D):
	var node := message.duplicate()
	message_box.add_child(node)
	node.text = chatter.speaker + ": " + chatter._message
	var tw := node.create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(node, "modulate:a", 0.0, 0.5)
	tw.finished.connect(node.queue_free)

func _chatter_ended(chatter: Chatter3D):
	pass
