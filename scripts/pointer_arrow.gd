extends Node2D
# Pointer arrow: a small yellow triangle with a 1 px dark outline, drawn in code (no art).
# The Mission scene moves it around the player (about 24 px away) and rotates it toward the target.
func _ready() -> void:
	z_index = 300

func _draw() -> void:
	var pts := PackedVector2Array([Vector2(8, 0), Vector2(-5, -6), Vector2(-5, 6)])
	draw_colored_polygon(pts, Color("FFD23F"))
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	draw_polyline(outline, Color("0B0D1A"), 1.0)
