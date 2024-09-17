class_name CharacterNode
extends CharacterBody3D

signal restrainer_entered(restrainer: RestrainerNode)
signal restrainer_exited(restrainer: RestrainerNode)
signal interactive_focused(interactive: InteractiveNode)
signal interactive_unfocused(interactive: InteractiveNode)
signal interactive_selected(interactive: InteractiveNode)
signal interactive_deselected(interactive: InteractiveNode)
signal holding_started(item: ItemNode)
signal holding_ended(item: ItemNode)
## Used for updating the label if the object is within selection or interaction range.
signal interactive_distance_changed()

signal event(event)
signal aiming_started()
signal aiming_ended()

static var EVENT_JUMPED := { character=null }
static var EVENT_LANDED := { character=null, distance=0.0 }
static var EVENT_AIM_STARTED := {}
static var EVENT_AIM_ENDED := {}

enum Stance { STAND, CRAWL, PRONE }

const JUMP_VELOCITY = 4.0
const COYOTE_TIME = 0.2
const MAX_JUMP_HOLD_TIME = 0.25

@export var character: Character: get=get_character
@export var _player := false: set=set_player, get=is_player
@export var speed_default := 3.0
@export var speed_crawl := 1.0
@export var speed_prone := 0.1
@export var speed_sprint := 6.0
@export var default_fov := 70.0
@export var interact_distance := 2.0
@export var select_distance := 15.0

var area: StringName = &""

var direction: float:
	get: return -head.rotation.y
	set(r):
		head.rotation.y = -r
		equipment.rotation.y = -r
var input_motion := Vector2.ZERO
var input_rotation := Vector2.ZERO
var holding: ItemNode: set=set_holding
var holding_state: Item
var stance := Stance.STAND: set=set_stance
var _restrainer: RestrainerNode: set=set_restrainer
var _sprinting := false
var _jumping := false
var _aiming := false
var _firing := false
var _reload := false
var _reloading := false
var _coyote_time := 0.0
var _was_in_air := false
var _fall_height := 0.0
var _anim_bob := 0.0
var _interactive: InteractiveNode
var _interactive_distance: float
var _interacting := false
var _selected: InteractiveNode: set=set_selected

@onready var head: Node3D = %Head
@onready var headbob: Node3D = %Bob
@onready var equipment: CharacterEquipmentNode = $Equipment
@onready var crouch_animation: AnimationPlayer = $CrouchAnimation
@onready var crawl_ceiling_detection: ShapeCast3D = $CrawlCeilingDetection
@onready var prone_ceiling_detection: ShapeCast3D = $ProneCeilingDetection
@onready var interactive_detector: ShapeCast3D = $Head/InteractiveDetector
@onready var camera: Camera3D = %Camera
@onready var headbob_animation: AnimationPlayer = $Head/HeadbobAnimation
@onready var jump_animation: AnimationPlayer = $Head/JumpAnimation
@onready var camera_ray: RayCast3D = %CameraRay
@onready var interactive: InteractiveNode = $Interactive
@onready var navagent: NavigationAgent3D = $NavAgent
@onready var fov: FieldOfView3D = %FOV
@onready var light_detector: LightDetectorViewport = $LightDetectorVP
@onready var sound_listener: SoundListener3D = $Head/SoundListener
@onready var head_health: Damagable3D = %HeadHealth
@onready var body_health: Damagable3D = %BodyHealth

func _ready() -> void:
	camera_ray.add_exception(self)
	interactive_detector.add_exception(self)
	interactive_detector.add_exception(interactive)
	# Transfer potential rotation to the head.
	head.rotation.y = -rotation.y
	rotation.y = 0.0
	set_player(_player)

func get_character() -> Character:
	return character if character else Character.NONE

func set_player(p: bool):
	_player = p
	var old_controller := get_controller()
	if old_controller:
		old_controller.get_parent().remove_child(old_controller)
		old_controller.queue_free()
	var path: String
	if p:
		path = "res://addons/tome_fps/scenes/controller_player.tscn"
	else:
		path = "res://addons/tome_fps/scenes/controller_npc.tscn"
	var new_controller: Node = load(path).instantiate()
	new_controller.character_node = self
	new_controller.name = "Controller"
	%Head.add_child(new_controller)
	#new_controller.set_owner.call_deferred(self)
	
	if p:
		toggle_visuals(false)
		if interactive:
			interactive.disabled = true
	else:
		toggle_visuals(true)
		if interactive:
			interactive.disabled = false

func get_direction_to_point(point: Vector3) -> float:
	var dir := point - global_position
	dir.y = 0.0
	dir = dir.normalized()
	return atan2(dir.x, -dir.z)

func toggle_visuals(vis := true):
	find_child("Viser").visible = vis
	find_child("Mesh").visible = vis

func is_player() -> bool:
	return get_controller() is ControllerPlayer

func is_npc() -> bool:
	return get_controller() is ControllerNPC

func get_controller() -> ControllerNode:
	return get_node_or_null(^"Head/Controller")

