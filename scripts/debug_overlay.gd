# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node2D
# F3 overlay: shows footprints (red), slow zones (cyan) and interaction radii (yellow). Off by default.
func _ready() -> void:
	z_index = 4000
	visible = false

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F3:
		visible = not visible
		queue_redraw()

func _process(_d: float) -> void:
	if GameState.video_mode:
		visible = false
	if visible:
		queue_redraw()

func _draw() -> void:
	for group_name in ["footprint_shape", "slow_shape"]:
		var col := Color(1, 0.15, 0.15, 0.45) if group_name == "footprint_shape" else Color(0.2, 0.9, 1, 0.35)
		for s in get_tree().get_nodes_in_group(group_name):
			if s is CollisionPolygon2D and s.is_inside_tree():
				var pts := PackedVector2Array()
				for p in s.polygon:
					pts.append(s.global_transform * p)
				if pts.size() >= 3:
					draw_colored_polygon(pts, col)
					pts.append(pts[0])
					draw_polyline(pts, Color(col.r, col.g, col.b, 1.0), 1.0)
	for it in get_tree().get_nodes_in_group("interactable"):
		if it.visible and it.radius > 0.0:
			draw_arc(it.global_position + Vector2(0, 8), it.radius, 0.0, TAU, 32, Color(1, 0.85, 0.2, 0.8), 1.0)
