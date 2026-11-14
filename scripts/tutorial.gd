# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node2D
# Guided start for kids: a daily goal checklist top-left (eat, drink, water radishes, sleep) that ticks off, and on
# days 1-3 a bouncing arrow over the next building with a one-line goal. "Skip tutorial (K)" turns the arrow off.
const ARROW_Y := -12.0

var outpost: Node
var layer: CanvasLayer
var goal_label: Label
var checks: Array = []          # [{key, label}]
var skip_btn: Button
var t := 0.0
var panel: Control              # the TODAY checklist, docked under the HUD strip on the left
var box: Control
var collapsed := false          # T folds it to its heading
const FADE_ALPHA := 0.4         # when the player walks behind the panel

func _ready() -> void:
	z_index = 300
	layer = CanvasLayer.new()
	layer.layer = 9                 # under the HUD strip layer (10), above the world
	add_child(layer)
	panel = Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	box = UIKit.dark_box()
	box.position = Vector2(UIStyle.SAFE, 40)
	box.size = Vector2(150, 78)
	panel.add_child(box)
	var head := UIKit.world_label(Text.t("ui.goals") + " " + Text.t("ui.goals_hide"), 16, UIStyle.ACCENT)
	head.position = Vector2(UIStyle.SAFE + 6, 40)
	panel.add_child(head)
	var y := 58.0
	for k in ["eat", "drink", "radish", "sleep"]:
		var l := UIKit.world_label("", 12)
		l.position = Vector2(UIStyle.SAFE + 6, y)
		panel.add_child(l)
		checks.append({"key": k, "label": l})
		y += 14.0
	goal_label = UIKit.world_label("", 16, UIStyle.ACCENT)
	goal_label.position = Vector2(0, 296)
	goal_label.size = Vector2(640, 20)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(goal_label)
	skip_btn = UIKit.flat_button(Text.t("ui.skip_tutorial"), Rect2(UIStyle.SAFE, 122, 150, 18))
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.pressed.connect(_skip)
	layer.add_child(skip_btn)

func _skip() -> void:
	GameState.tutorial_off = true

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_K:
		_skip()
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_T:
		collapsed = not collapsed
		for c in checks:
			c["label"].visible = not collapsed
		box.size.y = 20.0 if collapsed else 78.0

# fade the checklist to 40% while the astronaut is behind it, so it never hides the player
func _fade_panel() -> void:
	var pl: Node2D = outpost.get_node_or_null("World/Player") if outpost != null else null
	if pl == null:
		return
	var sp: Vector2 = pl.get_global_transform_with_canvas().origin
	var r := Rect2(box.position, box.size).grow(12)
	var target := FADE_ALPHA if r.has_point(sp) or r.has_point(sp + Vector2(0, -24)) else 1.0
	panel.modulate.a = move_toward(panel.modulate.a, target, 0.08)

# which goal is next today, and which building it is at
func _next_goal() -> Array:
	var gs := GameState
	if not gs.ate_today:
		return ["eat", "Habitat"]
	if not gs.drank_today and gs.is_unlocked("recycler"):
		return ["drink", "Recycler"]
	if gs.is_unlocked("greenhouse") and not gs.watered_today and not gs.tray_ready:
		return ["radish", "Tray"]
	if gs.day == 3 and not gs.sliders_tried:
		return ["sliders", "Console"]
	if not gs.slept_today and fmod(gs.hour, 24.0) >= 18.0:
		return ["sleep", "Habitat"]
	if not gs.slept_today:
		return ["wait", ""]
	return ["done", ""]

func _process(delta: float) -> void:
	t += delta
	_fade_panel()
	var gs := GameState
	# checklist
	for c in checks:
		var l: Label = c["label"]
		var done := false
		var locked_day := 0
		match c["key"]:
			"eat": done = gs.ate_today
			"drink":
				done = gs.drank_today
				locked_day = 0 if gs.is_unlocked("recycler") else int(Config.data["unlock_day"]["recycler"])
			"radish":
				done = gs.watered_today
				locked_day = 0 if gs.is_unlocked("greenhouse") else int(Config.data["unlock_day"]["greenhouse"])
			"sleep": done = gs.slept_today
		var name: String = Text.t("ui.goal_" + c["key"])
		if locked_day > 0:
			l.text = "  " + name + " " + Text.t("ui.goal_later") % locked_day
			l.modulate = Color(0.6, 0.62, 0.7)
		else:
			l.text = ("[x] " if done else "[ ] ") + name
			l.modulate = UIStyle.GOOD if done else Color.WHITE
	# guided arrow and one-line goal on days 1-3
	var guided: bool = gs.day <= 3 and not gs.tutorial_off and gs.modal_count == 0
	skip_btn.visible = gs.day <= 3 and not gs.tutorial_off
	if not guided:
		goal_label.text = ""
		visible = false
		return
	var g := _next_goal()
	goal_label.text = Text.t("tutorial." + g[0])
	var target: Node2D = outpost.get_node_or_null("World/" + g[1]) if g[1] != "" else null
	visible = target != null
	if target != null:
		# just above the building's door / base, where the player has to go
		global_position = Vector2(target.global_position.x, target.global_position.y - 46.0 + sin(t * 5.0) * 5.0)
		queue_redraw()

# a bouncing yellow arrow pointing down at the building
func _draw() -> void:
	var pts := PackedVector2Array([Vector2(0, 10), Vector2(-9, -4), Vector2(-3, -4), Vector2(-3, -14), Vector2(3, -14), Vector2(3, -4), Vector2(9, -4)])
	draw_colored_polygon(pts, UIStyle.ACCENT)
	var o := PackedVector2Array(pts)
	o.append(pts[0])
	draw_polyline(o, UIStyle.PANEL_DARK, 1.0)
