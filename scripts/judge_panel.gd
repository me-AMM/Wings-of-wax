# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Modal
# JudgePanel (debug panel for judges). Drawn in real 640x360 pixels (not the 2x UI scale).
# Mouse or keyboard: Tab / arrows / Enter. J toggles, Esc or Close leaves.
var from_title := false
var day_slider: HSlider
var day_label: Label
const PW := 420.0
const PH := 300.0
const M := 12.0

func _btn(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := UIKit.flat_button(text, Rect2(pos, size))
	b.add_theme_font_size_override("font_size", 16)
	return b

func _ready() -> void:
	super._ready()
	layer = 100                       # above every other UI layer
	scale = Vector2(1, 1)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(640, 360)
	root.add_child(dim)
	var ox := (640.0 - PW) / 2.0
	var oy := (360.0 - PH) / 2.0
	var bg := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("0B0D1A")
	sb.border_color = Color("F06FA8")
	sb.set_border_width_all(2)
	bg.add_theme_stylebox_override("panel", sb)
	bg.position = Vector2(ox, oy)
	bg.size = Vector2(PW, PH)
	root.add_child(bg)
	# title row: JUDGE MODE ........ [Close]
	var title := UIKit.world_label(Text.t("ui.judge_label"), 16, Color("F06FA8"))
	title.position = Vector2(ox + M, oy + 6)
	root.add_child(title)
	var close := _btn(Text.t("ui.judge_close"), Vector2(ox + PW - M - 80, oy + M - 4), Vector2(80, 24))
	close.pressed.connect(close_modal)
	root.add_child(close)
	# day picker: [<] Day N [>] ====slider==== [Jump]
	var y := oy + 40.0
	var prev := _btn("<", Vector2(ox + M, y), Vector2(24, 24))
	prev.pressed.connect(func(): day_slider.value -= 1)
	root.add_child(prev)
	day_label = UIKit.world_label("", 16)
	day_label.position = Vector2(ox + M + 30, y + 2)
	day_label.custom_minimum_size = Vector2(64, 20)
	root.add_child(day_label)
	var nxt := _btn(">", Vector2(ox + M + 96, y), Vector2(24, 24))
	nxt.pressed.connect(func(): day_slider.value += 1)
	root.add_child(nxt)
	day_slider = HSlider.new()
	day_slider.min_value = 1
	day_slider.max_value = 32
	day_slider.step = 1
	day_slider.value = GameState.day
	day_slider.position = Vector2(ox + M + 128, y + 4)
	day_slider.size = Vector2(PW - 2 * M - 128 - 70, 16)
	var track := StyleBoxFlat.new()          # visible track: 4 px high, light colour
	track.bg_color = Color("A3ABC2")
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	day_slider.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("FFD23F")
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	day_slider.add_theme_stylebox_override("grabber_area", fill)
	day_slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var img := Image.create(8, 16, false, Image.FORMAT_RGBA8)     # 8 px grabber
	img.fill(Color("E4E8F2"))
	var gt := ImageTexture.create_from_image(img)
	day_slider.add_theme_icon_override("grabber", gt)
	day_slider.add_theme_icon_override("grabber_highlight", gt)
	day_slider.value_changed.connect(func(_v): _refresh())
	root.add_child(day_slider)
	var jump := _btn(Text.t("ui.judge_jump"), Vector2(ox + PW - M - 62, y), Vector2(62, 24))
	jump.pressed.connect(func():
		var d := int(day_slider.value)
		_act(func(): Judge.jump_to_day(d); Judge.go_outpost(), Text.t("ui.judge_t_jump") % d))
	root.add_child(jump)
	# 3-column grid of buttons. Every button closes the panel (so you SEE the effect) and shows a confirmation toast.
	var cw := (PW - 2 * M - 16.0) / 3.0
	var sizes := {"small": Text.t("storm_names.small"), "medium": Text.t("storm_names.medium"), "large": Text.t("storm_names.large"), "finale": Text.t("storm_names.finale")}
	var items := [
		[Text.t("ui.judge_storm_small"), func(): Judge.trigger_storm("small"), Text.t("ui.judge_t_storm") % sizes["small"]],
		[Text.t("ui.judge_storm_medium"), func(): Judge.trigger_storm("medium"), Text.t("ui.judge_t_storm") % sizes["medium"]],
		[Text.t("ui.judge_storm_large"), func(): Judge.trigger_storm("large"), Text.t("ui.judge_t_storm") % sizes["large"]],
		[Text.t("ui.judge_storm_finale"), func(): Judge.trigger_storm("finale"), Text.t("ui.judge_t_storm") % sizes["finale"]],
		[Text.t("ui.judge_shadow"), func(): Judge.start_shadow(), Text.t("ui.judge_t_shadow")],
		[Text.t("ui.judge_end_shadow"), func(): Judge.end_shadow(), Text.t("ui.judge_t_sunrise")],
		[Text.t("ui.judge_land"), func(): Judge.land_cargo(), Text.t("ui.judge_t_cargo")],
		[Text.t("ui.judge_mission"), func(): Judge.start_mission(), Text.t("ui.judge_t_mission")],
		[Text.t("ui.judge_refill"), func(): Judge.refill_all(), Text.t("ui.judge_t_refill")],
		[Text.t("ui.judge_speed"), null, ""]]
	var gy := y + 36.0
	for i in items.size():
		var b := _btn(items[i][0], Vector2(ox + M + (i % 3) * (cw + 8.0), gy + (i / 3) * 26.0), Vector2(cw, 24))
		if items[i][1] == null:                         # Speed x4 toggles and keeps the panel open
			b.pressed.connect(func():
				var on := Judge.toggle_speed()
				Judge.toast(Text.t("ui.judge_t_speed_on") if on else Text.t("ui.judge_t_speed_off")))
		else:
			var cb: Callable = items[i][1]
			var msg: String = items[i][2]
			b.pressed.connect(func(): _act(cb, msg))
		root.add_child(b)
	# presets: full width
	var vb := _btn(Text.t("ui.judge_video"), Vector2(ox + M + 1 * (cw + 8.0), gy + 3 * 26.0), Vector2(cw, 24))
	vb.toggle_mode = true
	vb.button_pressed = GameState.video_mode
	vb.pressed.connect(func():
		GameState.video_mode = not GameState.video_mode
		Judge.toast(Text.t("ui.judge_t_video_on") if GameState.video_mode else Text.t("ui.judge_t_video_off")))
	root.add_child(vb)
	var py := gy + 4 * 26.0 + 6.0
	var presets := [
		[Text.t("ui.judge_preset_storm_mission"), func(): Judge.preset_storm_in_mission()],
		[Text.t("ui.judge_preset_shadow"), func(): Judge.preset_shadow()],
		[Text.t("ui.judge_preset_big_storm"), func(): Judge.preset_big_storm()]]
	for i in 3:
		var b := _btn(presets[i][0], Vector2(ox + M, py + i * 26.0), Vector2(PW - 2 * M, 24))
		var cb: Callable = presets[i][1]
		var msg: String = Text.t("ui.judge_t_preset") % presets[i][0]
		b.pressed.connect(func(): _act(cb, msg))
		root.add_child(b)
	if from_title:
		var start := _btn(Text.t("ui.judge_start_game"), Vector2(ox + M, py + 3 * 26.0), Vector2(PW - 2 * M, 24))
		start.pressed.connect(func(): _act(func(): Judge.go_outpost(), Text.t("ui.judge_t_start")))
		root.add_child(start)
	_refresh()
	day_slider.grab_focus()

func _refresh() -> void:
	day_label.text = "%s %d" % [Text.t("ui.judge_day_label"), int(day_slider.value)]

# Close the panel, run the action, confirm with a toast (Judge autoload: works in every scene).
func _act(cb: Callable, msg: String) -> void:
	close_modal()
	cb.call()
	Judge.toast(msg)

func _unhandled_input(e: InputEvent) -> void:
	if ready_for_input() and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		close_modal()
		get_viewport().set_input_as_handled()
