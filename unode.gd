class_name UNode

static func remember_parent(node: Node):
	node.set_meta(&"last_parent", node.get_parent())

static func reparent(node: Node):
	if node.has_meta(&"last_parent"):
		node.reparent(node.get_meta(&"last_parent"))
		node.remove_meta(&"last_parent")
