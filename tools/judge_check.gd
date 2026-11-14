extends Node
# Headless Judge panel check:  godot --headless --path . res://tools/judge_check.tscn
# For EVERY panel button, in each host scene (Title, Outpost, Mission): the real mouse hits the button (nothing swallows
# clicks) and button.pressed.emit() has the expected effect. Prints a table.
var fails := 0
var rows: Array = []
var host_scene: Node = null

func record(host: String, button: String, ok: bool, note: String) -> void:
	if not ok:
		fails += 1
	rows.append("%-8s %-12s %-5s %s" % [host, button, "ok" if ok else "FAIL", note])

func wait_scene(scene_name: String, timeout_s: float) -> bool:
	var t := 0.0
	while t < timeout_s:
		var cs := get_tree().current_scene
		if cs != null and cs.name == scene_name:
			return true
		await get_tree().process_frame
		t += get_process_delta_time() / maxf(Engine.time_scale, 0.001)
	return false

func frames(n: int = 3) -> void:
	for i in n:
		await get_tree().process_frame

func fresh(host: String, day: int = 3) -> Node:
	if host_scene != null and is_instance_valid(host_scene):
		host_scene.queue_free()
	if Judge.panel != null and is_instance_valid(Judge.panel):
		Judge.panel.queue_free()
	GameState.new_game()
	GameState.auto_endings = false
	GameState.judge_mode = true
	GameState.day = day
	GameState._start_day(false)
	GameState.mission_kind = "rock"
	GameState.card_queue.clear()
	Engine.time_scale = 4.0
	host_scene = load("res://scenes/%s.tscn" % host).instantiate()
	add_child(host_scene)
	return host_scene

func open_panel(host: String) -> Node:
	await frames(3)
	Judge.open_panel(host == "Title")
	await frames(3)
	return Judge.panel

func find_button(panel: Node, text: String) -> Button:
	for b in panel.find_children("*", "Button", true, false):
		if b.text == text:
			return b
	return null

func _ready() -> void:
	await get_tree().process_frame
	for host in ["Title", "Outpost", "Mission"]:
		await check_host(host)
	# the J key must open (and close) the panel inside the Outpost and inside a mission, even with an info card open
	for host in ["Outpost", "Mission"]:
		fresh(host, 8)
		await frames(3)
		if host == "Outpost":
			var card = load("res://scenes/InfoCard.tscn").instantiate()
			card.keys = ["ice_drink"]
			host_scene.add_child(card)
			await frames(30)
		var ej := InputEventKey.new()
		ej.keycode = KEY_J
		ej.physical_keycode = KEY_J
		ej.pressed = true
		get_viewport().push_input(ej)
		await frames(3)
		var opened: bool = Judge.panel != null and is_instance_valid(Judge.panel) and not Judge.panel.is_queued_for_deletion()
		record(host, "J key", opened, "panel opened by the J key" if opened else "panel did NOT open")
		if opened:
			Judge.panel.close_modal()
	print("host     button       res   note")
	for r in rows:
		print(r)
	print("judge_check FAILS: ", fails)
	Engine.time_scale = 1.0
	get_tree().quit(1 if fails > 0 else 0)

# One button at a time, always from a fresh host scene.
func check_host(host: String) -> void:
	var names := ["<", ">", "Jump", "Storm S", "Storm M", "Storm L", "Storm X", "Shadow", "Sunrise", "Cargo", "Mission", "Refill", "Speed x4",
		Text.t("ui.judge_preset_storm_mission"), Text.t("ui.judge_preset_shadow"), Text.t("ui.judge_preset_big_storm"), "Close"]
	if host == "Title":
		names.append("Start game")
	for nm in names:
		while Scenes.busy or Scenes.pending != "":          # let a running scene fade finish first
			await get_tree().process_frame
		fresh(host)
		var panel = await open_panel(host)
		var b := find_button(panel, nm)
		if b == null:
			record(host, nm, false, "button not found")
			continue
		# 1. the real mouse must reach this button (no full-screen Control swallowing clicks)
		var center: Vector2 = b.get_global_rect().get_center()
		var ev := InputEventMouseMotion.new()
		ev.position = center
		ev.global_position = center
		get_viewport().push_input(ev)
		await frames(2)
		var hov := get_viewport().gui_get_hovered_control()
		var reach := hov == b
		# 2. press it and assert the effect
		var note := await press_and_assert(host, nm, b, panel)
		record(host, nm, note == "" and reach, ("mouse blocked by " + (hov.name if hov else "nothing") + " " if not reach else "") + note)
	if host_scene != null and is_instance_valid(host_scene):
		host_scene.queue_free()
	await frames(2)

