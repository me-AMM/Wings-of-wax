extends Control
# Ending screen, used by EndingSuccess.tscn and EndingFailed.tscn (the scene name decides which).
# Success: "You achieved X% of the mission" and stars that pop in one by one (Judge runs earn no stars). Then Credits.

var success := true
var star_nodes: Array = []

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
	var body := UIKit.world_label("\n".join(lines), 16)
	body.position = Vector2(34, 176)
	body.size = Vector2(572, 92)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(body)
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
	var next := UIKit.button(Text.t("ui.credits") if success else Text.t("ui.play_again"), 140)
	next.position = Vector2(466, 310)
	next.pressed.connect(_next)
	add_child(next)
	next.grab_focus()
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
	get_tree().change_scene_to_file("res://scenes/Credits.tscn" if success else "res://scenes/Title.tscn")

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact"):
		_next()
