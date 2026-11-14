extends CanvasLayer
# StormWarning overlay (real 640x360 pixels): storm_frame banner with a LARGE countdown, the REAL-EVENT line
# (from DONKI data, wrapped to 2 lines), red screen tint and flying particles while the warning runs.
# Add it to any scene (Outpost, Mission).

@export var tint_color := Color(0.9, 0.1, 0.1)
@export var specks := 10

var root: Control
var warn_nodes: Array = []       # everything shown only while a warning runs
var tint: ColorRect
var count_label: Label
var title_label: Label
var real_label: Label
var result_label: Label
var speck_nodes: Array = []
var shown := false
var result_t := 0.0

func _ready() -> void:
	layer = 12
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	tint = ColorRect.new()
	tint.color = tint_color
	tint.size = Vector2(640, 360)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tint)
	warn_nodes.append(tint)
	for i in specks:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Art.frames("storm_specks")
		s.position = Vector2(randf() * 640.0, randf() * 360.0)
		s.speed_scale = randf_range(0.7, 1.3)
		s.play("default")
		root.add_child(s)
		speck_nodes.append(s)
		warn_nodes.append(s)
	var frame := NinePatchRect.new()
	frame.texture = Art.tex("storm_frame")
	frame.patch_margin_left = 9
	frame.patch_margin_right = 9
	frame.position = Vector2(100, 44)
	frame.size = Vector2(440, 32)
	root.add_child(frame)
	warn_nodes.append(frame)
	var ic := UIKit.icon("icon_storm", 32)
	ic.position = Vector2(108, 44)
	root.add_child(ic)
	warn_nodes.append(ic)
	count_label = UIKit.world_label("", 24)         # large countdown
	count_label.position = Vector2(150, 44)
	count_label.size = Vector2(380, 32)
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(count_label)
	warn_nodes.append(count_label)
	title_label = UIKit.world_label("", 16, Color("FFD23F"))
	title_label.position = Vector2(100, 80)
	title_label.size = Vector2(440, 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title_label)
	warn_nodes.append(title_label)
	real_label = UIKit.world_label("", 16, Color(1, 0.92, 0.92))       # the real-event line, 2 lines max
	real_label.position = Vector2(100, 100)
	real_label.size = Vector2(440, 44)
	real_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	real_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(real_label)
	warn_nodes.append(real_label)
	result_label = UIKit.world_label("", 24)
	result_label.position = Vector2(60, 200)
	result_label.size = Vector2(520, 80)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(result_label)
	GameState.event.connect(_on_event)
	_set_shown(false)
	if GameState.storm_state == "warning":      # scene changed while a storm was coming
		_begin()

func _set_shown(v: bool) -> void:
	shown = v
	for n in warn_nodes:
		n.visible = v

func _begin() -> void:
	_set_shown(true)
	title_label.text = "%s  -  %s" % [Text.t("ui.storm_incoming"), Text.t("storm_names." + GameState.storm_size)]
	real_label.text = Config.storm_label(GameState.storm_event)
	Audio.play("storm_warning")

func _on_event(ev_name: String, data: Dictionary) -> void:
	if ev_name == "storm_warning":
		_begin()
	elif ev_name == "storm_hit":
		_set_shown(false)
		Audio.play("storm_hit")
		if data["failed"]:
			result_label.text = Text.t("ui.storm_failed")
		elif data["sheltered"]:
			result_label.text = Text.t("ui.storm_sheltered")
		elif data["damage_pct"] > 0.0:
			result_label.text = Text.t("ui.storm_hurt") % int(data["damage_pct"])
		else:
			result_label.text = Text.t("ui.storm_clear")
		result_t = 4.0

func _process(delta: float) -> void:
	if result_t > 0.0:
		result_t -= delta
		if result_t <= 0.0:
			result_label.text = ""
	if shown:
		var left_s: float = maxf(0.0, GameState.storm_left_h * Config.data["time"]["real_seconds_per_game_hour"])
		count_label.text = "%s %d:%02d" % [Text.t("ui.storm_countdown"), int(left_s) / 60, int(left_s) % 60]
		tint.color.a = 0.07 + 0.07 * sin(Time.get_ticks_msec() / 250.0)
		for s in speck_nodes:
			s.position.y += 80.0 * delta
			s.position.x -= 28.0 * delta
			if s.position.y > 380.0 or s.position.x < -20.0:
				s.position = Vector2(randf() * 680.0, -20.0)
