extends Control
# Story: 3 intro pages in one scene (story_1..3 art at 2x). E / Enter / click = next page; after page 3 the game starts.

var page := 0
var bg: TextureRect
var text_l: Label
var dots: Label

func _ready() -> void:
	GameState.clock_running = false
	bg = TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	add_child(bg)
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.05, 0.1, 0.78)
	panel.position = Vector2(20, 262)
	panel.size = Vector2(600, 84)
	add_child(panel)
	text_l = UIKit.world_label("", 16)
	text_l.position = Vector2(34, 270)
	text_l.size = Vector2(572, 56)
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(text_l)
	dots = UIKit.world_label("", 16, Color("FFD23F"))
	dots.position = Vector2(34, 322)
	dots.size = Vector2(572, 20)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(dots)
	_show()

func _show() -> void:
	bg.texture = Art.tex("story_%d" % (page + 1))
	text_l.text = Text.list("story")[page]
	dots.text = "%d/3   %s" % [page + 1, Text.t("ui.press_e_continue")]

func _next() -> void:
	page += 1
	Audio.play("ui_click")
	if page >= 3:
		get_tree().change_scene_to_file("res://scenes/Outpost.tscn")
	else:
		_show()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and e.keycode in [KEY_ENTER, KEY_SPACE]) \
			or (e is InputEventMouseButton and e.pressed):
		_next()
