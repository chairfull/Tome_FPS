extends Node

signal closed()

@export var keycode := "4321"
@onready var buttons: GridContainer = %Buttons
@onready var input: Label = %Input
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var _input := ""
var _animating := false

func _ready() -> void:
	for btn in buttons.get_children():
		btn.pressed.connect(_pressed.bind(btn))
	clear()

func _pressed(btn: Button):
	if _animating:
		return
	
	_input += btn.text
	input.text = "-".repeat(len(keycode) - len(_input)) + _input
	
	if len(_input) == len(keycode):
		var passed := _input == keycode
		_animating = true
		if passed:
			animation_player.play(&"accepted")
		else:
			animation_player.play(&"denied")
		await animation_player.animation_finished
		_animating = false
		_input = ""
		clear()
		
		if passed:
			closed.emit()

func clear():
	input.text = "-".repeat(len(keycode))
