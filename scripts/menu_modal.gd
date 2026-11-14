# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
class_name MenuModal
extends Modal
# A vertical menu of buttons: up/down to move, E to choose, Esc to close.
# items: [{icon, text, sub, enabled, call}]
var items: Array = []
var title_text := ""
var sel := 0
var rows: Array = []
@export var menu_width := 200.0

func build() -> void:
	var root := Control.new()
	add_child(root)
	var dim := UIKit.dim()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP          # clicks never reach the buttons behind the menu
	dim.gui_input.connect(_on_click)
	root.add_child(dim)
	get_viewport().gui_release_focus()                     # keyboard belongs to this menu, not to buttons behind it
	var h := 34.0 + items.size() * 32.0 + 10.0
	var x := (320.0 - menu_width) / 2.0
	var y := (180.0 - h) / 2.0
	root.add_child(UIKit.panel(Vector2(x, y), Vector2(menu_width, h)))
	var title := UIKit.label(title_text, 10, UIStyle.ACCENT)
	title.position = Vector2(x + 22, y + 14)
	root.add_child(title)
	for i in items.size():
		var it: Dictionary = items[i]
		var bx := x + 14.0
		var by := y + 30.0 + i * 32.0
		var bg := UIKit.button_bg(menu_width - 28.0, "normal")
		bg.position = Vector2(bx, by)
		root.add_child(bg)
		var ic := UIKit.icon(it.get("icon", "icon_heart"), 16)   # 16 in the 2x layer = the 32 px icon 1:1
		ic.position = Vector2(bx + 12, by + 8)
		root.add_child(ic)
		var col := Color.WHITE if it.get("enabled", true) else Color(0.6, 0.62, 0.7)
		var lb := UIKit.label(it["text"], 10, col)
		lb.position = Vector2(bx + 38, by + 9)
		root.add_child(lb)
		var sub := UIKit.label(it.get("sub", ""), 8, Color(0.8, 0.85, 1.0))
		sub.position = Vector2(bx + 38, by + 9)
		UIKit.box(sub, menu_width - 28.0 - 50.0, 12)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# a long reason: drop to the small size, and if it still does not fit, put it under the label
		var f: Font = sub.get_theme_font("font")
		var room := (menu_width - 28.0 - 50.0) * 2.0
		if f.get_string_size(sub.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > room:
			sub.add_theme_font_size_override("font_size", 12)
			if f.get_string_size(sub.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > room:
				sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				lb.position.y = by + 4
				sub.position.y = by + 16
		root.add_child(sub)
		rows.append({"bg": bg, "label": lb, "sub": sub})
	_refresh()

func _refresh() -> void:
	for i in rows.size():
		var state := "hover" if i == sel else "normal"
		rows[i]["bg"].texture = Art.tex("button_" + state)

func _unhandled_input(e: InputEvent) -> void:
	if not ready_for_input():
		return
	if e.is_action_pressed("move_down"):
		sel = (sel + 1) % items.size()
		_refresh()
	elif e.is_action_pressed("move_up"):
		sel = (sel - 1 + items.size()) % items.size()
		_refresh()
	elif e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
		var it: Dictionary = items[sel]
		if it.get("enabled", true):
			close_modal()
			if it.has("call"):
				it["call"].call()
		else:
			Audio.play("ui_click")
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		close_modal()
	elif e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down") or e.is_action_pressed("ui_left") or e.is_action_pressed("ui_right") or e.is_action_pressed("ui_focus_next"):
		pass                                                   # swallow: no focus moves behind the menu
	else:
		return
	get_viewport().set_input_as_handled()

# Mouse: a click on a row picks it (rows are in 320x180 units, the layer is drawn at 2x).
func _on_click(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or not ready_for_input():
		return
	var p: Vector2 = e.position
	for i in rows.size():
		var bg: Control = rows[i]["bg"]
		if Rect2(bg.position, bg.size).has_point(p):
			sel = i
			_refresh()
			var it: Dictionary = items[i]
			if it.get("enabled", true):
				close_modal()
				if it.has("call"):
					it["call"].call()
			return
