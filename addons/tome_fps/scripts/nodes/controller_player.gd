class_name ControllerPlayer
extends ControllerNode

@export var mouse_sensitivity : float = 0.1
@onready var cursor: Node3D = %Cursor

var crouch_countdown := 0.0
var stand_countdown := 0.0

func _ready() -> void:
	%interactive.visible = false
	
	await get_tree().process_frame
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	Scene.get_main_scene().show_ui(&"item_NONE", { character_node=character_node })
	
	# TODO: Disable these less distructivley.
	character_node.fov.queue_free()
	character_node.sound_listener.queue_free()
	
	character_node.camera.make_current()
	
	character_node.damaged.connect(_damaged)
	
	character_node.interactive_selected.connect(func(inter):
			cursor.visible = true)
	character_node.interactive_deselected.connect(func(inter):
			cursor.visible = false)
	
	character_node.holding_started.connect(func(holding: ItemNode):
			if holding.item.ui:
				Scene.get_main_scene().hide_ui(&"item_NONE")
				Scene.get_main_scene().show_ui(holding.item.ui, { character_node=character_node })
			)
	character_node.holding_ended.connect(func(holding: ItemNode):
			if holding.item.ui:
				Scene.get_main_scene().hide_ui(holding.item.ui)
				Scene.get_main_scene().show_ui(&"item_NONE", { character_node=character_node })
			)
	character_node.restrainer_entered.connect(func(r: RestrainerNode):
			if r.lock_player_head:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			#user_interface.visible = false
			character_node.toggle_visuals(true)
			if character_node.holding and character_node.holding.item.ui:
				Scene.get_main_scene().hide_ui(character_node.holding.item.ui)
			)
	character_node.restrainer_exited.connect(func(r):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			#user_interface.visible = true
			character_node.toggle_visuals(false)
			character_node.camera.make_current()
			if character_node.holding and character_node.holding.item.ui:
				Scene.get_main_scene().show_ui(character_node.holding.item.ui, { character_node=character_node })
			)
	
	character_node.event.connect(func(e):
			match e:
				CharacterNode.EVENT_JUMPED:
					character_node.jump_animation.play(&"jump")
				CharacterNode.EVENT_LANDED:
					if randi() % 2 == 0:
						character_node.jump_animation.play(&"land_left")
					else:
						character_node.jump_animation.play(&"land_right")
			)
	
	character_node.interactive_distance_changed.connect(func():
			var inter: InteractiveNode = character_node._interactive
			if not inter:
				%interactive.visible = false
			else:
				%interactive.visible = true
				var label: String = inter.get_label({ character_node=character_node })
				var label_select := "Select %s" % inter.name
				if character_node.has_selection():
					if character_node.sees_selectable():
						%label.text = "[E] Assign %s to %s\n[F] %s" % [character_node._selected.name, inter.name, label_select]
					else:
						%label.text = "[E] Assign %s to %s" % [character_node._selected.name, inter.name]
				elif character_node.sees_selectable() and character_node.is_interactive_in_range():
					%label.text = "[E] %s\n[F] %s" % [label, label_select]
				elif character_node.sees_interactive() and character_node.is_interactive_in_range():
					%label.text = "[E] %s" % [label]
				else:
					%label.text = "[F] %s" % [label_select]
			)

func _damaged(e: DamageEvent):
	var rot := PI - character_node.direction + character_node.get_direction_to_point(e.source.global_position)
	%DamageIndicator.visible = true
	%DamageIndicator.rotation = rot + PI * .5
	%DamageIndicator.position = get_viewport().size * .5 + Vector2(sin(-rot), cos(-rot)) * 64.0
	var tw := get_tree().create_tween()
	tw.tween_property(%DamageIndicator, "modulate:a", 1.0, 0.125)
	await tw.finished
	await get_tree().create_timer(.5).timeout
	var tw2 := get_tree().create_tween()
	tw2.tween_property(%DamageIndicator, "modulate:a", 0.0, 0.25)
	await tw2.finished
	%DamageIndicator.visible = false

