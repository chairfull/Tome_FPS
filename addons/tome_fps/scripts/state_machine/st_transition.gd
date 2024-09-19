class_name STTransition
extends Resource

@export var to: STTask
@export var event_type: StringName
@export var event_state: Dictionary[String, Variant]
@export_custom(PROPERTY_HINT_EXPRESSION, "") var test: String
