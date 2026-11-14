# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends CanvasLayer
# HUD, drawn in real 640x360 pixels. ONE slim top strip, icon + value pairs in evenly spaced fixed-width cells
# (so digits never jitter): day/time, rations, water, oxygen hours, base pack %, spare pack %, research %,
# then the Health bar with the heart. Low values turn red; a pack icon blinks (icon_pack_low) under 10%.
# Also: notice line at the bottom, floating toasts, day splash, black fade, blinking storm icon.

@export var strip_height := 36.0
@export var first_cell := 138.0      # clock cell ("DAY 32 06:00" in Silkscreen 16)
@export var cell_widths: Array[float] = [56.0, 74.0, 68.0, 66.0, 66.0, 80.0]   # icon 32 + value, fixed so digits never jitter
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
var fact_btn: Button
var day_card: ColorRect
var day_info: Label
var health_num: Label
var heart_icon: TextureRect
var flash: ColorRect
var banner_panel: ColorRect
var banner_label: Label
var shown_health := 100.0
var hurt_acc := 0.0
var hurt_timer := 0.0
var hurt_reason := ""
var blackout_icon: TextureRect

func _ready() -> void:
	layer = 10
	_build()
	GameState.changed.connect(refresh)
	GameState.notice.connect(push_notice)
	GameState.event.connect(_on_game_event)
	shown_health = GameState.health
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
		var lb := _text(Vector2(x + 32, 8), 16, root)
		lb.custom_minimum_size = Vector2(cell_widths[i] - 32.0, 20)
		if i == 4:
			lb.add_theme_color_override("font_color", UIStyle.INFO)    # spare pack on the charger
		stats.append({"icon": ic, "label": lb, "get": defs[i][1]})
		x += cell_widths[i]
	# health: heart, the number BESIDE it, a thin red bar under the number, then the Facts "?" button.
	# Everything ends SAFE px from the right edge.
	var hx := x
	heart_icon = _icon("icon_heart", Vector2(hx, 2), root)
	var num_w := 36.0
	health_num = UIKit.world_label("100", 16)
	health_num.position = Vector2(hx + 32, 6)
	health_num.size = Vector2(num_w, 20)
	health_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_num.add_theme_constant_override("outline_size", 4)
	health_num.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	root.add_child(health_num)
	health_bar = HudBar.new().setup(num_w, UIStyle.DANGER)
	health_bar.position = Vector2(hx + 32, 26)
	health_bar.scale = Vector2(1, 0.5)               # thin bar under the number
	root.add_child(health_bar)
	# blinking storm icon under the strip
	storm_icon = _icon("icon_storm", Vector2(568, strip_height + 2), root)
	storm_icon.visible = false
	blackout_icon = _icon("icon_blackout", Vector2(532, strip_height + 2), root)
	blackout_icon.visible = false
	judge_label = _text(Vector2(440, strip_height + 6), 12, root, UIStyle.JUDGE)     # small, under the strip
	judge_label.text = Text.t("ui.judge_label")
	judge_label.visible = false
	# Fact log: a "?" button at the right end of the strip (also the F key); reopens every info card seen so far
	var fb := UIKit.flat_button(Text.t("ui.fact_icon"), Rect2(640.0 - UIStyle.SAFE - 20.0, 8, 20, 20))
	fb.tooltip_text = Text.t("ui.fact_log")
	fb.focus_mode = Control.FOCUS_NONE
	fb.pressed.connect(open_fact_log)
	root.add_child(fb)
	fact_btn = fb
	# notice line
	notice_panel = ColorRect.new()
	notice_panel.color = Color(0.04, 0.05, 0.1, 0.75)
	notice_panel.position = Vector2(0, 322)
	notice_panel.size = Vector2(640, 38)
	notice_panel.visible = false
	root.add_child(notice_panel)
	notice_label = UIKit.world_label("", 16, UIStyle.ACCENT)
	notice_label.position = Vector2(12, 4)
	notice_label.size = Vector2(616, 32)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_panel.add_child(notice_label)
	# red damage flash and the big MISSION FAILED banner
	flash = ColorRect.new()
	flash.color = Color(1, 0.1, 0.1, 0.0)
	flash.size = Vector2(640, 360)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	banner_panel = ColorRect.new()
	banner_panel.color = Color(0.45, 0.05, 0.08, 0.9)
	banner_panel.position = Vector2(20, 130)
	banner_panel.size = Vector2(600, 64)
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.visible = false
	root.add_child(banner_panel)
	banner_label = UIKit.world_label("", 24)
	banner_label.position = Vector2(0, 16)
	banner_label.size = Vector2(600, 32)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_panel.add_child(banner_label)
	# day splash and fade (above everything)
	day_card = ColorRect.new()
	day_card.color = Color(0.04, 0.05, 0.1, 0.85)
	day_card.position = Vector2(160, 120)
	day_card.size = Vector2(320, 110)
	day_card.visible = false
	root.add_child(day_card)
	splash = UIKit.world_label("", 24)
	splash.position = Vector2(0, 8)
	splash.size = Vector2(320, 56)
	splash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_card.add_child(splash)
	day_info = UIKit.world_label("", 16, UIStyle.ACCENT)
	day_info.position = Vector2(0, 70)
	day_info.size = Vector2(320, 24)
	day_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_card.add_child(day_info)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = Vector2(640, 360)
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)
	UIKit.ignore_mouse(root)
	fact_btn.mouse_filter = Control.MOUSE_FILTER_STOP

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
	for s in stats:
		s["label"].text = s["get"].call()
	var red := UIStyle.DANGER
	stats[1]["label"].modulate = red if GameState.water < Config.data["water"]["warn_below_l"] else Color.WHITE
	stats[2]["label"].modulate = red if GameState.oxygen_h < 12.0 else Color.WHITE
	var low: float = Config.data["power"]["low_pack_warn_pct"]
	stats[3]["label"].modulate = red if GameState.base_pack < low else Color.WHITE
	stats[4]["label"].modulate = red if GameState.spare_pack < low else Color.WHITE
	judge_label.visible = GameState.judge_mode and not GameState.video_mode

