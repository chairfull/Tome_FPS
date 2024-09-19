extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stopper: InteractiveNode = $Pivot/Stopper

var opening := false

func _ready() -> void:
	stopper.interacted.connect(_interacted)
	stopper.body_entered.connect(_body_entered)
	stopper.body_exited.connect(_body_exited)

func _interacted(event: Variant):
	if animation_player.is_playing():
		animation_player.pause()
	else:
		if opening:
			animation_player.play_backwards(&"open")
			opening = false
		else:
			animation_player.play(&"open")
			opening = true

func _body_entered(body: Node3D):
	if body is CharacterNode:
		animation_player.pause()

func _body_exited(body: Node3D):
	if len(stopper.get_overlapping_bodies()) == 0:
		if animation_player.current_animation and animation_player.current_animation_position < animation_player.current_animation_length:
			animation_player.play()
