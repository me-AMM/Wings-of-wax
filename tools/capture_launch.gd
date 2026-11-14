# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Starts capture.gd on the root so it survives scene changes.
func _ready() -> void:
	var n := Node.new()
	n.set_script(load("res://tools/capture.gd"))
	get_tree().root.add_child.call_deferred(n)
