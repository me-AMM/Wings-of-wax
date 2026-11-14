extends Modal
# InfoCard: shows a queue of cards from data/text.json "cards". E closes the current card.
# Set `keys` before adding to the tree.
var keys: Array = []
var root: Control
var title_l: Label
var body_l: Label
var src_l: Label
var idx := 0

func _ready() -> void:
	super._ready()
	root = Control.new()
	add_child(root)
	root.add_child(UIKit.dim(0.5))
	root.add_child(UIKit.panel(Vector2(20, 22), Vector2(280, 136)))
	var star := UIKit.icon("icon_research", 24)
	star.position = Vector2(32, 34)
	root.add_child(star)
	title_l = UIKit.label("", 11, Color("FFD23F"))
	title_l.position = Vector2(62, 36)
	root.add_child(title_l)
	body_l = UIKit.label("", 9)
	body_l.position = Vector2(34, 62)
	UIKit.box(body_l, 250, 60)
	body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body_l)
	src_l = UIKit.label("", 8, Color(0.65, 0.7, 0.85))
	src_l.position = Vector2(34, 128)
	UIKit.box(src_l, 220, 20)
	src_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(src_l)
	var ek := UIKit.icon("icon_ekey", 20)
	ek.position = Vector2(272, 132)
	root.add_child(ek)
	_show()

func _show() -> void:
	var c: Dictionary = Text.card(keys[idx])
	title_l.text = c["title"]
	body_l.text = c["body"]
	src_l.text = c["source"]
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
