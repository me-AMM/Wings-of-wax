extends Node
# Starts judge_check.gd on the root so it survives scene changes.
func _ready() -> void:
	var n := Node.new()
	n.set_script(load("res://tools/judge_check.gd"))
	get_tree().root.add_child.call_deferred(n)