# Returns "" when the effect is right, otherwise a message.
func press_and_assert(host: String, nm: String, b: Button, panel: Node) -> String:
	var slider: HSlider = panel.day_slider
	match nm:
		"Jump":
			slider.value = 8
			b.pressed.emit()
			await frames(2)
			var snap: Dictionary = Config.load_json("res://data/day_snapshots.json")["8"]
			if GameState.day != 8 or absf(GameState.water - float(snap["water"])) > 0.01 or GameState.meals_left() != int(snap["rations"]) + int(snap["radish_meals"]):
				return "day %d water %.1f (want 8 / %.1f)" % [GameState.day, GameState.water, snap["water"]]
			if not await wait_scene("Outpost", 5.0):
				return "did not open the Outpost"
		"<", ">":
			slider.value = 10
			b.pressed.emit()
			if int(slider.value) != (9 if nm == "<" else 11):
				return "slider is %d" % int(slider.value)
		"Storm S", "Storm M", "Storm L", "Storm X":
			b.pressed.emit()
			await frames(2)
			var want: String = {"Storm S": "small", "Storm M": "medium", "Storm L": "large", "Storm X": "finale"}[nm]
			if GameState.storm_state != "warning" or GameState.storm_size != want:
				return "storm state %s size %s" % [GameState.storm_state, GameState.storm_size]
		"Shadow":
			b.pressed.emit()
			await frames(2)
			if not GameState.in_shadow:
				return "shadow not on"
		"Sunrise":
			GameState.start_shadow()
			b.pressed.emit()
			await frames(2)
			if GameState.in_shadow:
				return "shadow still on"
		"Cargo":
			var d0: float = GameState.dust[0]
			b.pressed.emit()
			await frames(2)
			if GameState.cargo_waiting.is_empty() or GameState.dust[0] <= d0:
				return "no cargo / dust"
		"Mission":
			b.pressed.emit()
			if not await wait_scene("Mission", 5.0):
				return "Mission scene did not open"
		"Refill":
			GameState.health = 20.0
			GameState.water = 5.0
			GameState.oxygen_h = 5.0
			GameState.base_pack = 5.0
			GameState.spare_pack = 5.0
			b.pressed.emit()
			await frames(2)
			if GameState.health < 100.0 or GameState.water < 40.0 or GameState.oxygen_h < 48.0 or GameState.base_pack < 100.0 or GameState.spare_pack < 100.0:
				return "not refilled"
		"Speed x4":
			b.pressed.emit()
			await frames(2)
			var first := GameState.time_scale
			b.pressed.emit()
			await frames(2)
			if first != 4.0 or GameState.time_scale != 1.0:
				return "time scale %s then %s" % [first, GameState.time_scale]
		"Close":
			b.pressed.emit()
			await frames(3)
			if Judge.panel != null and is_instance_valid(Judge.panel) and not Judge.panel.is_queued_for_deletion():
				return "panel still open"
		"Start game":
			b.pressed.emit()
			if not await wait_scene("Outpost", 5.0):
				return "did not start the game"
		_:
			# presets
			b.pressed.emit()
			await frames(2)
			if nm == Text.t("ui.judge_preset_storm_mission"):
				if GameState.day != 8 or not await wait_scene("Mission", 5.0) or GameState.mission_kind != "ice":
					return "day %d kind %s" % [GameState.day, GameState.mission_kind]
			elif nm == Text.t("ui.judge_preset_shadow"):
				if GameState.day != 11 or not GameState.in_shadow or not await wait_scene("Outpost", 5.0):
					return "day %d shadow %s" % [GameState.day, GameState.in_shadow]
			else:
				if GameState.day != 24 or not await wait_scene("Mission", 5.0) or GameState.mission_kind != "ice":
					return "day %d kind %s" % [GameState.day, GameState.mission_kind]
	# every button must have shown a toast
	if nm not in ["<", ">", "Close"] and Judge.last_toast == "":
		return "no toast shown"
	return ""
