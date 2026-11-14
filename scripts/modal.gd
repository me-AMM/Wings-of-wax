# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
class_name Modal
extends CanvasLayer
# Base for overlays that pause the game clock and take the keyboard (menus, cards, sliders).
signal closed
var is_open := false
var _age := 0.0

func _ready() -> void:
	layer = 20
	scale = Vector2(2, 2)      # UI is authored in 320x180 units; the view is 640x360
	is_open = true
	GameState.modal_count += 1
	call_deferred("_intro")

func _process(delta: float) -> void:
	_age += delta

# Ignore input for a moment so the key that opened us does not also act inside.
func ready_for_input() -> bool:
	return is_open and _age > 0.3        # a quick double tap of E does not also pick the first item

func close_modal() -> void:
	if not is_open:
		return
	is_open = false
	GameState.modal_count = maxi(0, GameState.modal_count - 1)
	GameState.last_modal_close_ms = Time.get_ticks_msec()
	closed.emit()
	var tw := create_tween().set_parallel(true)
	for c in get_children():
		if c is CanvasItem:
			tw.tween_property(c, "modulate:a", 0.0, UIStyle.PANEL_FADE)
	tw.chain().tween_callback(queue_free)

# the same open animation for every panel: 0.12 s fade and a 2 px slide up
func _intro() -> void:
	for c in get_children():
		if c is Control:
			c.modulate.a = 0.0
			c.position.y += UIStyle.PANEL_SLIDE
			var tw := create_tween().set_parallel(true)
			tw.tween_property(c, "modulate:a", 1.0, UIStyle.PANEL_FADE)
			tw.tween_property(c, "position:y", c.position.y - UIStyle.PANEL_SLIDE, UIStyle.PANEL_FADE)
