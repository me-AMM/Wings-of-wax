extends CanvasLayer
# StormWarning overlay: countdown in the storm_frame, the REAL-EVENT label (from DONKI data),
# red screen tint and flying particles while the warning runs. Add it to any scene (Outpost, Mission).

@export var tint_color := Color(0.9, 0.1, 0.1)
@export var specks := 10

var root: Control
var frame: NinePatchRect
var count_label: Label
var title_label: Label
var real_label: Label
var tint: ColorRect
var result_label: Label
var speck_nodes: Array = []
var shown := false
var result_t := 0.0

func _ready() -> void:
	layer = 12
	scale = Vector2(2, 2)
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	tint = ColorRect.new()
	tint.color = tint_color
	tint.size = Vector2(320, 180)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tint)
	for i in specks:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Art.frames("storm_specks")
		s.position = Vector2(randf() * 320.0, randf() * 180.0)
		s.speed_scale = randf_range(0.7, 1.3)
		s.play("default")
		root.add_child(s)
		speck_nodes.append(s)
	frame = NinePatchRect.new()
	frame.texture = Art.tex("storm_frame")
	frame.patch_margin_left = 9
	frame.patch_margin_right = 9
	frame.position = Vector2(40, 34)
	frame.size = Vector2(240, 32)
	root.add_child(frame)
	var ic := UIKit.icon("icon_storm", 20)
	ic.position = Vector2(52, 40)
	root.add_child(ic)
	title_label = UIKit.label("", 9, Color("FFD23F"))
	title_label.position = Vector2(76, 36)
	root.add_child(title_label)
	count_label = UIKit.label("", 11)
	count_label.position = Vector2(76, 47)
	root.add_child(count_label)
	real_label = UIKit.label("", 8, Color(1, 0.9, 0.9))
	real_label.position = Vector2(0, 68)
	UIKit.box(real_label, 320, 12)
	real_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(real_label)
	result_label = UIKit.label("", 11, Color.WHITE)
	result_label.position = Vector2(0, 100)
	UIKit.box(result_label, 320, 40)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(result_label)
	GameState.event.connect(_on_event)
	_set_visible(false)
	if GameState.storm_state == "warning":      # scene changed while a storm was coming
		_begin()

func _set_visible(v: bool) -> void:
	shown = v
	tint.visible = v
	frame.visible = v
	for c in root.get_children():
		if c != result_label and c != tint:
			c.visible = v if not (c is Label and c == real_label and not v) else false
	for s in speck_nodes:
		s.visible = v

func _begin() -> void:
	_set_visible(true)
	title_label.text = "%s  -  %s" % [Text.t("ui.storm_incoming"), Text.t("storm_names." + GameState.storm_size)]
	real_label.text = Config.storm_label(GameState.storm_event)
	Audio.play("storm_warning")

func _on_event(ev_name: String, data: Dictionary) -> void:
	if ev_name == "storm_warning":
		_begin()
	elif ev_name == "storm_hit":
		_set_visible(false)
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
		count_label.text = "%s  %d:%02d" % [Text.t("ui.storm_countdown"), int(left_s) / 60, int(left_s) % 60]
		tint.color.a = 0.07 + 0.07 * sin(Time.get_ticks_msec() / 250.0)
		for s in speck_nodes:
			s.position.y += 40.0 * delta
			s.position.x -= 14.0 * delta
			if s.position.y > 190.0 or s.position.x < -10.0:
				s.position = Vector2(randf() * 340.0, -10.0)
