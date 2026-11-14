# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Modal
# SliderPanel: the 4 power sliders. Up/Down choose a slider, Left/Right change it, E or Esc close.
# Uses slider_track (zones low/medium/high) and slider_knob from the art.

const ROW_ICONS := ["icon_oxygen", "icon_radish", "icon_research", "icon_storm"]
const ROW_TEXT := ["ui.slider_life", "ui.slider_food", "ui.slider_science", "ui.slider_watch"]
const ZONE_X := [25.0, 63.5, 102.0]      # knob centre inside the 128 px track art (low, medium, high)
@export var track_scale := 0.75
@export var row_y0 := 24.0
@export var row_h := 27.0

var sel := 0
var knobs: Array = []
var kw_labels: Array = []
var hilite: ColorRect
var made_l: Label
var used_l: Label
var hours_l: Label
var track_x := 150.0

func _ready() -> void:
	super._ready()
	var root := Control.new()
	add_child(root)
	root.add_child(UIKit.dim(0.5))
	root.add_child(UIKit.panel(Vector2(8, 4), Vector2(304, 172)))
	hilite = ColorRect.new()
	hilite.color = Color(1, 0.82, 0.25, 0.22)
	hilite.size = Vector2(276, row_h - 1)
	root.add_child(hilite)
	for i in 4:
		var y := row_y0 + i * row_h
		var ic := UIKit.icon(ROW_ICONS[i], 18)
		ic.position = Vector2(22, y + 3)
		root.add_child(ic)
		var lb := UIKit.label(Text.t(ROW_TEXT[i]), 10)
		lb.position = Vector2(44, y + 2)
		root.add_child(lb)
		var tr := TextureRect.new()
		tr.texture = Art.tex("slider_track")
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(128, 32) * track_scale
		tr.position = Vector2(track_x, y)
		root.add_child(tr)
		var kn := TextureRect.new()
		kn.texture = Art.tex("slider_knob")
		kn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		kn.size = Vector2(32, 32) * track_scale
		root.add_child(kn)
		knobs.append(kn)
		var kl := UIKit.label("", 9, Color(0.8, 0.9, 1.0))
		kl.position = Vector2(256, y + 4)
		root.add_child(kl)
		kw_labels.append(kl)
	var pi := UIKit.icon("icon_sun", 14)
	pi.position = Vector2(22, 136)
	root.add_child(pi)
	made_l = UIKit.label("", 9)
	made_l.position = Vector2(38, 134)
	root.add_child(made_l)
	var ui_i := UIKit.icon("icon_pack", 14)
	ui_i.position = Vector2(22, 152)
	root.add_child(ui_i)
	used_l = UIKit.label("", 9)
	used_l.position = Vector2(38, 150)
	root.add_child(used_l)
	hours_l = UIKit.label("", 9, Color("9BE8FF"))
	hours_l.position = Vector2(170, 150)
	root.add_child(hours_l)
	_refresh()

func _refresh() -> void:
	hilite.position = Vector2(20, row_y0 + sel * row_h)
	for i in 4:
		var lvl: int = GameState.sliders[i]
		var cx: float = track_x + ZONE_X[lvl] * track_scale
		knobs[i].position = Vector2(cx - 16.0 * track_scale, row_y0 + i * row_h)
		kw_labels[i].text = "%.1f kW" % GameState.slider_kw(i)
	made_l.text = "%s %.1f kW" % [Text.t("ui.power_made"), GameState.panel_kw()]
	used_l.text = "%s %.1f kW" % [Text.t("ui.power_used"), GameState.draw_kw()]
	var h := GameState.base_hours_left()
	hours_l.text = "" if h >= 99.0 else "%s: %d %s" % [Text.t("ui.pack_base"), int(h), Text.t("ui.hours_left")]

func _unhandled_input(e: InputEvent) -> void:
	if not ready_for_input():
		return
	if e.is_action_pressed("move_down"):
		sel = (sel + 1) % 4
	elif e.is_action_pressed("move_up"):
		sel = (sel + 3) % 4
	elif e.is_action_pressed("move_left"):
		GameState.set_slider(sel, GameState.sliders[sel] - 1)
		Audio.play("slider_tick")
	elif e.is_action_pressed("move_right"):
		GameState.set_slider(sel, GameState.sliders[sel] + 1)
		Audio.play("slider_tick")
	elif e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE):
		close_modal()
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()
