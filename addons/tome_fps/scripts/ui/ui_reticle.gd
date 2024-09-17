@tool
extends Sprite2D

var character_node: CharacterNode
var dist := 0.0
var goal_fov := 20.0
var aiming := false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)

func _process(delta: float) -> void:
	if not character_node:
		character_node = owner.character_node
		#character_node.aiming_started.connect(_aim_started)
		#character_node.aiming_ended.connect(_aim_ended)
		return
	

		
	position = get_viewport_rect().size * .5
	dist = lerpf(dist, 8.0 + character_node.velocity.length() * 2.0, delta * 5.0)
	queue_redraw()

func _draw() -> void:
	for i in 4:
		draw_set_transform_matrix(
			Transform2D((i/4.0)*TAU, Vector2(0.0, 0.0)) *\
			Transform2D(0.0, Vector2(dist, 0))
		)
		draw_rect(Rect2(-8.0-2, -2.0-2, 16+4, 4+4), Color.BLACK, true)
		
	for i in 4:
		draw_set_transform_matrix(
			Transform2D((i/4.0)*TAU, Vector2(0.0, 0.0)) *\
			Transform2D(0.0, Vector2(dist, 0))
		)
		draw_rect(Rect2(-8.0, -2.0, 16, 4), Color.WHITE, true)
