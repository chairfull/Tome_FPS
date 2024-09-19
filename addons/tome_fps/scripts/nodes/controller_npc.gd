class_name ControllerNPC
extends ControllerNode

@onready var debug_draw: Node2D = $DebugDraw

enum Phase {
	## Standing idle.
	IDLE,
	## Walk to a random patrol point that is close by.
	PATROL_CLOSE,
	## Walk to a random patrol point that is far away.
	PATROL_FAR,
	
	AIM_TO_FIRE,
	FIND_HIGH_GROUND,
	
	## Moving to use something.
	MOVING_TO_RESTRAINER,
	## Inside some kind of restrainer.
	RESTRAINED,
	## Check if you see the player.
	INVESTIGATE_CHARACTER,
	## Investigating something from idle point.
	INVESTIGATE_FROM_IDLE,
	## Pathfinding towards where the problem was seen.
	INVESTIGATE_TARGET,
	## Investigate at target.
	INVESTIGATE_AT_TARGET,
	## Chasing another Character, like the player.
	CHASING,
	## Looking for a Character that was lost.
	LOST_CHASE,
	
	## Running away from something.
	EVADING,
	## Staying in one spot, in an attempt to hide.
	HIDING,
}

enum InvestigationType {
	NONE,
	SOUND,
	CHARACTER,
}

# Goto Item -> Pickup
# Goto Interactive -> Use
# Goto Character -> 
#		Far? -> Move Closer
#		Close? -> Move Away
#		Attack
# Goto -> Use Ladder?
# Goto -> Use Moving Platform?

@onready var state_chart: StateChart = %StateChart

var navagent: NavigationAgent3D
var chatter: Chatter3D

var sounds: Array[Sound3D]
var spotted: Array[CharacterNode]

## Node, Vector3, or null
var assignment: Variant = null

var investigating: Node3D
var investigate_point: Vector3
var timer := 0.0
var investigate_type := InvestigationType.NONE
var path_started := false
var path_end_event: StringName

## Where NPC was when chase started.
var target: CharacterNode
var target_last_position: Vector3
var target_last_direction: Vector3
var target_lost_timer := 0.0
var searching_timer := 0.0
var search_timer := 0.0
var stuck_timer := 0.0

var following_path := false

func _ready() -> void:
	navagent = character_node.navagent
	navagent.path_changed.connect(_path_changed)
	navagent.target_reached.connect(_path_ended)
	
	chatter = character_node.chatter
	
	set_physics_process(false)
	await get_tree().process_frame
	set_physics_process(true)
	
	#character_node.interactive.assigned.connect(_assigned)
	character_node.fov.spotted.connect(func(ch: CharacterNode):
		if not target:
			target = ch
			target_lost_timer = 5.0
			state_chart.send_event(&"target_spotted")
		spotted.append(ch))
	character_node.fov.unspotted.connect(func(ch):
		spotted.erase(ch))
	
	character_node.sound_listener.sound_started.connect(func(e: SoundEvent):
		sounds.append(e.source))
	character_node.sound_listener.sound_ended.connect(func(e: SoundEvent):
		sounds.erase(e.source))

func set_target_position(pos: Vector3, end_event: StringName = ""):
	navagent.target_position = pos
	path_started = true
	path_end_event = end_event
	state_chart.send_event(&"path_started")

#func set_phase(p: Phase):
	#var exiting := "_phase_%s_EXIT" % [Phase.keys()[phase].to_lower()]
	#if has_method(exiting):
		#call(exiting)
	#phase = p
	#var entering := "_phase_%s_ENTER" % [Phase.keys()[phase].to_lower()]
	#if has_method(entering):
		#call(entering)

#func _assigned(ass: Variant):
	#var navagent := character_node.navagent
	#assignment = ass
	#if assignment is Node:
		#navagent.target_position = ass.global_position
	#elif assignment is Vector3:
		## Jump out of seat.
		## TODO: Add some kind of check for if the character
		## can be interacted with when they are restrained.
		#if character_node.is_restrained():
			#character_node.set_restrainer(null)
		## Move to position.
		#navagent.target_position = ass

func _path_changed():
	debug_draw.path = Array(character_node.navagent.get_current_navigation_path())

func _path_ended():
	if path_started:
		path_started = false
		character_node.input_motion = Vector2.ZERO
		state_chart.send_event(&"path_ended")
		if path_end_event:
			state_chart.send_event(path_end_event)
		print("path ended")

#func _scan_for_sounds() -> bool:
	#if sounds:
		#phase = Phase.INVESTIGATE_FROM_IDLE
		#investigating = sounds[0]
		#investigate_point = sounds[0].global_position
		## The further the sound the longer they wait while scanning.
		#timer = character_node.global_position.distance_to(investigate_point)
		#investigate_type = InvestigationType.SOUND
		#return true
	#return false
#
#func _scan_for_character() -> bool:
	#if spotted:
		#for ch in spotted:
			#if ch.is_player():
				#print("Hey! There he is!")
				#timer = .1
				#chasing = ch
				#chase_origin = character_node.global_position
				#phase = Phase.CHASING
				#return true
	#return false

