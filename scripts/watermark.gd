# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends CanvasLayer
# Watermark autoload: a small, persistent "Art: AI-generated (Pixel Lab)" label in the bottom-right corner of EVERY
# screen (title, gameplay, endings, credits). Required by the challenge rules for AI-generated images.
# It stays on in Video mode. Font size 8 = 16 px when recorded at 1280x720.

var label: Label

func _ready() -> void:
	layer = 250                                   # above every other layer
	process_mode = Node.PROCESS_MODE_ALWAYS
	label = Label.new()
	label.text = Text.t("ui.watermark")
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 2)
	label.modulate.a = 0.6                        # about 60% opacity
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.position = Vector2(340, 347)
	label.size = Vector2(296, 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
