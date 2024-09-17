class_name Character
extends Resource

signal items_changed()

static var NONE := Character.new()

@export var items := {
	"ammo": 100
}

func count(id: StringName) -> int:
	return items.get(id, 0)

func gain(id: StringName, amount := 1):
	items[id] = items.get(id, 0) + amount
	items_changed.emit()

func lose(id: StringName, amount := 1):
	items[id] = items.get(id, 0) - amount
	items_changed.emit()
