class_name FieldOfView3D
extends Area3D
## Detects other NPCs.

signal visible_changed()
signal spotted(ch: CharacterNode)
signal unspotted(ch: CharacterNode)

@export var ray: RayCast3D
@export var head: Node3D
var _in_area: Array[CharacterNode]
var _visible: Array[CharacterNode]
var _index := 0
var _last_positions: Dictionary[CharacterNode, Vector3]
var _last_direction: Dictionary[CharacterNode, Vector3]

func _ready() -> void:
	set_physics_process(false)
	if owner is CollisionObject3D:
		ray.add_exception(owner)
	ray.top_level = true
	body_entered.connect(_body_entered)
	body_exited.connect(_body_exited)

func get_last_position(ch: CharacterNode) -> Variant:
	if ch in _last_positions:
		return _last_positions[ch]
	return null

func get_future_position(ch: CharacterNode, future := 1.0) -> Variant:
	if ch in _last_direction:
		return _last_positions[ch] + _last_direction[ch].normalized() * future
	return null

func can_see(ch: CharacterNode) -> bool:
	return ch in _visible

func _physics_process(delta: float) -> void:
	if _in_area or _visible:
		# Pick a random character.
		_index = (_index + 1) % len(_in_area)
		var ch := _in_area[_index]
		ray.global_position = head.global_position
		ray.target_position = ch.global_position - ray.global_position
		ray.target_position.y = 0.0
		ray.target_position = ray.target_position.normalized() * 8.0
		if ray.is_colliding() and ray.get_collider() == ch and ch.light_detector.brightness >= 0.5:
			if ch not in _visible:
				_visible.append(ch)
				visible_changed.emit()
				spotted.emit(ch)
		else:
			if ch in _visible:
				_visible.erase(ch)
				visible_changed.emit()
				unspotted.emit(ch)
	
	for v in _visible:
		# Calculate directions.
		if v in _last_positions:
			_last_direction[v] = v.global_position - _last_positions[v]
		# Track last spotted position.
		_last_positions[v] = v.global_position

func _body_entered(body: Node3D):
	if body == owner:
		return
	_in_area.append(body)
	set_physics_process(true)

func _body_exited(body: Node3D):
	if body == owner:
		return
	_in_area.erase(body)
	
	if body in _visible:
		_visible.erase(body)
		visible_changed.emit()
		unspotted.emit(body)

	set_physics_process(len(_in_area) > 0 or len(_visible) > 0)
