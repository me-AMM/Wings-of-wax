class_name UIKit
extends RefCounted
# Small helpers that build UI pieces from the pixel art. Used by all overlays.

const FONT := 10

static func label(text: String, size: int = FONT, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func icon(icon_name: String, px: int = 16) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Art.tex(icon_name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.size = Vector2(px, px)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

# 9-slice panel (ui_panel: margins 13 left/right, 14 top/bottom)
static func panel(pos: Vector2, size: Vector2) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = Art.tex("ui_panel")
	n.patch_margin_left = 13
	n.patch_margin_right = 13
	n.patch_margin_top = 14
	n.patch_margin_bottom = 14
	n.position = pos
	n.size = size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

# Button background: horizontal 3-slice, fixed height 32, margin 17. state: normal / hover / pressed
static func button_bg(width: float, state: String = "normal") -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = Art.tex("button_" + state)
	n.patch_margin_left = 17
	n.patch_margin_right = 17
	n.size = Vector2(maxf(width, 38.0), 32)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

static func dim(alpha: float = 0.55) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.02, 0.03, 0.08, alpha)
	c.size = Vector2(320, 180)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
