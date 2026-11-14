extends Control
# Credits: credits_bg at 2x with the lines from data/text.json ("credits") scrolling up. E / Esc goes to the Title.

@export var scroll_speed := 22.0
var box: Control

func _ready() -> void:
	GameState.clock_running = false
	var bg := TextureRect.new()
	bg.texture = Art.tex("credits_bg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.1, 0.55)
	dim.size = Vector2(640, 360)
	add_child(dim)
	box = Control.new()
	box.position = Vector2(60, 340)
	add_child(box)
	var y := 0.0
	var head := UIKit.world_label(Text.t("game_title"), 24, Color("FFD23F"))
	head.position = Vector2(0, y)
	box.add_child(head)
	y += 44.0
	for line in Text.list("credits"):
		var l := UIKit.world_label(line, 16)
		l.position = Vector2(0, y)
		l.size = Vector2(520, 40)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
		y += 20.0 * ceil(l.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x / 520.0) + 14.0
	var th := UIKit.world_label(Text.t("ui.thanks"), 24, Color("9BE8FF"))
	th.position = Vector2(0, y + 10)
	box.add_child(th)

func _process(delta: float) -> void:
	box.position.y -= scroll_speed * delta * (4.0 if Input.is_action_pressed("move_down") else 1.0)
	if box.position.y < -box.get_child_count() * 60.0:
		box.position.y = 340.0

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE):
		Scenes.go("res://scenes/Title.tscn")
