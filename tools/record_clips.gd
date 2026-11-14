# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Scripted video clips for the 30 s judge video. Tool only: it never changes gameplay.
# One clip per run, recorded with Godot Movie Maker (needs a window, not --headless):
#   godot --path . --write-movie docs/video/clips/NAME.avi --fixed-fps 30 res://tools/record_clips.tscn -- clip=NAME
# tools/record_clips.sh runs every clip, tools/make_video.py converts them and builds the rough cut.
# Video mode is ON (no JUDGE MODE label, no debug overlay); the AI watermark stays on screen.
# Movement uses simulated input (move_* and interact actions), like a player at the keyboard.

var clip := "title"
var walking := Vector2.INF          # current walk target (world position)
var mission: Node = null            # set while walking in a mission (route through the wall gaps)

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("clip="):
			clip = a.substr(5)
	Save.path = "user://record_unused.json"          # never touch a real save
	await get_tree().process_frame
	await call("clip_" + clip)
	release_all()
	get_tree().quit()

# ---------- helpers
func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func go(scene: String) -> Node:
	get_tree().change_scene_to_file(scene)
	for i in 10:
		await get_tree().process_frame
	return get_tree().current_scene

func prep(day: int) -> void:
	GameState.new_game()
	GameState.auto_endings = false
	GameState.game_started = true
	if day > 1:
		Judge.jump_to_day(day)
	GameState.judge_mode = false               # no Judge UI in any frame
	GameState.video_mode = true
	GameState.tutorial_off = day > 1
	GameState.day_intro_pending = false
	GameState.card_queue.clear()
	GameState.cards_seen = ["welcome", "solar_storms", "osdr_gym", "csa_radish"]

func release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "interact"]:
		Input.action_release(a)

func player() -> Node2D:
	var s := get_tree().current_scene
	if s.has_node("World/Player"):
		return s.get_node("World/Player")
	return s.get("player")

# walk with the arrow keys until close to the target (or out of time)
func walk_to(target: Vector2, max_s: float = 6.0) -> void:
	walking = target
	var t := 0.0
	while t < max_s:
		var p := player()
		if p == null:
			break
		var dest := target
		if mission != null and mission.has_method("_via_gap"):
			dest = mission._via_gap(target)
		var d := dest - p.global_position
		if p.global_position.distance_to(target) < 10.0:
			break
		Input.action_release("move_left"); Input.action_release("move_right")
		Input.action_release("move_up"); Input.action_release("move_down")
		if absf(d.x) > 3.0:
			Input.action_press("move_right" if d.x > 0 else "move_left")
		if absf(d.y) > 3.0:
			Input.action_press("move_down" if d.y > 0 else "move_up")
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	release_all()
	walking = Vector2.INF

func tap(action: String, hold: float = 0.08) -> void:
	Input.action_press(action)
	await wait(hold)
	Input.action_release(action)

func hover(b: Control) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = b.get_global_rect().get_center()
	ev.global_position = ev.position
	get_viewport().push_input(ev)

func outpost(day: int, spawn: Vector2) -> Node:
	prep(day)
	GameState.outpost_spawn = spawn
	var o := await go("res://scenes/Outpost.tscn")
	await wait(0.6)
	return o

# ---------- clips
func clip_title() -> void:
	var t := await go("res://scenes/Title.tscn")
	await wait(1.0)
	var buttons: Array = t.find_children("*", "Button", true, false)
	for i in 3:
		for b in buttons:
			if b.is_visible_in_tree():
				hover(b)
				await wait(0.45)
	await wait(1.0)

func clip_story() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets_derived/story_page.png"))
	var layer := CanvasLayer.new()
	get_tree().root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05)
	bg.size = Vector2(640, 360)
	layer.add_child(bg)
	var tr := Sprite2D.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.position = Vector2(320, 180)
	tr.scale = Vector2(0.5, 0.5)                    # the page is 1280x720 = the 640x360 game view at 2x
	layer.add_child(tr)
	var tw := tr.create_tween()
	tw.tween_property(tr, "scale", Vector2(0.56, 0.56), 4.5).set_trans(Tween.TRANS_SINE)
	await wait(4.6)

func clip_chores_eat() -> void:
	var o := await outpost(3, Vector2(640, 520))
	await walk_to(o.get_node("World/Habitat").position + Vector2(0, 30), 3.0)
	await tap("interact")
	await wait(1.0)
	await tap("interact")                            # first row: Eat ration
	await wait(2.0)

func clip_chores_sliders() -> void:
	var o := await outpost(3, Vector2(830, 250))
	var sp = load("res://scenes/SliderPanel.tscn").instantiate()
	o.add_child(sp)
	await wait(0.6)
	var sliders: Array = sp.find_children("*", "HSlider", true, false)
	for s in sliders:
		var tw := create_tween()
		tw.tween_property(s, "value", s.max_value, 1.2)
		await wait(1.3)
	for s in sliders:
		var tw := create_tween()
		tw.tween_property(s, "value", s.min_value, 0.9)
	await wait(2.0)

func clip_chores_panel() -> void:
	prep(5)
	GameState.dust[0] = 75.0
	GameState.outpost_spawn = Vector2(300, 290)
	var o := await go("res://scenes/Outpost.tscn")
	await wait(0.5)
	await walk_to(o.get_node("World/Panel0").position + Vector2(0, 26), 3.0)
	Input.action_press("interact")                   # hold E to clean
	await wait(3.5)
	Input.action_release("interact")
	await wait(1.5)