func _process(delta: float) -> void:
	# the Health bar animates down (and up) instead of jumping
	shown_health = move_toward(shown_health, GameState.health, delta * 70.0)
	health_bar.set_frac(shown_health / 100.0)
	health_num.text = str(int(ceil(GameState.health)))
	health_num.modulate = UIStyle.ACCENT if GameState.health < 30.0 else Color.WHITE
	_hurt_tick(delta)
	var blink := int(Time.get_ticks_msec() / 300) % 2 == 0
	var low: float = Config.data["power"]["low_pack_warn_pct"]
	stats[3]["icon"].texture = Art.tex("icon_pack_low" if (GameState.base_pack < low and blink) else "icon_pack")
	stats[4]["icon"].texture = Art.tex("icon_pack_low" if (GameState.spare_pack < low and blink) else "icon_pack")
	blackout_icon.visible = GameState.blackout and blink
	# oxygen hours: red under 12 h, blinking under 6 h
	stats[2]["label"].modulate.a = 1.0 if (GameState.oxygen_h >= Config.data["oxygen"]["blink_below_h"] or blink) else 0.25
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

# "Day N" card for 1.5 s at 06:00: the day number, meals and water.
func show_day_splash() -> void:
	splash.text = "%s %d" % [Text.t("ui.day"), GameState.day]
	day_info.text = "%s %d    %s %.1f" % [Text.t("ui.day_card_meals"), GameState.meals_left(), Text.t("ui.day_card_water"), GameState.water]
	day_card.modulate.a = 0.0
	day_card.visible = true
	var tw := create_tween()
	tw.tween_property(day_card, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.1)
	tw.tween_property(day_card, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): day_card.visible = false)

func fade_to_black(seconds: float = 0.6) -> Signal:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, seconds)
	return tw.finished

func fade_from_black(seconds: float = 0.6) -> Signal:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, seconds)
	return tw.finished

# ---------------------------------------------------------------- damage feedback
func _on_game_event(ev_name: String, data: Dictionary) -> void:
	if ev_name == "hurt":
		hurt_acc += data["amount"]
		if data.get("reason", "") != "":
			hurt_reason = data["reason"]
	elif ev_name == "mission_end" and not data["success"]:
		show_banner(Text.t("ui.mission_failed_banner"), 2.0)

# Damage arrives in many small pieces (storm over time, empty oxygen): show it in chunks of 3 or more.
func _hurt_tick(delta: float) -> void:
	if hurt_acc <= 0.0:
		return
	hurt_timer += delta
	if hurt_timer >= 0.35 and hurt_acc >= 3.0:
		_show_hurt(hurt_acc, hurt_reason)
		hurt_acc = 0.0
		hurt_timer = 0.0
		hurt_reason = ""
	elif hurt_timer >= 3.0:
		hurt_acc = 0.0                           # tiny damage that never adds up: no effect
		hurt_timer = 0.0

func _show_hurt(amount: float, reason: String) -> void:
	# red flash 0.3 s
	flash.color.a = 0.35
	create_tween().tween_property(flash, "color:a", 0.0, 0.3)
	# short screen shake (camera offset)
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var tw := create_tween()
		for i in 6:
			tw.tween_property(cam, "offset", Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.04)
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)
	# the heart shakes
	var hp := heart_icon.position
	var th := create_tween()
	for i in 5:
		th.tween_property(heart_icon, "position", hp + Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.04)
	th.tween_property(heart_icon, "position", hp, 0.04)
	# floating "-30" above the player
	var pl := get_tree().get_first_node_in_group("player")
	var at := Vector2(320, 180)
	if pl != null:
		at = get_viewport().get_canvas_transform() * pl.global_position + Vector2(-20, -100)
	var l := UIKit.world_label("-%d" % int(round(amount)), 24, UIStyle.DANGER)
	l.position = at
	add_child(l)
	var tf := create_tween()
	tf.set_parallel(true)
	tf.tween_property(l, "position:y", at.y - 50.0, 1.2)
	tf.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tf.chain().tween_callback(l.queue_free)
	if reason != "" and Text.data.get("damage", {}).has(reason):
		say(Text.t("damage." + reason))

func show_banner(text: String, seconds: float) -> void:
	banner_label.text = text
	banner_panel.visible = true
	await get_tree().create_timer(seconds).timeout
	banner_panel.visible = false

func open_fact_log() -> void:
	if GameState.cards_seen.is_empty() or GameState.modal_count > 0:
		return
	var c = load("res://scenes/InfoCard.tscn").instantiate()
	c.keys = GameState.cards_seen.duplicate()
	add_child(c)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F and GameState.modal_count == 0:
		open_fact_log()
