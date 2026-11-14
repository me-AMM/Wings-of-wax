extends Control
# ForecastBoard: full screen in the lab (320x180 art at exactly 2x). Free to read. At storm watch medium/high it
# names the next storm, its day, and the real flare it is modelled on (NASA DONKI). E or Esc goes back.

func _ready() -> void:
	GameState.clock_running = false
	var bg := TextureRect.new()
	bg.texture = Art.tex("forecast_screen")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	add_child(bg)
	var title := UIKit.world_label(Text.t("ui.board_title"), 24, Color("FFD23F"))
	title.position = Vector2(48, 44)
	add_child(title)
	var body := UIKit.world_label(_message(), 24)
	body.position = Vector2(48, 96)
	body.size = Vector2(540, 100)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(body)
	var real := UIKit.world_label(_real_line(), 16, Color(0.75, 0.85, 1.0))
	real.position = Vector2(48, 200)
	real.size = Vector2(540, 48)
	real.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(real)
	var back := UIKit.world_label(Text.t("ui.board_back"), 16)
	back.position = Vector2(440, 266)      # inside the board frame (the border is the outer 30 px)
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
		Scenes.go("res://scenes/Outpost.tscn")
