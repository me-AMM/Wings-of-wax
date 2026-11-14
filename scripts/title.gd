# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Control
# Title screen: Start Game, Load Game, Judge Mode. The 320x180 art is shown at exactly 2x (Nearest); buttons are real
# 640x360 pixels on the sky, away from the habitat picture.
# Load Game is greyed out without a save; with one it shows "Day N - saved hh:mm" under the button.
# Start Game with an existing save asks first ("Start a new game? Your saved game will be replaced.").
# Leaving to the title ends judge mode: the next Start or Load is a clean game.

var start_btn: Button
var load_btn: Button
var judge_btn: Button
var summary_l: Label
var msg_l: Label

func _ready() -> void:
	GameState.clock_running = false
	GameState.judge_mode = false             # back on the title: judge mode is over
	GameState.time_scale = 1.0
	GameState.auto_endings = true
	var bg: TextureRect = $Background
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	start_btn = UIKit.button(Text.t("ui.title_start"), 160)
	start_btn.position = Vector2(24, 22)
	start_btn.pressed.connect(_on_start)
	add_child(start_btn)
	load_btn = UIKit.button(Text.t("ui.title_load"), 160)
	load_btn.position = Vector2(240, 22)
	load_btn.pressed.connect(_on_load)
	add_child(load_btn)
	judge_btn = UIKit.button(Text.t("ui.title_judge"), 160)
	judge_btn.position = Vector2(456, 22)
	judge_btn.pressed.connect(_on_judge)
	add_child(judge_btn)
	summary_l = UIKit.world_label("", 16, Color(0.8, 0.9, 1.0))
	summary_l.position = Vector2(200, 60)
	summary_l.size = Vector2(240, 20)
	summary_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(summary_l)
	var log_btn := UIKit.button(Text.t("ui.title_log"), 160)
	log_btn.position = Vector2(240, 84)
	log_btn.pressed.connect(func():
		Audio.play("ui_click")
		GameState.log_return = "res://scenes/Title.tscn"
		Scenes.go("res://scenes/SpaceWeatherLog.tscn"))
	add_child(log_btn)
	msg_l = UIKit.world_label("", 16, Color("FF8080"))
	msg_l.position = Vector2(120, 122)
	msg_l.size = Vector2(400, 40)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(msg_l)
	var gt := UIKit.world_label(Text.t("game_title"), 24, Color("FFD23F"))     # the game's name on the title screen
	gt.position = Vector2(0, 150)
	gt.size = Vector2(640, 32)
	gt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(gt)
	var ai := UIKit.world_label(Text.t("ui.ai_statement"), 8)      # AI statement (challenge rules)
	ai.position = Vector2(8, 334)
	ai.size = Vector2(624, 12)
	ai.modulate.a = 0.85
	add_child(ai)
	_refresh_load()
	start_btn.grab_focus()
	start_btn.focus_neighbor_right = load_btn.get_path()
	load_btn.focus_neighbor_left = start_btn.get_path()
	load_btn.focus_neighbor_right = judge_btn.get_path()
	judge_btn.focus_neighbor_left = load_btn.get_path()
	load_btn.focus_neighbor_bottom = log_btn.get_path()
	log_btn.focus_neighbor_top = load_btn.get_path()

# Load Game is greyed out without a (readable) save.
func _refresh_load() -> void:
	var s: Dictionary = Save.summary()
	load_btn.disabled = s.is_empty()
	load_btn.modulate = Color(0.55, 0.55, 0.6) if load_btn.disabled else Color.WHITE
	summary_l.text = "" if s.is_empty() else Text.t("ui.load_summary") % [s["day"], Save.saved_time_text(s["saved_at"])]

func _on_start() -> void:
	Audio.play("ui_click")
	if Save.exists() and not Save.summary().is_empty():
		var m := MenuModal.new()
		m.title_text = Text.t("ui.new_game_q")
		m.items = [
			{"icon": "icon_heart", "text": Text.t("ui.yes"), "sub": Text.t("ui.new_game_sub"), "call": _begin_new},
			{"icon": "icon_lock", "text": Text.t("ui.no")}]
		m.sel = 1
		m.menu_width = 280.0
		add_child(m)
		m.build()
	else:
		_begin_new()

func _begin_new() -> void:
	GameState.new_game()
	Scenes.go("res://scenes/CharacterSelect.tscn")

func _on_load() -> void:
	Audio.play("ui_click")
	if Save.load_game():
		Scenes.go("res://scenes/Outpost.tscn")
	else:
		msg_l.text = Text.t("ui.load_failed")        # damaged or missing file: a message, never a crash
		_refresh_load()

func _on_judge() -> void:
	Audio.play("ui_click")
	Judge.begin_judge_run()
	Judge.open_panel(true)

func _unhandled_input(e: InputEvent) -> void:
	if GameState.modal_count > 0:
		return                                   # a dialog is open: it owns the keyboard
	var f := get_viewport().gui_get_focus_owner()
	if e.is_action_pressed("interact") and f is Button:
		f.pressed.emit()
	elif e.is_action_pressed("move_down") and f != null and f.focus_neighbor_bottom != NodePath(""):
		f.get_node(f.focus_neighbor_bottom).grab_focus()
	elif e.is_action_pressed("move_up") and f != null and f.focus_neighbor_top != NodePath(""):
		f.get_node(f.focus_neighbor_top).grab_focus()
	elif e.is_action_pressed("move_right") or e.is_action_pressed("move_left"):
		if f == null:
			start_btn.grab_focus()
			return
		var next_f: Control = f.find_next_valid_focus() if e.is_action_pressed("move_right") else f.find_prev_valid_focus()
		if next_f:
			next_f.grab_focus()