func _physics_process(delta: float) -> void:
	var ld := character_node.light_detector
	%LightLevel.text = "Light: %s" % [ld.brightness]
	%LightGem.color = lerp(Color.BLACK, Color.WHITE, ld.brightness)

	if character_node.has_selection():
		# Detects something it can assign to?
		if character_node.sees_interactive():
			cursor.visible = true
			cursor.global_position = character_node._interactive.global_position
		# Can assign to a position.
		elif character_node._selected.can_assign_to_point(character_node.get_interaction_point()):
			cursor.visible = true
			cursor.global_position = character_node.get_interaction_point()
		else:
			cursor.visible = false
		
	var motion := Input.get_vector(&"left", &"right", &"forward", &"backward")
	
	if character_node.is_restrained():
		if Input.is_action_just_pressed(&"eject"):
			character_node.eject()
		else:
			var rest := character_node._restrainer
			if motion:
				rest.controller_input.emit(&"move", motion)
			if Input.is_action_just_pressed(&"jump"):
				rest.controller_input.emit(&"jump", true)
			rest.controller_process.emit(delta)
	
	else:
		character_node.input_motion = motion.rotated(character_node.direction)
		
		# Align text with object.
		if character_node.sees_interactive():
			var vp := get_viewport()
			var cam := vp.get_camera_3d()
			var pos := character_node._interactive.global_position
			if character_node._interactive.label_node:
				pos = character_node._interactive.label_node.global_position
			pos += character_node._interactive.label_offset
			if cam.is_position_in_frustum(pos):
				var pos2d := cam.unproject_position(pos)
				%interactive.position = pos2d - %interactive.size * .5
		
		# Interact.
		if Input.is_action_just_pressed(&"interact"):
			character_node._interaction_start()
		elif Input.is_action_just_released(&"interact"):
			character_node._interaction_end()
		# Select.
		elif Input.is_action_just_pressed(&"select"):
			if character_node.has_selection():
				character_node._deselect()
			else:
				character_node._select()
		
		if Input.is_action_just_pressed(&"drop"):
			character_node.holding = null
		
		if Input.is_action_just_pressed(&"aim"):
			character_node._aim_start()
		elif Input.is_action_just_released(&"aim"):
			character_node._aim_end()
		
		if Input.is_action_just_pressed(&"fire"):
			character_node._fire_start()
		elif Input.is_action_just_released(&"fire"):
			character_node._fire_end()
		
		if Input.is_action_just_pressed(&"reload"):
			character_node._reload_start()
		
		# Run.
		if Input.is_action_just_pressed(&"sprint"):
			character_node._sprint()
		elif Input.is_action_just_released(&"sprint"):
			character_node._sprint_end()
		
		# Jump.
		if Input.is_action_just_pressed(&"jump"):
			stand_countdown = 0.0
			character_node._jump()
		elif Input.is_action_pressed(&"jump"):
			stand_countdown += delta
			# If not standing, holding jump will change stance.
			if stand_countdown > 0.5 and not character_node.is_standing():
				character_node._jump()
		elif Input.is_action_just_released(&"jump"):
			character_node._jump_end()
		
		# Crouching + prone.
		if Input.is_action_just_pressed(&"crouch"):
			crouch_countdown = 0.0
			if not character_node.is_prone():
				character_node._crouch()
		elif Input.is_action_pressed(&"crouch"):
			crouch_countdown += delta
			if crouch_countdown > 0.5 and not character_node.is_prone():
				character_node._crouch()
		
		if Input.is_action_just_pressed(&"unlock_cursor"):
			get_viewport().set_input_as_handled()
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		if Input.is_action_just_pressed(&"debug_play_sound"):
			print("Play sodun...")
			Sound3D.create(character_node.get_interaction_point())
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rotation: Vector2 = event.relative * mouse_sensitivity
		if character_node.is_restrained() and character_node._restrainer.lock_player_head:
			character_node._restrainer.controller_input.emit(&"rotate", character_node._restrainer)
		else:
			character_node.input_rotation += rotation
		
	# Uncomment for controller support
	#var controller_view_rotation = Input.get_vector(LOOK_DOWN, LOOK_UP, LOOK_RIGHT, LOOK_LEFT) * controller_sensitivity # These are inverted because of the nature of 3D rotation.
	#HEAD.rotation.x += controller_view_rotation.x
	#if invert_mouse_y:
		#HEAD.rotation.y += controller_view_rotation.y * -1.0
	#else:
		#HEAD.rotation.y += controller_view_rotation.y
