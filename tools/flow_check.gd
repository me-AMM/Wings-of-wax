# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Headless flow check:  godot --headless --path . res://tools/flow_check.tscn
# 1. Storm rules for the day 8 / 20 / 24 mission storms: the result waits for the storm; sheltered in time vs too late.
# 2. Finale (day 32) success path: crew lander hidden before, storm during the mission, walk to the shelter ->
#    crew lander arrives -> Extraction -> EndingSuccess.
# 3. Finale failure path: not in the shelter when the countdown ends -> EndingFailed.
var fails := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func wait_scene(scene_name: String, timeout_s: float) -> bool:
	var t := 0.0
	while t < timeout_s:
		var cs := get_tree().current_scene
		if cs != null and cs.name == scene_name:
			return true
		await get_tree().process_frame
		t += get_process_delta_time() / maxf(Engine.time_scale, 0.001)
	return false

func _ready() -> void:
	Engine.time_scale = 4.0
	await get_tree().process_frame
	# ---------------- storm rules (GameState only)
	for case in [[8, "ice", "medium"], [20, "rock", "small"], [24, "ice", "large"]]:
		for in_time in [true, false]:
			await storm_case(case[0], case[1], case[2], in_time)
	# ---------------- damage in the Outpost and in a mission, every storm size
	for size in ["small", "medium", "large"]:
		for host in ["Outpost", "Mission"]:
			await damage_case(size, host)
	await shelter_lock_case()
	await audio_case()
	await large_fatal_case()
	await retry_case(false)
	await retry_case(true)
	# ---------------- finale paths (scenes)
	await finale_case(true)
	await finale_case(false)
	print("flow_check FAILS: ", fails)
	Engine.time_scale = 1.0
	get_tree().quit(1 if fails > 0 else 0)

func storm_case(d: int, kind: String, size: String, in_time: bool) -> void:
	GameState.new_game()
	GameState.auto_endings = false
	Judge.jump_to_day(d)
	GameState.advance(1.2)
	GameState.collect_cargo()
	var st: Dictionary = GameState.today()["storm"]
	check(st != null and st["size"] == size and st["in_mission"], "day %d has a %s storm during the mission" % [d, size])
	GameState.start_storm_warning(size, st["event"], -1.0, true)
	var secs: float = GameState.storm_total_h * 10.0
	var want: float = GameState.storm_warning_seconds(size, true)
	check(absf(secs - want) < 0.01 and want >= 20.0, "day %d warning in a mission = %.0f s (x0.4, min 20)" % [d, secs])
	var r0 := GameState.pending_research.size()
	var hp0 := GameState.health
	GameState.submit_mission(kind, true)
	check(not GameState.pending_mission.is_empty() and GameState.pending_research.size() == r0 and GameState.storm_state == "warning",
		"day %d: leaving the mission does NOT clear the storm, result is pending" % d)
	if in_time:
		GameState.enter_shelter()
	GameState.advance(GameState.storm_total_h + 0.5)
	var tag := "day %d %s %s" % [d, size, "sheltered" if in_time else "too late"]
	check(GameState.storm_state == "none" and GameState.pending_mission.is_empty(), tag + ": storm resolved, pending applied")
	if size == "large":
		if in_time:
			check(GameState.pending_research.size() == r0 + 1 and GameState.health <= hp0, tag + ": samples kept, small damage only")
		else:
			check(GameState.pending_research.size() == r0 and GameState.missions_failed == 1, tag + ": mission failed, samples lost")
			check(GameState.health == 0.0 and GameState.game_over and GameState.game_result == "failed" and GameState.fail_reason == "storm", tag + ": FATAL (Health %.0f -> 0, failed ending)" % hp0)
	else:
		check(GameState.pending_research.size() == r0 + 1, tag + ": samples kept")
		if in_time:
			check(GameState.health >= hp0 - 0.01, tag + ": no damage")
		else:
			check(GameState.health < hp0 - 1.0, tag + ": damage taken (%.0f -> %.0f)" % [hp0, GameState.health])

