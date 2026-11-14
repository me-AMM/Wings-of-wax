# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Control
# Ending screen, used by EndingSuccess.tscn and EndingFailed.tscn (the scene name decides which).
# Success: "You achieved X% of the mission" and stars that pop in one by one (Judge runs earn no stars). Then Credits.

var success := true
var star_nodes: Array = []
var retry_btn: Button

func _ready() -> void:
	GameState.clock_running = false
	success = name == "EndingSuccess"
	var bg := TextureRect.new()
	bg.texture = Art.tex("ending_success" if success else "ending_failed")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	add_child(bg)
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.05, 0.1, 0.78)
	panel.position = Vector2(20, 168)
	panel.size = Vector2(600, 184)
	add_child(panel)
	var lines: Array = Text.list("ending_success" if success else "ending_failed")
	if not success and Text.list("ending_failed_" + GameState.fail_reason).size() > 0:
		lines = Text.list("ending_failed_" + GameState.fail_reason)
	var body := UIKit.world_label("\n".join(lines), 16)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 8)   # 4 lines of story text must fit above the percent line
	add_child(body)
	body.position = Vector2(34, 180)
	body.size = Vector2(560, 84)          # set after add_child so the wrap width sticks
	if success:
		var pct := UIKit.world_label(Text.t("ui.ending_percent") % int(round(GameState.research)), 24, Color("FFD23F"))
		pct.position = Vector2(34, 272)
		pct.size = Vector2(572, 30)
		add_child(pct)
		if GameState.judge_mode:
			var nj := UIKit.world_label(Text.t("ui.judge_no_stars"), 16, Color("F06FA8"))
			nj.position = Vector2(34, 316)
			add_child(nj)
		else:
			_stars()
	if success:
		var next := UIKit.button(Text.t("ui.credits"), 140)
		next.position = Vector2(466, 310)
		next.pressed.connect(_next)
		add_child(next)
		next.grab_focus()
	else:
		# failed: two main buttons (Retry day N / Start new game) and a small Title button
		retry_btn = UIKit.button(Text.t("ui.retry_day") % GameState.fail_day, 190)
		retry_btn.position = Vector2(34, 304)
		retry_btn.pressed.connect(_retry)
		add_child(retry_btn)
		var newb := UIKit.button(Text.t("ui.new_game_btn"), 190)
		newb.position = Vector2(244, 304)
		newb.pressed.connect(_new_game)
		add_child(newb)
		var tb := UIKit.button(Text.t("ui.title_btn"), 96)
		tb.position = Vector2(520, 304)
		tb.pressed.connect(_to_title)
		add_child(tb)
		retry_btn.focus_neighbor_right = newb.get_path()
		newb.focus_neighbor_left = retry_btn.get_path()
		newb.focus_neighbor_right = tb.get_path()
		tb.focus_neighbor_left = newb.get_path()
		retry_btn.grab_focus()
	_learned()
	Audio.play("success" if success else "fail")

func _stars() -> void:
	var n := GameState.stars()
	for i in 5:
		var s := TextureRect.new()
		s.texture = Art.tex("icon_star_empty")
		s.position = Vector2(34 + i * 38, 312)
		s.size = Vector2(32, 32)
		add_child(s)
		star_nodes.append(s)
	for i in n:
		await get_tree().create_timer(0.5).timeout
		star_nodes[i].texture = Art.tex("icon_star_full")
		Audio.play("star")

func _next() -> void:
	Audio.play("ui_click")
	Scenes.go("res://scenes/Credits.tscn")

# Retry day N: the 06:00 state of that day (everything done since is undone). The save file is never touched.
func _retry() -> void:
	Audio.play("ui_click")
	GameState.retry_day()
	Scenes.go("res://scenes/Outpost.tscn")

# Start new game: fresh state, character select. The save is only replaced by the next autosave.
func _new_game() -> void:
	Audio.play("ui_click")
	GameState.new_game()
	Scenes.go("res://scenes/CharacterSelect.tscn")

func _to_title() -> void:
	Audio.play("ui_click")
	Scenes.go("res://scenes/Title.tscn")

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact"):
		var f := get_viewport().gui_get_focus_owner()
		if f is Button:
			f.pressed.emit()
		elif success:
			_next()
		else:
			_retry()

# "What you learned": up to 3 facts the player met (NASA-data cards first), each with its source.
func _learned() -> void:
	var prefer := ["solar_storms", "gannon", "osdr_gym", "radlab_storm", "csa_radish", "busy_sun", "why_forecasts_work", "dust", "solar", "breathing"]
	var picks: Array = []
	for k in prefer:
		if k in GameState.cards_seen and picks.size() < 3:
			picks.append(k)
	for k in GameState.cards_seen:
		if picks.size() < 3 and not (k in picks):
			picks.append(k)
	if picks.is_empty():
		return
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.05, 0.1, 0.8)
	panel.position = Vector2(20, 12)
	panel.size = Vector2(600, 24 + 32 * picks.size())
	add_child(panel)
	var head := UIKit.world_label(Text.t("ui.learned"), 16, Color("FFD23F"))
	head.position = Vector2(30, 14)
	add_child(head)
	for i in picks.size():
		var c: Dictionary = Text.card(picks[i])
		var t := UIKit.world_label("- " + c["title"], 16)
		t.position = Vector2(30, 34 + 32 * i)
		add_child(t)
		var s := UIKit.world_label(c["source"], 8, Color(0.75, 0.85, 1.0))
		s.position = Vector2(46, 52 + 32 * i)
		add_child(s)
