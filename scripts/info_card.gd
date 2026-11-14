extends Modal
# InfoCard: one card at a time from a queue (data/text.json "cards"). Title, body wrapped to about 34 characters,
# dim source line at the bottom, "E to close" with icon_ekey, 0.15 s fade. E or Esc shows the next card / closes.
# Authored in virtual units (the UI layer is drawn at 2x): the panel is 180 wide = 360 real pixels (the maximum).
var keys: Array = []
var root: Control
var title_l: Label
var body_l: Label
var src_l: Label
var idx := 0
const PX := 70.0         # panel left (virtual)
const PY := 24.0
const PW := 180.0
const PH := 132.0
const PAD := 14.0        # 8 px inner padding on top of the 9-slice border

func _ready() -> void:
	super._ready()
	root = Control.new()
	add_child(root)
	root.add_child(UIKit.dim())
	root.add_child(UIKit.panel(Vector2(PX, PY), Vector2(PW, PH)))
	title_l = UIKit.label("", 8, Color("FFD23F"))
	title_l.position = Vector2(PX + PAD, PY + PAD - 2)
	UIKit.box(title_l, PW - 2 * PAD, 12)
	root.add_child(title_l)
	body_l = UIKit.label("", 8)
	body_l.position = Vector2(PX + PAD, PY + PAD + 12)
	UIKit.box(body_l, PW - 2 * PAD, 62)
	body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body_l)
	src_l = UIKit.label("", 6, Color(0.65, 0.7, 0.85))
	src_l.position = Vector2(PX + PAD, PY + PH - PAD - 20)
	UIKit.box(src_l, PW - 2 * PAD - 28, 18)
	src_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(src_l)
	var ek := UIKit.icon("icon_ekey", 16)
	ek.position = Vector2(PX + PW - PAD - 16, PY + PH - PAD - 16)
	root.add_child(ek)
	_show()

func _show() -> void:
	var c: Dictionary = Text.card(keys[idx])
	title_l.text = c["title"]
	body_l.text = c["body"]
	src_l.text = c["source"]
	root.modulate.a = 0.0                                  # 0.15 s fade in
	create_tween().tween_property(root, "modulate:a", 1.0, 0.15)
	Audio.play("info_card")

func _unhandled_input(e: InputEvent) -> void:
	if not ready_for_input():
		return
	if e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE):
		idx += 1
		if idx >= keys.size():
			close_modal()
		else:
			_show()
		get_viewport().set_input_as_handled()
