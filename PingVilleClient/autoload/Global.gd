extends Node


func instance_node(node, parent, position):
	var node_instance = node.instance()
	node_instance.global_position = position
	parent.add_child(node_instance)
	return node_instance
