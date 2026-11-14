# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends CanvasLayer
# Scenes autoload: Scenes.go("res://scenes/X.tscn") changes scene with a 0.2 s fade out and in.
var rect: ColorRect
var busy := false
var pending := ""         # a change requested while another one is running

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.size = Vector2(640, 360)
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

func go(path: String) -> void:
	if busy:
		pending = path
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, 0.2)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(rect, "modulate:a", 0.0, 0.2)
	await tw2.finished
	busy = false
	if pending != "":
		var p := pending
		pending = ""
		go(p)
