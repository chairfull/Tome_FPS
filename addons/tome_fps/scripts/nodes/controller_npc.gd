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

var navagent: NavigationAgent3D
var phase := Phase.IDLE: set=set_phase
var last_position := Vector3.ZERO

var sounds: Array[Sound3D]
var spotted: Array[CharacterNode]

## Node, Vector3, or null
var assignment: Variant = null

var investigating: Node3D
var investigate_point: Vector3
var timer := 0.0
var investigate_type := InvestigationType.NONE

## Where NPC was when chase started.
var chase_origin := Vector3.ZERO
var chasing: CharacterNode
var stuck_timer := 0.0

var following_path := false

func _ready() -> void:
	set_physics_process(false)
	await get_tree().process_frame
	set_physics_process(true)
	
	navagent = character_node.navagent
	navagent.path_changed.connect(_path_changed)
	last_position = character_node.global_position
	#navagent.path_desired_distance = 1.5
	#navagent.target_desired_distance = 1.5
	
	character_node.interactive.assigned.connect(_assigned)
	character_node.fov.spotted.connect(func(ch: CharacterNode):
		spotted.append(ch))
	character_node.fov.unspotted.connect(func(ch):
		spotted.erase(ch))
	
	character_node.sound_listener.sound_started.connect(func(e: Sound3DEvent):
		sounds.append(e.source))
	character_node.sound_listener.sound_ended.connect(func(e: Sound3DEvent):
		sounds.erase(e.source))

func set_phase(p: Phase):
	var exiting := "_phase_%s_EXIT" % [Phase.keys()[phase].to_lower()]
	if has_method(exiting):
		call(exiting)
	phase = p
	var entering := "_phase_%s_ENTER" % [Phase.keys()[phase].to_lower()]
	if has_method(entering):
		call(entering)

func _assigned(ass: Variant):
	var navagent := character_node.navagent
	assignment = ass
	if assignment is Node:
		navagent.target_position = ass.global_position
	elif assignment is Vector3:
		# Jump out of seat.
		# TODO: Add some kind of check for if the character
		# can be interacted with when they are restrained.
		if character_node.is_restrained():
			character_node.set_restrainer(null)
		# Move to position.
		navagent.target_position = ass

func _path_changed():
	debug_draw.path = Array(character_node.navagent.get_current_navigation_path())

func _phase_idle_ENTER():
	timer = get_random_wait_time()
	
func _phase_idle(delta: float):
	if _scan_for_character():
		return
	
	if timer <= 0.0:
		var pos := Scene.get_main_scene().get_random_patrol(character_node.area)
		if pos:
			print("Starting patrol...")
			navagent.target_position = pos
			phase = Phase.PATROL_CLOSE
			return
		else:
			timer = get_random_wait_time()
	
	if _scan_for_sounds():
		return

func _phase_patrol(delta: float):
	if not following_path:
		print("Patrol ended.")
		phase = Phase.IDLE

func _phase_investigate_from_idle(delta: float):
	# Rotate to point.
	var goal_angle := character_node.get_direction_to_point(investigate_point)# + sin(timer * TAU) * .05
	character_node.direction = lerp_angle(character_node.direction, goal_angle, delta * 5.0)
	
	if _scan_for_character():
		return false
	
	if timer <= 0.0:
		navagent.target_position = investigate_point
		phase = Phase.INVESTIGATE_TARGET

func _phase_investigate_target(delta: float):
	if navagent.is_navigation_finished():
		timer = 5.0
		phase = Phase.INVESTIGATE_AT_TARGET

func _phase_investigate_at_target(delta: float):
	print("Investigating at target...")
	
	var goal_angle := character_node.direction + sin(timer * TAU) * .05
	character_node.direction = lerp_angle(character_node.direction, goal_angle, delta * 5.0)
	
	if timer <= 0.0:
		print("Nothing found.")
		phase = Phase.IDLE

