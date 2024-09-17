class_name Sound3D
extends Area3D
## A sound wave that checks if any listener can hear it, and triggers them.

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ray_cast: RayCast3D = $RayCast3D
@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _ignore: Array[SoundListener3D]
var _listeners: Array[SoundListener3D]

static func create(at: Vector3):
	var node: Node3D = load("res://addons/tome_fps/scenes/sound_3d.tscn").instantiate()
	Scene.get_main_scene().get_world().add_child(node)
	node.global_position = at
	return node

func _ready() -> void:
	print("Created")
	area_entered.connect(_entered)
	area_exited.connect(_exited)
	
	audio_stream_player.play()
	await audio_stream_player.finished
	queue_free()

func _exit_tree() -> void:
	for area in _listeners:
		_ended(area)

func add_exception(sl: SoundListener3D):
	_ignore.append(sl)

func _entered(area: Area3D):
	print(area)
	if area is SoundListener3D and not area in _ignore:
		_listeners.append(area)
		Event.SOUND_STARTED.emit(get_event_state(), area.sound_started)

func _exited(area: Area3D):
	print(area)
	if area is SoundListener3D:
		_listeners.erase(area)
		_ended(area)

func _ended(area: SoundListener3D):
	Event.SOUND_ENDED.emit(get_event_state(), area.sound_ended)

func get_event_state() -> Dictionary:
	return { source=self, position=global_position }