func finale_case(sheltered: bool) -> void:
	var tag := "finale " + ("SUCCESS path" if sheltered else "FAILURE path")
	GameState.new_game()
	GameState.auto_endings = true
	Judge.jump_to_day(32)
	GameState.mission_kind = "finale"
	get_tree().change_scene_to_file("res://scenes/Outpost.tscn")
	await wait_scene("Outpost", 5.0)
	await get_tree().process_frame
	var o := get_tree().current_scene
	var cl: Node2D = o.get_node("World/CrewLander")
	check(not cl.visible and cl.get_node("Footprint").collision_layer == 0, tag + ": crew lander hidden (and not solid) before the mission")
	GameState.start_storm_warning("finale", "finale", -1.0, true)
	GameState.submit_mission("finale", true)
	check(GameState.storm_state == "warning" and not GameState.pending_mission.is_empty(), tag + ": storm still running after the mission")
	if sheltered:
		o.do_shelter()                                   # walk to the shelter and enter it
		check(await wait_scene("Extraction", 25.0), tag + ": crew lander arrives, then the Extraction scene")
		check(GameState.finale_cleared and GameState.pending_mission.is_empty(), tag + ": finale cleared, mission result applied")
		get_tree().current_scene._finish()                # skip the animation
		check(await wait_scene("EndingSuccess", 10.0), tag + ": reaches EndingSuccess")
	else:
		GameState.advance(GameState.storm_total_h + 0.3)  # countdown ends outside the shelter
		check(await wait_scene("EndingFailed", 10.0), tag + ": reaches EndingFailed")
		check(not GameState.finale_cleared, tag + ": no crew lander")

func damage_case(size: String, host: String) -> void:
	GameState.new_game()
	GameState.auto_endings = false
	var scene: Node = load("res://scenes/%s.tscn" % host).instantiate()
	add_child(scene)
	for i in 3:
		await get_tree().process_frame
	GameState.in_shelter = false
	GameState.start_storm_warning(size, "small1", -1.0, host == "Mission")
	var hp0 := GameState.health
	GameState.advance(GameState.storm_total_h + 1.6)       # countdown, then the damage over time
	var limit: float = {"small": 0.75, "medium": 0.6, "large": 0.62}[size]
	if size == "large":
		check(GameState.health == 0.0 and GameState.game_over, "large storm in the %s outside the shelter is FATAL (Health %.0f -> %.0f)" % [host, hp0, GameState.health])
	else:
		check(GameState.health < hp0 * limit, "%s storm in the %s outside the shelter: Health %.0f -> %.0f" % [size, host, hp0, GameState.health])
	GameState.modal_count = 0
	scene.queue_free()
	await get_tree().process_frame

func shelter_lock_case() -> void:
	GameState.new_game()
	GameState.auto_endings = false
	Judge.jump_to_day(8)
	var scene: Node = load("res://scenes/Outpost.tscn").instantiate()
	add_child(scene)
	for i in 3:
		await get_tree().process_frame
	var sh: Interactable = scene.get_node("World/Shelter")
	check(not sh.is_open(), "shelter is LOCKED when no storm is active")
	var h0 := GameState.hour
	var d0 := GameState.day
	await scene.do_shelter()
	check(GameState.hour == h0 and GameState.day == d0 and not GameState.slept_today, "entering a locked shelter does nothing (no day skip, no free sleep)")
	check(not GameState.enter_shelter(), "GameState.enter_shelter() refuses without a storm")
	Judge.trigger_storm("small")
	check(sh.is_open(), "shelter OPENS during a storm warning (Judge storm button)")
	scene.queue_free()
	await get_tree().process_frame

