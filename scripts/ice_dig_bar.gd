extends CanvasLayer
# IceDigBar: a marker slides back and forth; press E when it is inside the green zone (3 hits needed).
# Does NOT pause the clock (a storm countdown keeps running while you dig). Esc cancels.
# Numbers come from assets/manifest.json ui_layout.dig_bar: zone x 78-114, track inner x 4-187.
signal finished(hits: int)

@export var hits_needed := 3
@export var marker_speed := 2.6          # sweeps per second-ish (higher = harder)
const ZONE := Vector2(78, 114)
const TRACK := Vector2(4, 187)

var bar_pos := Vector2(64, 124)
var marker: TextureRect
var hits := 0
var t := 0.0
var hits_label: Label
var age := 0.0

func _ready() -> void:
	layer = 15
	scale = Vector2(2, 2)
	var root := Control.new()
	add_child(root)
	root.add_child(UIKit.panel(Vector2(48, 104), Vector2(224, 68)))
	var bar := TextureRect.new()
	bar.texture = Art.tex("dig_bar")
	bar.position = bar_pos
	root.add_child(bar)
	marker = TextureRect.new()
	marker.texture = Art.tex("dig_marker")
	marker.position = bar_pos
	root.add_child(marker)
	hits_label = UIKit.label("", 9, Color("FFD23F"))
	hits_label.position = Vector2(60, 110)
	root.add_child(hits_label)
	var hint := UIKit.label(Text.t("ui.dig_hint"), 8)
	hint.position = Vector2(60, 158)
	root.add_child(hint)
	_update()

func _update() -> void:
	hits_label.text = "%s %d/%d" % [Text.t("ui.dig_ice"), hits, hits_needed]

func marker_x() -> float:
	return lerpf(TRACK.x, TRACK.y, (sin(t * marker_speed) + 1.0) / 2.0)

func _process(delta: float) -> void:
	t += delta
	age += delta
	marker.position = Vector2(bar_pos.x + marker_x() - 6.0, bar_pos.y)

func _unhandled_input(e: InputEvent) -> void:
	if age < 0.2:
		return
	if e.is_action_pressed("interact"):
		var x := marker_x()
		if x >= ZONE.x and x <= ZONE.y:
			hits += 1
			Audio.play("ice_dig_hit")
			_update()
			if hits >= hits_needed:
				finished.emit(hits)
				queue_free()
		else:
			Audio.play("ice_dig_miss")
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		finished.emit(hits)
		queue_free()
		get_viewport().set_input_as_handled()
