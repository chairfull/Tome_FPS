class_name Control3D
extends Area3D
## https://github.com/godotengine/godot-demo-projects/blob/master/viewport/gui_in_3d/gui_3d.gd

@onready var node_quad: CollisionShape3D = %CollisionShape3D
@onready var node_viewport: SubViewport = %SubViewport
var is_mouse_inside := false
var last_event_pos2D := Vector2.ZERO
var last_event_time := 0.0

func _ready() -> void:
	mouse_entered.connect(set.bind(&"is_mouse_inside", true))
	mouse_exited.connect(set.bind(&"is_mouse_inside", false))
	input_event.connect(_on_input_event)

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# Get mesh size to detect edges and make conversions. This code only supports PlaneMesh and QuadMesh.
	var shape: Vector3 = node_quad.shape.size
	var quad_mesh_size: Vector2 = Vector2(shape.x, shape.y)
	
	# Event position in Area3D in world coordinate space.
	var event_pos3D := event_position
	
	# Current time in seconds since engine start.
	var now := Time.get_ticks_msec() / 1000.0
	
	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: `affine_inverse()` accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D
	
	# TODO: Adapt to bilboard mode or avoid completely.
	
	var event_pos2D := Vector2()
	
	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)
		
		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5
		
		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.
		
	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)
