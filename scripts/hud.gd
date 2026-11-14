extends CanvasLayer
# HUD, drawn in real 640x360 pixels. ONE slim top strip, icon + value pairs in evenly spaced fixed-width cells
# (so digits never jitter): day/time, rations, water, oxygen hours, base pack %, spare pack %, research %,
# then the Health bar with the heart. Low values turn red; a pack icon blinks (icon_pack_low) under 10%.
# Also: notice line at the bottom, floating toasts, day splash, black fade, blinking storm icon.

@export var strip_height := 36.0
@export var first_cell := 140.0      # clock cell ("DAY 32 06:00" in Silkscreen 16)
@export var cell_widths: Array[float] = [58.0, 76.0, 70.0, 70.0, 70.0, 84.0]   # icon 32 + value, fixed so digits never jitter
@export var notice_seconds := 4.0

var sky_icon: TextureRect
var clock_label: Label
var health_bar: HudBar
var stats: Array = []         # [{icon, label, get}]
var notice_panel: ColorRect
var notice_label: Label
var notice_queue: Array = []
var notice_timer := 0.0
var fade_rect: ColorRect
var splash: Label
var judge_label: Label
var storm_icon: TextureRect
var blackout_icon: TextureRect

func _ready() -> void:
	layer = 10
	_build()
	GameState.changed.connect(refresh)
	GameState.notice.connect(push_notice)
	refresh()

func _build() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var strip := ColorRect.new()
	strip.color = Color(0.04, 0.05, 0.1, 0.65)
	strip.size = Vector2(640, strip_height)
	root.add_child(strip)
	# cell 0: "Day N hh:mm" (the sun/moon icon sits under the strip, next to the storm icon)
	clock_label = _text(Vector2(4, 8), 16, root)
	clock_label.custom_minimum_size = Vector2(first_cell - 6.0, 20)
	sky_icon = _icon("icon_sun", Vector2(604, strip_height + 2), root)
	# stat cells (icon 32 + value in a fixed-width cell)
	var defs := [
		["icon_ration", func(): return str(GameState.meals_left())],
		["icon_water", func(): return "%.1f" % GameState.water],
		["icon_oxygen", func(): return "%dh" % int(round(GameState.oxygen_h))],
		["icon_pack", func(): return "%d" % int(round(GameState.base_pack))],
		["icon_pack", func(): return "%d" % int(round(GameState.spare_pack))],
		["icon_research", func(): return "%d%%" % int(round(GameState.research))],
	]
	var x := first_cell
	for i in defs.size():
		var ic := _icon(defs[i][0], Vector2(x, 2), root)
		var lb := _text(Vector2(x + 34, 8), 16, root)
		lb.custom_minimum_size = Vector2(cell_widths[i] - 34.0, 20)
		if i == 4:
			lb.add_theme_color_override("font_color", Color("9BE8FF"))    # spare pack on the charger
		stats.append({"icon": ic, "label": lb, "get": defs[i][1]})
		x += cell_widths[i]
	# health: heart + red bar (bar_frame + fill)
	var hx := x
	_icon("icon_heart", Vector2(hx, 2), root)
	health_bar = HudBar.new().setup(640.0 - hx - 38.0, Color("E5484D"))
	health_bar.position = Vector2(hx + 34, 10)
	root.add_child(health_bar)
	# blinking storm icon under the strip
	storm_icon = _icon("icon_storm", Vector2(568, strip_height + 2), root)
	storm_icon.visible = false
	blackout_icon = _icon("icon_blackout", Vector2(532, strip_height + 2), root)
	blackout_icon.visible = false
	judge_label = _text(Vector2(4, strip_height + 4), 16, root, Color("F06FA8"))
	judge_label.text = Text.t("ui.judge_label")
	judge_label.visible = false
	# notice line
	notice_panel = ColorRect.new()
	notice_panel.color = Color(0.04, 0.05, 0.1, 0.75)
	notice_panel.position = Vector2(0, 322)
	notice_panel.size = Vector2(640, 38)
	notice_panel.visible = false
	root.add_child(notice_panel)
	notice_label = UIKit.world_label("", 16, Color("FFD23F"))
	notice_label.position = Vector2(12, 4)
	notice_label.size = Vector2(616, 32)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_panel.add_child(notice_label)
	# day splash and fade (above everything)
	splash = UIKit.world_label("", 48)
	splash.position = Vector2(0, 130)
	splash.size = Vector2(640, 60)
	splash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash.modulate.a = 0.0
	root.add_child(splash)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = Vector2(640, 360)
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)

