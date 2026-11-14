# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
class_name HudBar
extends Control
# A bar: bar_frame (3-slice) with a tinted fill inside (docs/04: inner rect x 3-125, y 4-13).
var fill: ColorRect
var inner_w := 0.0

func setup(width: float, color: Color) -> HudBar:
	var frame := NinePatchRect.new()
	frame.texture = Art.tex("bar_frame")
	frame.patch_margin_left = 8
	frame.patch_margin_right = 8
	frame.size = Vector2(width, 16)
	add_child(frame)
	fill = ColorRect.new()
	fill.color = color
	fill.position = Vector2(3, 4)
	inner_w = width - 6.0
	fill.size = Vector2(inner_w, 9)
	add_child(fill)
	custom_minimum_size = Vector2(width, 16)
	size = Vector2(width, 16)
	return self

func set_frac(f: float) -> void:
	fill.size.x = inner_w * clampf(f, 0.0, 1.0)