func clip_chores_pack() -> void:
	prep(6)
	GameState.base_pack = 12.0
	GameState.spare_pack = 100.0
	GameState.outpost_spawn = Vector2(910, 300)
	var o := await go("res://scenes/Outpost.tscn")
	await wait(0.5)
	await walk_to(o.get_node("World/Charger").position + Vector2(0, 26), 3.0)
	Input.action_press("interact")
	await wait(2.5)
	Input.action_release("interact")
	await wait(1.5)

func clip_chores_harvest() -> void:
	prep(10)
	GameState.tray_planted = true
	GameState.tray_ready = true
	GameState.outpost_spawn = Vector2(330, 540)
	var o := await go("res://scenes/Outpost.tscn")
	await wait(0.5)
	await walk_to(o.get_node("World/Tray").position + Vector2(0, 26), 3.0)
	await tap("interact")
	await wait(2.5)

func mission_scene(day: int, kind: String) -> Node:
	prep(day)
	GameState.mission_kind = kind
	var m := await go("res://scenes/Mission.tscn")
	mission = m
	await wait(0.4)
	return m

func clip_mission_rock() -> void:
	var m := await mission_scene(4, "rock")
	for it in m.items:
		if it["type"] == "sample":
			await walk_to(it["pos"], 6.0)
			await tap("interact")
			await wait(0.8)
			break
	await wait(1.0)

func clip_mission_ice() -> void:
	var m := await mission_scene(8, "ice")
	for it in m.items:
		if it["type"] == "ice":
			m.player.position = it["pos"] + Vector2(-50, 0)      # start near the ice
			await walk_to(it["pos"], 3.0)
			await tap("interact")
			break
	# press E whenever the marker is inside the green zone
	var t := 0.0
	while t < 7.0 and m.digging:
		var bar = null
		for c in m.get_children():
			if c.has_method("marker_x"):
				bar = c
		if bar != null and bar.marker_x() > 84.0 and bar.marker_x() < 108.0:
			await tap("interact", 0.05)
			await wait(0.35)
		await get_tree().process_frame
		t += get_process_delta_time()
	await wait(1.2)

func clip_mission_storm() -> void:
	var m := await mission_scene(8, "ice")
	await walk_to(m.player.global_position + Vector2(120, 0), 1.0)
	GameState.start_storm_warning("medium", "medium1", -1.0, true)    # day 8 storm = the real X5.8 flare
	await walk_to(m.player.global_position + Vector2(-60, 40), 4.0)
	await wait(1.0)

func clip_finale() -> void:
	var m := await mission_scene(32, "finale")
	for it in m.items:
		if it["type"] == "stone":
			m.player.position = it["pos"] + Vector2(-90, 0)
			await walk_to(it["pos"], 3.0)
			await tap("interact")
			break
	await wait(0.6)
	await walk_to(m.player.global_position + Vector2(-140, 0), 2.0)
	# back at the outpost: the countdown runs, walk into the shelter
	GameState.submit_mission("finale", true)
	mission = null
	GameState.outpost_spawn = Vector2(1130, 560)
	var o := await go("res://scenes/Outpost.tscn")
	await wait(0.4)
	await walk_to(o.get_node("World/Shelter").position + Vector2(0, 20), 3.0)
	await tap("interact")
	await wait(2.5)

func clip_extraction() -> void:
	prep(32)
	GameState.mission_kind = "finale"
	GameState.outpost_spawn = Vector2(1130, 700)
	var o := await go("res://scenes/Outpost.tscn")
	GameState.start_storm_warning("finale", "finale", -1.0, true)
	GameState.submit_mission("finale", true)
	o.do_shelter()
	var t := 0.0
	while t < 25.0 and get_tree().current_scene.name != "Extraction":
		await wait(0.2)
		t += 0.2
	await wait(5.0)
	GameState.research = 100.0
	if get_tree().current_scene.has_method("_finish"):
		get_tree().current_scene._finish()
	t = 0.0
	while t < 8.0 and get_tree().current_scene.name != "EndingSuccess":
		await wait(0.2)
		t += 0.2
	await wait(5.0)

func clip_x_shadow() -> void:
	var o := await outpost(11, Vector2(560, 470))
	await walk_to(Vector2(760, 470), 2.5)
	await walk_to(Vector2(760, 560), 1.5)
	await wait(0.5)

func clip_x_sun() -> void:
	var o := await outpost(3, Vector2(560, 520))
	var t := 0.0
	while t < 5.0:                                    # the clock races so the polar shadows sweep round
		GameState.hour = fmod(GameState.hour + 0.12, 24.0)
		await get_tree().process_frame
		t += get_process_delta_time()

func clip_x_log() -> void:
	prep(24)
	GameState.storms_survived = ["small1", "medium1", "small2", "small3", "small4", "small5"]
	GameState.log_return = "res://scenes/Title.tscn"
	await go("res://scenes/SpaceWeatherLog.tscn")
	await wait(5.0)

func clip_x_lander() -> void:
	var o := await outpost(7, Vector2(640, 640))
	await wait(0.3)
	Judge.land_cargo()
	await wait(5.0)