func _phase_chasing(delta: float):
	if timer <= 0.0 and navagent.is_navigation_finished():
		print("Got away!?")
		navagent.set_target_position(chase_origin)
		timer = 1.0
		phase = Phase.LOST_CHASE
		return
	
	var future_position := character_node.fov.get_future_position(chasing)
	if future_position:
		navagent.set_target_position(future_position)

func _phase_lost_chase(delta: float):
	character_node.direction += sin(timer * TAU) * .05
	
	if timer <= 0.0:
		print("Lost him!")
		phase = Phase.IDLE

func get_random_wait_time() -> float:
	return randf_range(10.0, 20.0)

func _scan_for_sounds() -> bool:
	if sounds:
		phase = Phase.INVESTIGATE_FROM_IDLE
		investigating = sounds[0]
		investigate_point = sounds[0].global_position
		# The further the sound the longer they wait while scanning.
		timer = character_node.global_position.distance_to(investigate_point)
		investigate_type = InvestigationType.SOUND
		return true
	return false

func _scan_for_character() -> bool:
	if spotted:
		for ch in spotted:
			if ch.is_player():
				print("Hey! There he is!")
				timer = .1
				chasing = ch
				chase_origin = character_node.global_position
				phase = Phase.CHASING
				return true
	return false

func _physics_process(delta: float):
	return
	
	if timer > 0.0:
		timer -= delta
	else:
		timer = 0.0
	
	match phase:
		Phase.IDLE: _phase_idle(delta)
		Phase.INVESTIGATE_FROM_IDLE: _phase_investigate_from_idle(delta)
		Phase.INVESTIGATE_TARGET: _phase_investigate_target(delta)
		Phase.INVESTIGATE_AT_TARGET: _phase_investigate_at_target(delta)
		Phase.CHASING: _phase_chasing(delta)
		Phase.LOST_CHASE: _phase_lost_chase(delta)
	
	var health1 := character_node.head_health.health
	var health2 := character_node.body_health.health
	debug_draw.text = "%s\n%.2f\nHead: %s\nBody: %s" % [Phase.keys()[phase], timer, health1, health2]
	
	# Draw last positions.
	var points := []
	for ch in character_node.fov._last_direction:
		var pos := character_node.fov._last_positions[ch]
		var dir := character_node.fov._last_direction[ch]
		points.append(pos)
		points.append(pos + dir.normalized() * 2.0)
	debug_draw.points.assign(points)
	
	if Input.is_action_just_pressed(&"npc_debug"):
		var player: Node3D = get_tree().get_first_node_in_group(&"Player")
		navagent.target_position = player.global_position
	
	var curr_position := character_node.global_position
	
	if navagent.is_navigation_finished() or navagent.distance_to_target() <= 0.5:
		following_path = false
		
		# Force finish.
		if not navagent.is_navigation_finished():
			navagent.target_position = curr_position
		character_node.input_motion = Vector2.ZERO
		debug_draw.path.clear()
		
		if assignment:
			if assignment is InteractiveNode:
				assignment.interaction_start({ character_node=character_node })
			elif assignment is Vector3:
				print("At point!")
			assignment = null
	
	else:
		following_path = true
		
		var next_position := navagent.get_next_path_position()
		var dir := character_node.get_direction_to_point(next_position)
		character_node.direction = lerp_angle(character_node.direction, dir, 5.0 * delta)
		var move := next_position - curr_position
		var dist := move.length()
		move = move.normalized() * clampf(dist, 0.5, 1.0)
		character_node.input_motion = Vector2(move.x, move.z)
		
		if last_position.distance_to(curr_position) <= 0.001:
			stuck_timer += delta
			print("Stuck?")
			if stuck_timer > 3.0:
				stuck_timer = 0.0
				print("Unsticking self.")
				phase = Phase.IDLE
				navagent.target_position = character_node.global_position
	
	last_position = character_node.global_position