# The storm alarm plays and the ambience goes silent during a storm.
func audio_case() -> void:
	GameState.new_game()
	GameState.auto_endings = false
	var scene: Node = load("res://scenes/Outpost.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	Audio.ambience({"suit_breath": 1.0})
	for i in 90:
		await get_tree().process_frame
	var before: float = Audio._amb["suit_breath"]["vol"] if Audio._amb.has("suit_breath") else -1.0
	check(before > 0.3, "ambience is audible before a storm (suit_breath volume %.2f)" % before)
	GameState.start_storm_warning("small", "small1")
	for i in 120:
		await get_tree().process_frame
	var during: float = Audio._amb["suit_breath"]["vol"] if Audio._amb.has("suit_breath") else -1.0
	check(during < 0.05, "ambience is SILENT during the storm warning (volume %.2f)" % during)
	check(Audio._loops.has("storm_warning"), "the storm alarm loop is playing during the warning")
	scene.queue_free()
	await get_tree().process_frame

# Large storm: unsheltered = fatal and EndingFailed with the storm text; sheltered = -5 and the run continues.
func large_fatal_case() -> void:
	GameState.new_game()
	GameState.auto_endings = true
	Judge.jump_to_day(24)
	get_tree().change_scene_to_file("res://scenes/Outpost.tscn")
	await wait_scene("Outpost", 5.0)
	GameState.start_storm_warning("large", "large1")
	GameState.advance(GameState.storm_total_h + 0.2)
	check(await wait_scene("EndingFailed", 10.0), "large storm outside the shelter reaches EndingFailed")
	check(GameState.fail_reason == "storm" and GameState.health == 0.0, "  ... reason 'storm', Health 0")
	GameState.new_game()
	GameState.auto_endings = true
	Judge.jump_to_day(24)
	GameState.start_storm_warning("large", "large1")
	GameState.enter_shelter()
	var hp := GameState.health
	GameState.advance(GameState.storm_total_h + 0.2)
	check(not GameState.game_over and GameState.health >= hp - 5.01 and GameState.health > 0.0, "large storm sheltered: tiny damage (-5), the run continues")

# Die, then "Retry day N": the 06:00 state of that day comes back and the save file is untouched (also in judge mode).
func retry_case(judge: bool) -> void:
	var tag := "judge mode" if judge else "normal day"
	Save.path = "user://save_test.json"
	if FileAccess.file_exists(Save.path):
		DirAccess.remove_absolute(Save.path)
	GameState.new_game()
	GameState.auto_endings = true
	GameState.game_started = true
	GameState.day = 6
	GameState._start_day(false)
	check(Save.write(), "%s: a save file exists before the death" % tag)
	GameState.day = 3
	GameState._start_day(false)                    # a new day: the 06:00 autosave (normal mode)
	if judge:
		Judge.jump_to_day(5)                       # judge mode on from the jump: nothing is saved
	var h0 := FileAccess.get_md5(Save.path)
	var day0: int = GameState.day
	var state0 := JSON.stringify(GameState.save_dict(), "", true)
	get_tree().change_scene_to_file("res://scenes/Outpost.tscn")
	await wait_scene("Outpost", 5.0)
	GameState.eat("ration")                       # things done during the day ...
	GameState.drink()
	GameState.dust = [50.0, 50.0, 50.0, 50.0]
	GameState.advance(6.0)
	GameState.damage(1000.0, "health")             # ... and then the run ends
	check(await wait_scene("EndingFailed", 10.0), "%s: death reaches EndingFailed" % tag)
	var ending := get_tree().current_scene
	check(ending.retry_btn != null and ending.retry_btn.text == Text.t("ui.retry_day") % day0, "%s: the button says 'Retry day %d'" % [tag, day0])
	ending.retry_btn.pressed.emit()
	check(await wait_scene("Outpost", 10.0), "%s: Retry opens the Outpost" % tag)
	var back := JSON.stringify(GameState.save_dict(), "", true)
	var dk := ""
	var da: Dictionary = JSON.parse_string(state0)
	var db: Dictionary = JSON.parse_string(back)
	for k in da:
		if k not in ["hour", "total_hours"] and str(da[k]) != str(db.get(k)):      # (the clock has run a few frames since)
			dk += " " + str(k)
	check(GameState.day == day0 and GameState.hour < 6.6 and not GameState.game_over and dk == "", "%s: day %d starts again at 06:00 with the day-start state (everything done is undone)%s" % [tag, day0, " DIFF:" + dk if dk != "" else ""])
	check(GameState.judge_mode == judge, "%s: judge mode kept as it was" % tag)
	check(FileAccess.get_md5(Save.path) == h0, "%s: the save file is unchanged by the death and the retry" % tag)
	DirAccess.remove_absolute(Save.path)
	Save.path = "user://save.json"
