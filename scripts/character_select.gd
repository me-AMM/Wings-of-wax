extends Control
# CharacterSelect: pick astronaut A (blue) or B (pink) and type a name. 320x180 art shown at 2x, UI in real pixels.
# Left/Right (or A/D, or click) choose the astronaut, Down goes to the name field, Enter confirms.

var pick := "a"
var buttons := {}
var name_edit: LineEdit

func _ready() -> void:
	GameState.clock_running = false
	var bg := TextureRect.new()
	bg.texture = Art.tex("select_bg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	add_child(bg)
	var title := UIKit.world_label(Text.t("ui.select_title"), 24, Color("FFD23F"))
	title.position = Vector2(0, 20)
	title.size = Vector2(640, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	for i in 2:
		var key := "a" if i == 0 else "b"
		var b := Button.new()
		b.icon = Art.tex("portrait_" + key)
		b.flat = false
		b.toggle_mode = true
		b.position = Vector2(150 + i * 232, 70)
		b.custom_minimum_size = Vector2(140, 150)
		b.size = Vector2(140, 150)
		b.focus_mode = Control.FOCUS_ALL
		b.text = ""
		b.pressed.connect(func(): _choose(key))
		add_child(b)
		buttons[key] = b
		var cap := UIKit.world_label(Text.t("ui.astronaut_" + key), 16)
		cap.position = Vector2(150 + i * 232, 224)
		cap.size = Vector2(140, 20)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(cap)
	var hint := UIKit.world_label(Text.t("ui.name_hint"), 16)
	hint.position = Vector2(0, 252)
	hint.size = Vector2(640, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	name_edit = LineEdit.new()
	name_edit.text = Text.t("ui.default_name")
	name_edit.max_length = 12
	name_edit.position = Vector2(240, 276)
	name_edit.size = Vector2(160, 28)
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.add_theme_font_size_override("font_size", 16)
	name_edit.text_submitted.connect(func(_t): _go())
	add_child(name_edit)
	var go := UIKit.button(Text.t("ui.continue"), 140)
	go.position = Vector2(250, 316)
	go.pressed.connect(_go)
	add_child(go)
	buttons["a"].focus_neighbor_right = buttons["b"].get_path()
	buttons["b"].focus_neighbor_left = buttons["a"].get_path()
	for k in buttons:
		buttons[k].focus_neighbor_bottom = name_edit.get_path()
	name_edit.focus_neighbor_top = buttons["a"].get_path()
	name_edit.focus_neighbor_bottom = go.get_path()
	go.focus_neighbor_top = name_edit.get_path()
	_choose("a")
	buttons["a"].grab_focus()

func _choose(key: String) -> void:
	pick = key
	for k in buttons:
		buttons[k].button_pressed = (k == key)
	Audio.play("ui_click")

func _go() -> void:
	GameState.astronaut = pick
	GameState.player_name = name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else Text.t("ui.default_name")
	Audio.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/Story.tscn")

func _unhandled_input(e: InputEvent) -> void:
	var f := get_viewport().gui_get_focus_owner()
	if f is LineEdit:
		return
	if e.is_action_pressed("move_left") and f != null and f.focus_neighbor_left != NodePath(""):
		buttons["a"].grab_focus()
		_choose("a")
	elif e.is_action_pressed("move_right") and (f == buttons["a"] or f == buttons["b"]):
		buttons["b"].grab_focus()
		_choose("b")
	elif e.is_action_pressed("interact") and f is Button:
		f.pressed.emit()