func _icon(icon_name: String, pos: Vector2, parent: Control) -> TextureRect:
	var ic := UIKit.icon(icon_name, 32)       # 32x32 derived icon, shown 1:1
	ic.position = pos
	parent.add_child(ic)
	return ic

func _text(pos: Vector2, px: int, parent: Control, color: Color = Color.WHITE) -> Label:
	var l := UIKit.world_label("", px, color)
	l.position = pos
	parent.add_child(l)
	return l

func refresh() -> void:
	clock_label.text = "%s %d %s" % [Text.t("ui.day"), GameState.day, GameState.clock_text()]
	sky_icon.texture = Art.tex("icon_moon" if GameState.in_shadow else "icon_sun")
	health_bar.set_frac(GameState.health / 100.0)
	for s in stats:
		s["label"].text = s["get"].call()
	var red := Color("FF8080")
	stats[1]["label"].modulate = red if GameState.water < Config.data["water"]["warn_below_l"] else Color.WHITE
	stats[2]["label"].modulate = red if GameState.oxygen_h < 12.0 else Color.WHITE
	var low: float = Config.data["power"]["low_pack_warn_pct"]
	stats[3]["label"].modulate = red if GameState.base_pack < low else Color.WHITE
	stats[4]["label"].modulate = red if GameState.spare_pack < low else Color.WHITE
	judge_label.visible = GameState.judge_mode

func _process(delta: float) -> void:
	var blink := int(Time.get_ticks_msec() / 300) % 2 == 0
	var low: float = Config.data["power"]["low_pack_warn_pct"]
	stats[3]["icon"].texture = Art.tex("icon_pack_low" if (GameState.base_pack < low and blink) else "icon_pack")
	stats[4]["icon"].texture = Art.tex("icon_pack_low" if (GameState.spare_pack < low and blink) else "icon_pack")
	blackout_icon.visible = GameState.blackout and blink
	storm_icon.visible = GameState.storm_state == "warning"
	storm_icon.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0)
	if notice_timer > 0.0:
		notice_timer -= delta
		if notice_timer <= 0.0:
			notice_panel.visible = false
	if notice_timer <= 0.0 and notice_queue.size() > 0:
		notice_label.text = notice_queue.pop_front()
		notice_panel.visible = true
		notice_timer = notice_seconds

# key = text key in data/text.json "notices"
func push_notice(key: String) -> void:
	var txt := Text.t("notices." + key)
	if not notice_queue.has(txt):
		notice_queue.append(txt)

func say(text: String) -> void:
	notice_queue.append(text)

# Floating text in the middle of the screen (feedback for actions).
func toast(text: String, color: Color = Color.WHITE) -> void:
	var l := UIKit.world_label(text, 16, color)
	l.position = Vector2(0, 200)
	l.size = Vector2(640, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", 160.0, 1.4)
	tw.tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)

func show_day_splash() -> void:
	splash.text = "%s %d" % [Text.t("ui.day"), GameState.day]
	var tw := create_tween()
	tw.tween_property(splash, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.2)
	tw.tween_property(splash, "modulate:a", 0.0, 0.6)

func fade_to_black(seconds: float = 0.6) -> Signal:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, seconds)
	return tw.finished

func fade_from_black(seconds: float = 0.6) -> Signal:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, seconds)
	return tw.finished