func is_standing() -> bool:
	return stance == Stance.STAND

func is_crawling() -> bool:
	return stance == Stance.CRAWL

func is_prone() -> bool:
	return stance == Stance.PRONE

## Is in a Restrainer?
func is_restrained() -> bool:
	return _restrainer != null

## Remove from Restrainer.
func eject():
	if is_restrained():
		_restrainer.eject()

func _reload_start():
	if not _reloading:
		_reload = true

func _reloading_start():
	_reload = false
	_reloading = true

func _reloading_end():
	_reloading = false
	_reload = false

func wants_reload() -> bool:
	return _reload

func is_reloading() -> bool:
	return _reloading

func _sprint():
	_sprinting = true

func _sprint_end():
	_sprinting = false

func _jump():
	match stance:
		Stance.STAND:
			if is_on_floor() or _coyote_time > 0.0:
				velocity.y = JUMP_VELOCITY
				_coyote_time = 0.0
				_jumping = true
				do_event(EVENT_JUMPED, {})
		
		Stance.CRAWL:
			stance = Stance.STAND
		
		Stance.PRONE:
			stance = Stance.CRAWL

func _jump_end():
	_jumping = false
	
	if velocity.y > 0.0:
		velocity.y *= .5

func is_aiming() -> bool:
	return _aiming

func _aim_start():
	_aiming = true
	aiming_started.emit()

func _aim_end():
	_aiming = false
	aiming_ended.emit()

func is_firing() -> bool:
	return _firing

func _fire_start():
	_firing = true

func _fire_end():
	_firing = false

func _crouch():
	match stance:
		Stance.STAND:
			stance = Stance.CRAWL
		
		Stance.CRAWL:
			stance = Stance.PRONE
	
		Stance.PRONE:
			pass

func set_stance(s: Stance):
	match [stance, s]:
		[Stance.STAND, Stance.CRAWL]: crouch_animation.play(&"crouch")
		[Stance.CRAWL, Stance.PRONE]: crouch_animation.play(&"prone")
		[Stance.CRAWL, Stance.STAND]:
			# Blocked?
			if crawl_ceiling_detection.is_colliding():
				return
			crouch_animation.play_backwards(&"crouch")
		[Stance.PRONE, Stance.CRAWL]:
			# Blocked?
			if prone_ceiling_detection.is_colliding():
				return
			crouch_animation.play_backwards(&"prone")
	
	stance = s

func set_holding(h: ItemNode):
	if h == holding:
		return
	
	if holding:
		UNode.reparent(holding)
		if holding.has_meta(&"posessor"):
			holding.remove_meta(&"posessor")
		holding.posession_state = ItemNode.PosessionState.IDLE
		
		# TODO:
		# holding.state = holding_state
		if holding_state.ui and is_player():
			Scene.get_main_scene().hide_ui(holding_state.ui)
			Scene.get_main_scene().show_ui("item_NONE", { character_node=self })
		holding_state._on_held_ended(self)
		holding_state = null
		holding_ended.emit(holding)
	
	holding = h
	
	if holding:
		UNode.remember_parent(holding)
		holding.reparent(headbob)
		holding.set_meta(&"posessor", self)
		holding.posession_state = ItemNode.PosessionState.EQUIPPED
		
		holding_state = holding.item.duplicate(true)
		holding_state._on_held_started(self)
		holding_started.emit(holding)

func get_restrainer() -> RestrainerNode:
	return _restrainer

func set_restrainer(re: RestrainerNode):
	if re == _restrainer:
		return
	
	if _restrainer:
		restrainer_exited.emit(_restrainer)
	
	_restrainer = re
	
	if _restrainer:
		if is_interacting():
			_interaction_end()
		restrainer_entered.emit(_restrainer)

func _physics_process(delta: float) -> void:
	if is_restrained():
		if not _restrainer.lock_player_head:
			_update_head_rotation(delta)
		return
	
	if holding_state:
		holding_state._on_held(self, delta)
	
	# Apply gravity.
	if is_on_floor():
		if _was_in_air:
			_was_in_air = false
			var height := global_position.y
			var distance := _fall_height - height
			do_event(EVENT_LANDED, { distance=distance })
		
		# Reset coyote.
		_coyote_time = COYOTE_TIME
	else:
		_was_in_air = true
		_fall_height = maxf(_fall_height, global_position.y)
		
		# Apply gravity.
		velocity += get_gravity() * delta
		# Coyote time cooldown.
		if not _jumping:
			_coyote_time -= delta
	
	# Apply movement and velocity.
	var speed := 0.0
	match stance:
		Stance.STAND:
			speed = speed_default
			if _sprinting:
				speed *= 2.0
		Stance.CRAWL:
			speed = speed_crawl
			if _sprinting:
				speed *= 1.5
		Stance.PRONE:
			speed = speed_prone
			if _sprinting:
				speed *= 1.25
	
	velocity.x = input_motion.x * speed
	velocity.z = input_motion.y * speed
	move_and_slide()
	
	var vel := velocity.length()
	if vel:
		_anim_bob += delta * vel
		headbob.position.y = lerpf(camera.position.y, sin(_anim_bob * 2.0) * 0.1 * vel, delta * 20.0)
		headbob.position.x = lerpf(camera.position.x, sin(_anim_bob * 1.0) * 0.2 * vel, delta * 20.0)
	else:
		headbob.position.x = lerpf(headbob.position.x, 0.0, delta * 5.0)
		headbob.position.y = lerpf(headbob.position.y, 0.0, delta * 5.0)
	
	_update_head_rotation(delta)
	_update_interactive_detection()

