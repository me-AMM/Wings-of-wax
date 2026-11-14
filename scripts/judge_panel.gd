extends Modal
# JudgePanel: debug panel for judges. Mouse or keyboard (Tab / arrows / Enter). Esc or Close to leave.
var from_title := false
var day_slider: HSlider
var day_label: Label
var speed_btn: Button

func _ready() -> void:
	super._ready()
	layer = 30
	var root := Control.new()
	add_child(root)
	root.add_child(UIKit.dim(0.8))
	root.add_child(UIKit.panel(Vector2(4, 3), Vector2(312, 174)))
	var title := UIKit.label(Text.t("ui.judge_label"), 10, Color("F06FA8"))
	title.position = Vector2(18, 8)
	root.add_child(title)
	# day picker
	day_label = UIKit.label("", 9)
	day_label.position = Vector2(18, 24)
	root.add_child(day_label)
	day_slider = HSlider.new()
	day_slider.min_value = 1
	day_slider.max_value = 32
	day_slider.step = 1
	day_slider.value = GameState.day
	day_slider.position = Vector2(70, 26)
	day_slider.size = Vector2(170, 12)
	day_slider.value_changed.connect(func(_v): _refresh())
	root.add_child(day_slider)
	var jump := UIKit.flat_button(Text.t("ui.judge_jump"), Rect2(250, 22, 54, 16))
	jump.pressed.connect(func(): _do(func(): Judge.jump_to_day(int(day_slider.value)); Judge.go_outpost()))
	root.add_child(jump)
	# storms
	_row(root, 44, [
		[Text.t("ui.judge_storm_small"), func(): Judge.trigger_storm("small")],
		[Text.t("ui.judge_storm_medium"), func(): Judge.trigger_storm("medium")],
		[Text.t("ui.judge_storm_large"), func(): Judge.trigger_storm("large")],
		[Text.t("ui.judge_storm_finale"), func(): Judge.trigger_storm("finale")]])
	# events
	_row(root, 64, [
		[Text.t("ui.judge_shadow"), func(): Judge.start_shadow()],
		[Text.t("ui.judge_end_shadow"), func(): Judge.end_shadow()],
		[Text.t("ui.judge_land"), func(): Judge.land_cargo()],
		[Text.t("ui.judge_mission"), func(): Judge.start_mission()]], false)
	# helpers
	var refill := UIKit.flat_button(Text.t("ui.judge_refill"), Rect2(14, 84, 70, 16))
	refill.pressed.connect(func(): Judge.refill_all())
	root.add_child(refill)
	speed_btn = UIKit.flat_button(Text.t("ui.judge_speed"), Rect2(87, 84, 70, 16))
	speed_btn.toggle_mode = true
	speed_btn.button_pressed = GameState.time_scale > 1.0
	speed_btn.toggled.connect(func(_on): Judge.toggle_speed())
	root.add_child(speed_btn)
	# presets
	var pl := UIKit.label(Text.t("ui.judge_presets"), 8, Color("FFD23F"))
	pl.position = Vector2(14, 104)
	root.add_child(pl)
	var presets := [
		[Text.t("ui.judge_preset_storm_mission"), func(): Judge.preset_storm_in_mission()],
		[Text.t("ui.judge_preset_shadow"), func(): Judge.preset_shadow()],
		[Text.t("ui.judge_preset_big_storm"), func(): Judge.preset_big_storm()]]
	for i in 3:
		var b := UIKit.flat_button(presets[i][0], Rect2(14, 116 + i * 17, 292, 16))
		var cb: Callable = presets[i][1]
		b.pressed.connect(func(): _do(cb))
		root.add_child(b)
	if from_title:
		var start := UIKit.flat_button(Text.t("ui.judge_start_game"), Rect2(160, 84, 70, 16))
		start.pressed.connect(func(): _do(func(): Judge.go_outpost()))
		root.add_child(start)
	var close := UIKit.flat_button(Text.t("ui.judge_close"), Rect2(236, 84, 70, 16))
	close.pressed.connect(close_modal)
	root.add_child(close)
	_refresh()
	day_slider.grab_focus()

func _row(root: Control, y: float, defs: Array, closes := true) -> void:
	var w := 70.0
	for i in defs.size():
		var b := UIKit.flat_button(defs[i][0], Rect2(14 + i * 73, y, w, 16))
		var cb: Callable = defs[i][1]
		b.pressed.connect(func(): _do(cb) if closes else cb.call())
		root.add_child(b)

func _refresh() -> void:
	day_label.text = "%s %d" % [Text.t("ui.judge_day_label"), int(day_slider.value)]

# Run an action, closing the panel first (so overlays and scene changes start clean).
func _do(cb: Callable) -> void:
	close_modal()
	cb.call()

func _unhandled_input(e: InputEvent) -> void:
	if ready_for_input() and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		close_modal()
		get_viewport().set_input_as_handled()
