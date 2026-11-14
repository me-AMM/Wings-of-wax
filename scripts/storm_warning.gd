# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends CanvasLayer
# StormWarning overlay (real 640x360 pixels): ONE small panel in the top-right corner, under the HUD strip and the
# sun/moon icons (about 30% of the screen width, under 28% of its height, 8 px margin).
#   line 1: red storm icon + "STORM IN 2:33" (largest text)   line 2: storm size ("Huge storm")
#   line 3: short real-event label ("X28, 4 NOV 2003")         line 4 (only while you are outside): "Get to shelter!"
# The full "Similar to a real event: ..." text shows for the first 5 s in a small dark panel under it.
# Red screen tint (at most 12% alpha) and a few light storm_specks. The panel blinks red in the last 10 s.
# After the storm: "Storm over" for 2 s, then the panel hides. Add it to any scene (Outpost, Mission).

@export var tint_color := Color(0.9, 0.1, 0.1)
@export var specks := 12
@export var full_text_seconds := 5.0
@export var panel_pos := Vector2(440, 78)      # 640 - 192 - 8 = 440; y is under the strip (36) and the icon row (38-70)
@export var panel_size := Vector2(192, 98)

var root: Control
var warn_nodes: Array = []       # tint and specks
var panel: Control
var count_label: Label
var size_label: Label
var src_label: Label
var real_label: Label
var shelter_label: Label
var full_panel: ColorRect
var full_label: Label
var tint: ColorRect
var speck_nodes: Array = []
var shown := false
var age := 0.0
var over_t := 0.0

func _ready() -> void:
	layer = 12
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	tint = ColorRect.new()
	tint.color = tint_color
	tint.size = Vector2(640, 360)
	root.add_child(tint)
	warn_nodes.append(tint)
	for i in specks:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Art.frames("storm_specks")
		s.position = Vector2(randf() * 640.0, randf() * 360.0)
		s.speed_scale = randf_range(0.7, 1.3)
		s.modulate.a = 0.6
		s.play("default")
		root.add_child(s)
		speck_nodes.append(s)
		warn_nodes.append(s)
	# the corner panel: dark translucent with the storm_frame art as its top strip
	panel = Control.new()
	panel.position = panel_pos
	root.add_child(panel)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.02, 0.04, 0.82)
	bg.size = panel_size
	panel.add_child(bg)
	var frame := NinePatchRect.new()
	frame.texture = Art.tex("storm_frame")
	frame.patch_margin_left = 9
	frame.patch_margin_right = 9
	frame.size = Vector2(panel_size.x, 32)
	panel.add_child(frame)
	var ic := UIKit.icon("icon_storm", 32)
	ic.position = Vector2(4, 0)
	panel.add_child(ic)
	count_label = UIKit.world_label("", 16)
	count_label.position = Vector2(38, 6)
	count_label.size = Vector2(150, 20)
	panel.add_child(count_label)
	src_label = UIKit.world_label("", 12, UIStyle.INFO)     # the data source, always visible
	src_label.position = Vector2(38, 22)                     # small line under the countdown, inside the frame strip
	src_label.size = Vector2(150, 10)
	panel.add_child(src_label)
	size_label = UIKit.world_label("", 16, UIStyle.ACCENT)
	size_label.position = Vector2(4, 36)
	size_label.size = Vector2(184, 20)
	panel.add_child(size_label)
	real_label = UIKit.world_label("", 16, Color(1, 0.92, 0.92))
	real_label.position = Vector2(4, 56)
	real_label.size = Vector2(184, 20)
	panel.add_child(real_label)
	shelter_label = UIKit.world_label("", 16, UIStyle.DANGER)
	shelter_label.position = Vector2(4, 76)
	shelter_label.size = Vector2(184, 20)
	panel.add_child(shelter_label)
	# the full real-event text, first 5 s only (2 lines max, small dark translucent panel under the corner panel)
	full_panel = ColorRect.new()
	full_panel.color = Color(0.04, 0.05, 0.1, 0.78)
	full_panel.position = Vector2(172, panel_pos.y + panel_size.y + 6)
	full_panel.size = Vector2(460, 48)
	root.add_child(full_panel)
	full_label = UIKit.world_label("", 16, Color(1, 0.92, 0.92))
	full_label.position = Vector2(6, 4)
	full_label.size = Vector2(448, 40)
	full_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	full_panel.add_child(full_label)
	UIKit.ignore_mouse(root)
	GameState.event.connect(_on_event)
	_set_shown(false)
	if GameState.storm_state == "warning":      # scene changed while a storm was coming
		_begin(false)

func _set_shown(v: bool) -> void:
	shown = v
	panel.visible = v
	full_panel.visible = v
	for n in warn_nodes:
		n.visible = v

func _begin(play_sound := true) -> void:
	age = 0.0 if play_sound else full_text_seconds      # no full text again after a scene change
	over_t = 0.0
	_set_shown(true)
	panel.modulate = Color.WHITE
	size_label.text = Text.t("storm_names." + GameState.storm_size)
	real_label.text = Config.storm_short(GameState.storm_event)
	src_label.text = Text.t("ui.source_noaa") if Config.donki.get(GameState.storm_event, {}).get("source", "") == "NOAA / ESA" else Text.t("ui.source_donki")
	full_label.text = Config.storm_label(GameState.storm_event)
	if play_sound:
		Audio.play("storm_warning")              # loops during the countdown

func _on_event(ev_name: String, _data: Dictionary) -> void:
	if ev_name == "storm_warning":
		_begin()
	elif ev_name == "storm_hit":
		Audio.play("storm_hit")
		# "Storm over" for 2 s, then the panel hides
		shown = false
		for n in warn_nodes:
			n.visible = false
		full_panel.visible = false
		panel.visible = true
		panel.modulate = Color.WHITE
		count_label.text = Text.t("ui.storm_over")
		size_label.text = ""
		real_label.text = ""
		src_label.text = ""
		shelter_label.text = ""
		over_t = 2.0

func _process(delta: float) -> void:
	if over_t > 0.0:
		over_t -= delta
		if over_t <= 0.0:
			panel.visible = false
	if not shown:
		return
	age += delta
	var left_s: float = maxf(0.0, GameState.storm_left_h * Config.data["time"]["real_seconds_per_game_hour"])
	count_label.text = "%s %d:%02d" % [Text.t("ui.storm_in"), int(left_s) / 60, int(left_s) % 60]
	shelter_label.text = "" if GameState.in_shelter else Text.t("ui.get_to_shelter")
	full_panel.visible = age < full_text_seconds
	# last 10 s: the panel turns red and blinks
	if left_s <= 10.0:
		panel.modulate = Color(1.0, 0.35, 0.35) if int(Time.get_ticks_msec() / 250) % 2 == 0 else Color.WHITE
	else:
		panel.modulate = Color.WHITE
	tint.color.a = 0.06 + 0.06 * sin(Time.get_ticks_msec() / 250.0)      # never above 12%
	for s in speck_nodes:
		s.position.y += 70.0 * delta
		s.position.x -= 24.0 * delta
		if s.position.y > 380.0 or s.position.x < -20.0:
			s.position = Vector2(randf() * 680.0, -20.0)
