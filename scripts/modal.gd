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
	queue_free()
