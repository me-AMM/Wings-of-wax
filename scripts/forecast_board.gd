extends Control
# ForecastBoard: full screen in the lab. Free to read. At storm watch medium/high it names the next
# storm, its day, and the real flare it is modelled on (NASA DONKI). E or Esc goes back.

func _ready() -> void:
	GameState.clock_running = false
	var bg := TextureRect.new()
	bg.texture = Art.tex("forecast_screen")
	add_child(bg)
	var title := UIKit.label(Text.t("ui.board_title"), 12, Color("FFD23F"))
	title.position = Vector2(20, 14)
	add_child(title)
	var body := UIKit.label(_message(), 10)
	body.position = Vector2(20, 50)
	body.size = Vector2(280, 90)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(body)
	var real := UIKit.label(_real_line(), 8, Color(0.75, 0.85, 1.0))
	real.position = Vector2(20, 120)
	real.size = Vector2(280, 24)
	real.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(real)
	var back := UIKit.label(Text.t("ui.board_back"), 9)
	back.position = Vector2(250, 160)
	add_child(back)

# The next storm (day, entry) from today on, or {}.
func _next_storm() -> Dictionary:
	for d in range(GameState.day, 33):
		var st = GameState.days[d - 1]["storm"]
		if st != null and (d > GameState.day or st["in_mission"] or GameState.hour < st["at"]):
			return {"day": d, "storm": st}
	return {}

func _message() -> String:
	var special: String = GameState.today()["forecast"]
	if special != "" and GameState.sliders[3] > 0:
		return Text.t("forecast." + special)
	if GameState.sliders[3] == 0:
		return Text.t("forecast.fc_low_watch")
	var n := _next_storm()
	if n.is_empty():
		return Text.t("forecast.fc_none")
	return Text.t("forecast.fc_next") % [Text.t("storm_names." + n["storm"]["size"]), n["day"]]

func _real_line() -> String:
	if GameState.sliders[3] == 0:
		return ""
	var n := _next_storm()
	return "" if n.is_empty() else Config.storm_label(n["storm"]["event"])

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE):
		get_tree().change_scene_to_file("res://scenes/Outpost.tscn")
