class_name UIKit
extends RefCounted
# Small helpers that build UI pieces from the pixel art. Used by all overlays.

const FONT := 10

# Text sizes are snapped to the pixel font's clean sizes (virtual units; UI layers are drawn at 2x):
# Silkscreen is an 8 px font: use whole multiples only. 8 = body/small (16 real), 12 = heading (24), 16 = title (32), 24 = splash (48).
static func snap_size(size: int) -> int:
	if size <= 10:
		return 8
	if size <= 13:
		return 12
	if size <= 18:
		return 16
	return 24

# UI label for the 2x UI layers: the font is rendered at 2x its virtual size and the label is drawn at scale 0.5,
# so glyphs are crisp at the font's real pixel size (no blurry upscaled text). Position stays in virtual units;
# set the box with UIKit.box(label, w, h) (virtual units).
static func label(text: String, size: int = FONT, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", snap_size(size) * 2)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 1)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.scale = Vector2(0.5, 0.5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func box(l: Control, w: float, h: float) -> void:
	l.size = Vector2(w, h) * 2.0
	l.custom_minimum_size = l.size

# Label for the world (scale 1, real pixels): prompts and lock labels above buildings.
static func world_label(text: String, px: int = 16, color: Color = Color.WHITE) -> Label:
	px = maxi(16, int(round(px / 8.0)) * 8)      # whole multiples of the font size 8, never below 16
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 1)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
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

# Make a node and all its children ignore the mouse (HUD, storm panel, banners must never swallow clicks).
static func ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		ignore_mouse(c)

static func dim(alpha: float = 0.45) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.02, 0.03, 0.08, alpha)
	c.size = Vector2(320, 180)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# A real Button (mouse + keyboard focus) drawn with the button art (3-slice, margin 17, height 32).
static func button(text: String, width: float = 120.0) -> Button:
	var b := Button.new()
	b.text = text
	# width = text + 24 px, minimum 96 (real pixels)
	var f: Font = ThemeDB.get_project_theme().default_font if ThemeDB.get_project_theme() != null else ThemeDB.fallback_font
	var tw: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	b.custom_minimum_size = Vector2(maxf(maxf(width, 96.0), tw + 24.0), 32)
	b.size = b.custom_minimum_size
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxTexture.new()
		sb.texture = Art.tex("button_" + ("hover" if state == "focus" else state))
		sb.texture_margin_left = 17
		sb.texture_margin_right = 17
		sb.content_margin_top = 1.0 if state == "pressed" else 0.0
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("FFD23F"))
	b.add_theme_constant_override("outline_size", 1)
	b.add_theme_constant_override("h_separation", 0)
	b.add_theme_color_override("font_hover_color", Color("FFD23F"))
	b.add_theme_color_override("font_focus_color", Color("FFD23F"))
	return b

# Small flat debug button (Judge panel).
static func flat_button(text: String, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = true
	b.custom_minimum_size = rect.size
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 8)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": Color("1F2438"), "hover": Color("3D4560"), "pressed": Color("2F5BE0"), "focus": Color("3D4560")}[state]
		sb.border_color = Color("A3ABC2")
		sb.set_border_width_all(1)
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		b.add_theme_stylebox_override(state, sb)
	return b
