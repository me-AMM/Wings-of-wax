# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Renders the digit test line in each candidate font at the HUD size (16 px), no antialiasing / hinting.
var n := 0
func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1F2438")
	bg.size = Vector2(640, 360)
	add_child(bg)
	var base := "E:/AMUNi/Wings of wax/junior-astronaut-mission-trainer/"
	var f := FontFile.new()
	f.load_dynamic_font(base + "fonts/PixelifySans.ttf")
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var y := 4.0
	for sz in [16, 20, 22, 24, 28, 32]:
		var l := Label.new()
		l.text = "%d: 3 5 8 9 0123456789 Day 32 S5 9.7L 88%%" % sz
		l.position = Vector2(8, y)
		l.add_theme_font_override("font", f)
		l.add_theme_font_size_override("font_size", sz)
		l.add_theme_color_override("font_color", Color("F0F4FF"))
		add_child(l)
		y += sz + 14
func _process(_d: float) -> void:
	n += 1
	if n == 12:
		get_viewport().get_texture().get_image().save_png("E:/AMUNi/shot15.png")
		get_tree().quit()
