# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Control
# Space Weather Log: a table of the 8 storms with the REAL solar flare each one copies (NASA CCMC DONKI, the 2003
# flare from NOAA / ESA): game day, storm size, flare class, real date, flrID, source, and a tick for storms survived.
# Opened from the Title and from the forecast board (L). E or Esc goes back.

func _ready() -> void:
	GameState.clock_running = false
	var bg := TextureRect.new()
	bg.texture = Art.tex("credits_bg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.09, 0.82)
	dim.size = Vector2(640, 360)
	add_child(dim)
	var title := UIKit.world_label(Text.t("ui.weather_log"), 24, UIStyle.ACCENT)
	title.position = Vector2(16, 10)
	add_child(title)
	var line := UIKit.world_label(Text.t("ui.log_line"), 16, UIStyle.INFO)
	line.position = Vector2(16, 42)
	line.size = Vector2(608, 20)
	add_child(line)
	var cols: Array = Text.list("log_cols")
	var xs := [12, 44, 152, 196, 292, 528, 612]
	var y := 74.0
	for i in cols.size():
		_cell(cols[i], Vector2(xs[i], y), UIStyle.ACCENT)
	var sep := ColorRect.new()
	sep.color = Color(1, 0.82, 0.25, 0.5)
	sep.position = Vector2(16, y + 14)
	sep.size = Vector2(608, 1)
	add_child(sep)
	y += 22.0
	for d in range(1, 33):
		var st = GameState.days[d - 1]["storm"]
		if st == null:
			continue
		var e: Dictionary = Config.donki.get(st["event"], {})
		var survived: bool = st["event"] in GameState.storms_survived
		var row := [str(d), Text.t("storm_names." + st["size"]), e.get("classType", "?"), Config.nice_date(e.get("peakTime", "")),
			str(e.get("flrID", "")), "NOAA/ESA" if e.get("source", "") == "NOAA / ESA" else "NASA DONKI", "YES" if survived else "-"]
		var shade := ColorRect.new()
		shade.color = Color(1, 1, 1, 0.04 if int(y) % 44 < 22 else 0.0)
		shade.position = Vector2(12, y - 2)
		shade.size = Vector2(616, 22)
		add_child(shade)
		for i in row.size():
			_cell(row[i], Vector2(xs[i], y), UIStyle.GOOD if (i == 6 and survived) else Color.WHITE)
		y += 26.0
	var back := UIKit.world_label(Text.t("ui.back_hint"), 16)
	back.position = Vector2(16, 312)
	add_child(back)

func _cell(text: String, pos: Vector2, color: Color) -> void:
	var l := UIKit.world_label(text, 12, color)
	l.position = pos
	add_child(l)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE):
		Scenes.go(GameState.log_return if GameState.log_return != "" else "res://scenes/Title.tscn")