func _update_head_rotation(delta: float):
	var fov_delta := camera.fov / default_fov
	head.rotation_degrees.y -= input_rotation.x * fov_delta
	head.rotation_degrees.x -= input_rotation.y * fov_delta
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-90.0), deg_to_rad(90.0))
	equipment.rotation.y = lerp_angle(equipment.rotation.y, head.rotation.y, 10.0 * delta)
	input_rotation = Vector2.ZERO

func sees_interactive() -> bool:
	return _interactive != null

func sees_selectable() -> bool:
	return _interactive != null and _interactive.selectable

func is_interactive_in_range() -> bool:
	return _interactive_distance <= interact_distance

func is_selectable_in_range() -> bool:
	return _interactive_distance <= select_distance

func is_interacting() -> bool:
	return _interacting

func get_interaction_point() -> Vector3:
	if interactive_detector.is_colliding():
		return interactive_detector.get_collision_point(0)
	else:
		return interactive_detector.global_position + interactive_detector.target_position

func get_interaction_normal() -> Vector3:
	if interactive_detector.is_colliding():
		return interactive_detector.get_collision_normal(0)
	else:
		return Vector3.UP

func _interaction_start():
	if has_selection():
		if sees_interactive():
			_selected.assign_to_node(_interactive, null)
			_deselect()
		else:
			_selected.assign_to_point(get_interaction_point(), null)
			_deselect()
	else:
		if sees_interactive() and not is_interacting() and is_interactive_in_range():
			_interacting = true
			_interactive.interaction_start({ character_node=self })

func _interaction_end():
	if is_interacting():
		_interacting = false
		_interactive.interaction_end()

func _select():
	if sees_selectable() and not is_interacting() and is_selectable_in_range():
		_selected = _interactive

func _deselect():
	if has_selection():
		_selected = null

func set_selected(s: InteractiveNode):
	if _selected == s:
		return
	
	if _selected:
		interactive_deselected.emit(_selected)
	_selected = s
	if _selected:
		interactive_selected.emit(_selected)
	interactive_distance_changed.emit()

func has_selection() -> bool:
	return _selected != null

func _update_interactive_detection():
	if is_interacting():
		return
	
	var info := _detect_interactive()
	if is_player():
		print(info)
	if info.interactive != _interactive:
		if _interactive:
			_interactive._focus_exited()
			interactive_unfocused.emit(_interactive)
		
		_interactive = info.interactive
		_interactive_distance = info.distance
		interactive_distance_changed.emit()
		
		if _interactive:
			_interactive._focus_entered()
			interactive_focused.emit(_interactive)
	
	if _interactive:
		var old_distance := _interactive_distance
		_interactive_distance = info.distance
		
		var old := old_distance <= interact_distance
		var new := _interactive_distance <= interact_distance
		if old != new:
			interactive_distance_changed.emit() 

func _detect_interactive() -> Dictionary:
	if interactive_detector.is_colliding():
		var inter := interactive_detector.get_collider(0)
		if inter is InteractiveNode:
			if has_selection():
				if inter != _selected:
					if _selected.can_assign_to_node(inter, null):
						var point := interactive_detector.get_collision_point(0)
						var distance := interactive_detector.global_position.distance_to(point)
						return { interactive=inter, distance=distance }
			else:
				if inter.can_interact({ character_node=self }):
					var point := interactive_detector.get_collision_point(0)
					var distance := interactive_detector.global_position.distance_to(point)
					if distance <= interact_distance:
						return { interactive=inter, distance=distance }
					elif distance <= select_distance and inter.selectable:
						return { interactive=inter, distance=distance }
	return { interactive=null, distance=INF }

func do_event(ev: Variant, props: Dictionary):
	for key in props:
		if key in ev:
			ev[key] = props[key]
	event.emit(ev)

func spawn_projectile(barrel: Node3D):
	var ray := camera_ray
	var look_at := ray.global_position + ray.target_position
	if ray.is_colliding():
		look_at = ray.get_collision_point()
	
	# Point barrel at camera reticle origin.
	barrel.look_at(look_at)
	var normal := -barrel.global_basis.z.normalized()
	var origin := barrel.global_position
	var proj := Projectile3D.create(origin, normal * 30.0)
	var hit_info = await proj.finished
	if hit_info:
		var decal: Node = load("res://addons/tome_fps/scenes/decal.tscn").instantiate()
		get_tree().current_scene.add_child(decal)
		decal.global_position = hit_info.position
