extends Node
# Instantiates the UI with the LONGEST strings from text.json and reports any label that does not fit.
#   godot --headless --path . res://tools/ui_check.tscn
var fails := 0

func text_w(l: Label, txt: String = "") -> float:
	var f: Font = l.get_theme_font("font")
	var px: int = l.get_theme_font_size("font_size")
	return f.get_string_size(txt if txt != "" else l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x

# Wrapped label: how many lines does the text need in a box of `box_w` (local px)?
func lines_needed(l: Label, box_w: float) -> int:
	var f: Font = l.get_theme_font("font")
	var px: int = l.get_theme_font_size("font_size")
	var para := TextParagraph.new()
	para.add_string(l.text, f, px)
	para.width = box_w
	return para.get_line_count()

func report(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _ready() -> void:
	await get_tree().process_frame
	# --- info cards: longest body and longest title
	var longest := ""
	var blen := 0
	for k in Text.data["cards"]:
		var c: Dictionary = Text.data["cards"][k]
		var n: int = c["body"].length() + c["title"].length() * 2 + c["source"].length()
		if n > blen:
			blen = n
			longest = k
	var card = load("res://scenes/InfoCard.tscn").instantiate()
	card.keys = [longest]
	add_child(card)
	await get_tree().process_frame
	var bl: Label = card.body_l
	var lines := lines_needed(bl, bl.size.x)
	var line_h: float = bl.get_theme_font("font").get_height(bl.get_theme_font_size("font_size")) + 2.0
	report(lines * line_h <= bl.size.y, "info card '%s' body: %d lines x %.0f px in %.0f px box" % [longest, lines, line_h, bl.size.y])
	report(text_w(card.title_l) <= card.title_l.size.x, "info card title '%s' %.0f of %.0f" % [card.title_l.text, text_w(card.title_l), card.title_l.size.x])
	var sl := lines_needed(card.src_l, card.src_l.size.x)
	report(sl * (card.src_l.get_theme_font("font").get_height(card.src_l.get_theme_font_size("font_size")) + 2.0) <= card.src_l.size.y, "info card source '%s': %d lines in %.0f px" % [card.src_l.text, sl, card.src_l.size.y])
	card.close_modal()
	# --- HUD cells with the largest values
	GameState.new_game()
	GameState.day = 32
	GameState.water = 40.0
	GameState.base_pack = 100.0
	GameState.spare_pack = 100.0
	GameState.research = 100.0
	GameState.rations = 36
	var hud = load("res://scripts/hud.gd").new()
	add_child(hud)
	await get_tree().process_frame
	hud.refresh()
	for s in hud.stats:
		var l: Label = s["label"]
		report(text_w(l) <= l.custom_minimum_size.x, "HUD cell '%s' %.0f of %.0f px" % [l.text, text_w(l), l.custom_minimum_size.x])
	report(text_w(hud.clock_label) <= hud.clock_label.custom_minimum_size.x, "HUD clock '%s' %.0f of %.0f px" % [hud.clock_label.text, text_w(hud.clock_label), hud.clock_label.custom_minimum_size.x])
	# longest notice in 2 lines
	var ln := ""
	for k in Text.data["notices"]:
		if Text.data["notices"][k].length() > ln.length():
			ln = Text.data["notices"][k]
	hud.notice_label.text = ln
	report(lines_needed(hud.notice_label, hud.notice_label.size.x) <= 2, "HUD notice '%s' fits 2 lines" % ln.left(30))
	hud.queue_free()
	# --- storm banner with the longest real-event line
	var longest_real := ""
	for slot in Config.donki:
		var s := Config.storm_label(slot)
		if s.length() > longest_real.length():
			longest_real = s
	var sw = load("res://scripts/storm_warning.gd").new()
	add_child(sw)
	await get_tree().process_frame
	sw.real_label.text = longest_real
	report(lines_needed(sw.real_label, sw.real_label.size.x) <= 2, "storm real-event line '%s' in <= 2 lines" % longest_real)
	sw.count_label.text = "%s 9:99" % Text.t("ui.storm_countdown")
	report(text_w(sw.count_label) <= sw.count_label.size.x, "storm countdown %.0f of %.0f px" % [text_w(sw.count_label), sw.count_label.size.x])
	sw.title_label.text = "%s  -  %s" % [Text.t("ui.storm_incoming"), Text.t("storm_names.medium")]
	report(text_w(sw.title_label) <= sw.title_label.size.x, "storm title %.0f of %.0f px" % [text_w(sw.title_label), sw.title_label.size.x])
	sw.queue_free()
	# --- habitat menu rows
	GameState.new_game()
	GameState.day = 5
	var hm = load("res://scenes/HabitatMenu.tscn").instantiate()
	hm.outpost = self
	add_child(hm)
	await get_tree().process_frame
	for r in hm.rows:
		var lbl: Label = r["label"]
		var sub: Label = r["sub"]
		var room: float = (hm.menu_width - 28.0 - 38.0) * 2.0 - 16.0
		report(text_w(lbl) <= room, "habitat menu '%s' %.0f of %.0f px" % [lbl.text, text_w(lbl), room])
		report(text_w(sub) <= room, "habitat menu sub '%s' %.0f of %.0f px" % [sub.text, text_w(sub), room])
	hm.close_modal()
	# --- slider panel
	var sp = load("res://scenes/SliderPanel.tscn").instantiate()
	add_child(sp)
	await get_tree().process_frame
	for i in 4:
		var rl: String = Text.t(sp.ROW_TEXT[i])
		var probe := UIKit.label(rl, 8)
		add_child(probe)
		report(text_w(probe) <= (sp.track_x - 44.0) * 2.0, "slider row '%s' %.0f of %.0f px" % [rl, text_w(probe), (sp.track_x - 44.0) * 2.0])
		probe.queue_free()
	report(text_w(sp.hours_l, "Base pack: 99 h left") <= (300.0 - 170.0) * 2.0, "slider hours line (worst case) fits")
	sp.close_modal()
	# --- Judge buttons
	var jp = load("res://scripts/judge_panel.gd").new()
	jp.from_title = true
	add_child(jp)
	await get_tree().process_frame
	for b in jp.find_children("*", "Button", true, false):
		var w: float = b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		report(w <= b.size.x - 8.0, "judge button '%s' %.0f of %.0f px" % [b.text, w, b.size.x - 8.0])
	jp.close_modal()
	print("ui_check FAILS: ", fails)
	get_tree().quit(1 if fails > 0 else 0)