func _physics_process(delta: float):
	if target and not target in spotted:
		target_lost_timer -= delta
		if target_lost_timer <= 0.0:
			target = null
			chatter.say("Where'd they go!?")
			state_chart.send_event(&"target_lost")
	
	if Input.is_action_just_pressed(&"debug_npc"):
		#var player: Node3D = get_tree().get_first_node_in_group(&"Player")
		#set_target_position(player.get_interaction_point())
		var camera := get_viewport().get_camera_3d()
		var screen_position := get_viewport().get_mouse_position()
		var ray_origin := camera.project_ray_origin(screen_position)
		var ray_length := 30.0
		var ray_direction := camera.project_ray_normal(screen_position) * ray_length
		var space_state := get_world_3d().direct_space_state
		var result := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction))
		if result:
			chatter.say("On my way...")
			set_target_position(result.position)
	return
	
	#var health1 = character_node.head_health.health
	#var health2 = character_node.body_health.health
	#debug_draw.text = "%s\n%.2f\nHead: %s\nBody: %s" % [Phase.keys()[phase], timer, health1, health2]
	#
	## Draw last positions.
	#var points := []
	#for ch in character_node.fov._last_direction:
		#var pos := character_node.fov._last_positions[ch]
		#var dir := character_node.fov._last_direction[ch]
		#points.append(pos)
		#points.append(pos + dir.normalized() * 2.0)
	#debug_draw.points.assign(points)
	#
	#_move_to_target(delta)

func _reached_target():
	print("At target.")
	
	if assignment:
		if assignment is InteractiveNode:
			assignment.interaction_start({ character_node=character_node })
		elif assignment is Vector3:
			print("At point!")
		assignment = null

#func _move_to_target(delta: float):
	#var curr_position := character_node.global_position
	#
	#if navagent.is_navigation_finished() or navagent.distance_to_target() <= 0.005:
		#following_path = false
		#
		## Force finish.
		#if not navagent.is_navigation_finished():
			#navagent.target_position = curr_position
		#character_node.input_motion = Vector2.ZERO
		#
		#_reached_target()
	#
	#else:
		#following_path = true
		#
		#var next_position := navagent.get_next_path_position()
		#var dir := character_node.get_direction_to_point(next_position)
		#character_node.direction = lerp_angle(character_node.direction, dir, 5.0 * delta)
		#var move := next_position - curr_position
		#var dist := move.length()
		#move = move.normalized() * clampf(dist, 0.5, 1.0)
		#character_node.input_motion = Vector2(move.x, move.z)
		#
		##if last_position.distance_to(curr_position) <= 0.001:
			##stuck_timer += delta
			##print("Stuck?")
			##if stuck_timer > 3.0:
				##stuck_timer = 0.0
				##print("Unsticking self.")
				##phase = Phase.IDLE
				##navagent.target_position = character_node.global_position
	#
	#last_position = character_node.global_position

func _on_path_state_physics_processing(delta: float) -> void:
	
	if navagent.is_navigation_finished():
		_path_ended()
		#state_chart.send_event(&"path_ended")
	
	else:
		var curr_position := character_node.global_position
		var next_position := navagent.get_next_path_position()
		var dir := character_node.get_direction_to_point(next_position)
		character_node.direction = lerp_angle(character_node.direction, dir, 5.0 * delta)
		var move := next_position - curr_position
		var dist := move.length()
		move = move.normalized() * clampf(dist, 0.5, 1.0)
		character_node.input_motion = Vector2(move.x, move.z)

func _on_have_target_state_physics_processing(_delta: float) -> void:
	var targ_position := character_node.fov.get_future_position(target, 1.0)
	if targ_position:
		target_last_position = target.global_position
		target_last_direction = (targ_position - target.global_position).normalized()
		var curr := character_node.global_position
		var norm: Vector3 = curr - targ_position
		var dist := 1.0
		var next: Vector3 = targ_position + norm.normalized() * dist
		if curr.distance_to(target_last_position) <= 2.0:
			chatter.say("There you are! Grah!")
			state_chart.send_event(&"attack")
		else:
			set_target_position(next)

var attack_timer := 0.0

func _on_attack_state_physics_processing(delta: float) -> void:
	var targ_position := character_node.fov.get_future_position(target, 1.0)
	if targ_position:
		target_last_position = target.global_position
		target_last_direction = (targ_position - target.global_position).normalized()
		var curr := character_node.global_position
		if curr.distance_to(target_last_position) > 2.0:
			chatter.say("Get back here!")
			state_chart.send_event(&"target_out_of_range")
		else:
			attack_timer -= delta
			if attack_timer <= 0.0:
				print("Pew!")
				attack_timer = 1.0

func _on_searching_state_entered() -> void:
	searching_timer = 15.0
	chatter.say("Hmm... What was that?")

func _on_searching_state_physics_processing(delta: float) -> void:
	search_timer -= delta
	if search_timer <= 0.0:
		search_timer = randf_range(2.0, 5.0)
		var rand_offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		set_target_position(target_last_position + rand_offset * 5.0)
	
	searching_timer -= delta
	if searching_timer <= 0.0:
		chatter.say("Must have been the wind.")
		state_chart.send_event(&"giving_up_search")
