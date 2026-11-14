extends CanvasLayer
# HUD: icons first, numbers second (kids 7-12). Built in code from the pixel art.
# Top row: clock, sun/moon, health bar. Second row: meals, water, oxygen, packs, research.
# Bottom: notice line. Also: floating toasts, day splash, black fade.

@export var stat_spacing := 50.0
@export var notice_seconds := 4.0

var clock_label: Label
var sky_icon: TextureRect
var health_bar: HudBar
var stats: Array = []         # [{icon, label, get}]
var notice_panel: ColorRect
var notice_label: Label
var notice_queue: Array = []
var notice_timer := 0.0
var fade_rect: ColorRect
var splash: Label
var judge_label: Label

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
	# top strip background
	var strip := ColorRect.new()
	strip.color = Color(0.04, 0.05, 0.1, 0.55)
	strip.size = Vector2(320, 33)
	root.add_child(strip)
	var ci := UIKit.icon("icon_clock", 14)
	ci.position = Vector2(3, 2)
	root.add_child(ci)
	clock_label = UIKit.label("", 10)
	clock_label.position = Vector2(19, -2)
	root.add_child(clock_label)
	sky_icon = UIKit.icon("icon_sun", 14)
	sky_icon.position = Vector2(124, 2)
	root.add_child(sky_icon)
	var hi := UIKit.icon("icon_heart", 14)
	hi.position = Vector2(176, 2)
	root.add_child(hi)
	health_bar = HudBar.new().setup(120, Color("E5484D"))
	health_bar.position = Vector2(194, 1)
	root.add_child(health_bar)
	# stat row
	var defs := [
		["icon_ration", func(): return str(GameState.meals_left())],
		["icon_water", func(): return "%.1fL" % GameState.water],
		["icon_oxygen", func(): return "%dh" % int(round(GameState.oxygen_h))],
		["icon_pack", func(): return "%d%%" % int(round(GameState.base_pack))],
		["icon_pack", func(): return "+%d%%" % int(round(GameState.spare_pack))],
		["icon_research", func(): return "%d%%" % int(round(GameState.research))],
	]
	for i in defs.size():
		var x := 4.0 + i * stat_spacing
		var ic := UIKit.icon(defs[i][0], 14)
		ic.position = Vector2(x, 17)
		root.add_child(ic)
		var lb := UIKit.label("", 9)
		lb.position = Vector2(x + 15, 13)
		root.add_child(lb)
		stats.append({"icon": ic, "label": lb, "get": defs[i][1]})
	# notice line
	notice_panel = ColorRect.new()
	notice_panel.color = Color(0.04, 0.05, 0.1, 0.7)
	notice_panel.position = Vector2(0, 158)
	notice_panel.size = Vector2(320, 22)
	notice_panel.visible = false
	root.add_child(notice_panel)
	notice_label = UIKit.label("", 9, Color("FFD23F"))
	notice_label.position = Vector2(6, 4)
	notice_label.size = Vector2(308, 16)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_panel.add_child(notice_label)
	# judge mode label
	judge_label = UIKit.label(Text.t("ui.judge_label"), 9, Color("F06FA8"))
	judge_label.position = Vector2(120, 34)
	judge_label.visible = false
	root.add_child(judge_label)
	# day splash and fade (above everything)
	splash = UIKit.label("", 24, Color.WHITE)
	splash.position = Vector2(0, 70)
	splash.size = Vector2(320, 40)
	splash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash.modulate.a = 0.0
	root.add_child(splash)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = Vector2(320, 180)
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)

func refresh() -> void:
	clock_label.text = "%s %d   %s" % [Text.t("ui.day"), GameState.day, GameState.clock_text()]
	sky_icon.texture = Art.tex("icon_moon" if GameState.in_shadow else "icon_sun")
	health_bar.set_frac(GameState.health / 100.0)
	for s in stats:
		s["label"].text = s["get"].call()
	# warning colours
	var red := Color("FF8080")
	stats[1]["label"].modulate = red if GameState.water < Config.data["water"]["warn_below_l"] else Color.WHITE
	stats[2]["label"].modulate = red if GameState.oxygen_h < 12.0 else Color.WHITE
	var low: float = Config.data["power"]["low_pack_warn_pct"]
	stats[3]["icon"].texture = Art.tex("icon_pack_low" if GameState.base_pack < low else "icon_pack")
	stats[4]["icon"].texture = Art.tex("icon_pack_low" if GameState.spare_pack < low else "icon_pack")
	stats[3]["label"].modulate = red if GameState.base_pack < low else Color.WHITE
	judge_label.visible = GameState.judge_mode

func _process(delta: float) -> void:
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
	var l := UIKit.label(text, 10, color)
	l.position = Vector2(0, 100)
	l.size = Vector2(320, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", 80.0, 1.4)
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
