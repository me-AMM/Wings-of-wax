# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Save system check:  godot --headless --path . res://tools/save_check.tscn   (uses user://save_test.json, never the real save)
#  1. a good player to day 12, save, rebuild GameState from the file: every field equal
#  2. a damaged file (garbage, cut off, wrong checksum, a judge state) fails gracefully: no crash, nothing changed
#  3. round trips on days 1, 11 (shadow) and 24
#  4. judge mode never touches the save: the file hash stays the same through judge jumps, storms and a death
var fails := 0
const TEST_PATH := "user://save_test.json"

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

# numbers compare as numbers (JSON turns ints into floats), dictionaries and arrays recursively
func same(a, b) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) < 0.0001
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for k in a:
			var kb = k
			if not b.has(kb):
				kb = str(k) if not b.has(str(k)) else k
			if not b.has(kb) or not same(a[k], b[kb]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not same(a[i], b[i]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b

func diff_keys(a: Dictionary, b: Dictionary) -> String:
	var out: Array = []
	for k in a:
		if not b.has(k) or not same(a[k], b[k]):
			out.append(str(k))
	return ", ".join(out)

func fresh_game() -> void:
	GameState.new_game()
	GameState.auto_endings = false
	GameState.game_started = true

# a simple good player for one day (no scenes)
func play_day() -> void:
	var d: int = GameState.day
	if d == 11:                                      # "charge both packs" before the dark
		GameState.base_pack = 100.0
		GameState.spare_pack = 100.0
	GameState.set_slider(0, 0 if GameState.in_shadow else 1)         # shadow plan: life support low, science low
	GameState.set_slider(2, 0 if GameState.in_shadow else 1)
	GameState.set_slider(3, 1 if d >= 5 and not GameState.in_shadow else 0)
	if GameState.spare_pack > GameState.base_pack + 5.0:
		GameState.swap_packs()
	if GameState.hour < 7.01:
		GameState.advance(7.01 - GameState.hour)
	GameState.collect_cargo()
	GameState.eat("radish" if GameState.radish_meals > 0 else "ration")
	GameState.drink()
	if d >= 2:
		if GameState.tray_ready:
			GameState.harvest_radish()
		elif not GameState.tray_planted:
			GameState.plant_radish()
		GameState.water_radish()
	if d in [2, 5, 7, 9, 11]:
		GameState.gym()
	var st = GameState.today()["storm"]
	if st != null and not st["in_mission"]:
		var wait := 0
		while GameState.storm_state != "warning" and GameState.hour < 29.0 and wait < 200:
			GameState.advance(0.25)
			wait += 1
		GameState.shelter_until_day_end()
		return
	if GameState.hour < 22.0:
		GameState.advance(22.0 - GameState.hour)
	var why := GameState.sleep()
	if why != "":
		print("DBG sleep refused on day ", GameState.day, ": ", why, " blackout=", GameState.blackout, " base=", GameState.base_pack, " hour=", GameState.hour)

func file_md5() -> String:
	return FileAccess.get_md5(TEST_PATH) if FileAccess.file_exists(TEST_PATH) else "none"

func write_text(txt: String) -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(txt)
	f.close()

func _ready() -> void:
	await get_tree().process_frame
	Save.path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	# ---------- 1. good player to day 12
	fresh_game()
	for i in 11:
		play_day()
	check(GameState.day == 12 and not GameState.game_over, "good player reached day %d (health %.0f, research %.1f, hour %.1f)" % [GameState.day, GameState.health, GameState.research, GameState.hour])
	var before: Dictionary = GameState.save_dict()
	check(Save.write(), "Save.write() works on day 12")
	var sm: Dictionary = Save.summary()
	check(sm.get("day", 0) == 12, "summary says day %s" % str(sm.get("day")))
	GameState.new_game()                                   # throw the state away ...
	check(Save.load_game(), "Save.load_game() succeeds")   # ... and rebuild it from the file
	var after: Dictionary = GameState.save_dict()
	check(same(before, after), "every field is equal after the round trip" + ("" if same(before, after) else " (different: " + diff_keys(before, after) + ")"))
	check(GameState.day == 12 and typeof(GameState.day) == TYPE_INT and GameState.judge_mode == false, "day is an int again and judge mode is off")
	# ---------- 2. damaged files
	var good_text := FileAccess.get_file_as_string(TEST_PATH)
	for c in [["garbage", "this is not json {{{"], ["cut off", good_text.substr(0, good_text.length() / 2)], ["empty", ""],
			["wrong checksum", good_text.replace("\"checksum\":\"", "\"checksum\":\"0")], ["edited value", good_text.replace("\"rations\":", "\"rations\":9")]]:
		write_text(c[1])
		GameState.new_game()
		var day0: int = GameState.day
		var ok := Save.load_game()
		check(not ok and GameState.day == day0 and Save.summary().is_empty(), "damaged file (%s): Load fails gracefully, nothing changed" % c[0])
	DirAccess.remove_absolute(TEST_PATH)
	check(not Save.load_game() and Save.summary().is_empty() and not Save.exists(), "missing file: Load fails gracefully")
	# a judge state inside a valid file is refused
	fresh_game()
	GameState.day = 5
	GameState._start_day(false)
	var jd: Dictionary = GameState.save_dict()
	jd["judge_mode"] = true
	var obj := {"version": 1, "saved_at": 1, "data": jd, "day_start": GameState.day_start_state}
	obj["checksum"] = Save._sum(obj)
	write_text(JSON.stringify(obj, "", true))
	check(not Save.read()["ok"], "a file holding a judge state is never loaded")
	# ---------- 3. round trips on days 1, 11 (shadow) and 24
	for d in [1, 11, 24]:
		fresh_game()
		GameState.day = d
		GameState._start_day(false)
		GameState.game_started = true
		GameState.dust = [10.0, 25.0, 50.0, 75.0]
		GameState.base_pack = 63.5
		GameState.spare_pack = 12.25
		GameState.set_slider(0, 2)
		GameState.set_slider(2, 0)
		GameState.research = 42.5
		GameState.water = 17.3
		GameState.rations = 7
		GameState.oxygen_h = 31.5
		GameState.pending_research = [15.0, 12.5]
		GameState.cargo_waiting = {"rations": 2, "water": 3}
		GameState.tray_planted = true
		GameState.tray_growth = 4
		GameState.last_gym_day = maxi(1, d - 3)
		GameState.health_cap = 90.0
		GameState.health = 77.0
		GameState.player_name = "Zed"
		GameState.astronaut = "b"
		var b: Dictionary = GameState.save_dict()
		check(Save.write(), "day %d: saved" % d)
		GameState.new_game()
		check(Save.load_game(), "day %d: loaded" % d)
		var a: Dictionary = GameState.save_dict()
		check(same(b, a), "day %d: all fields equal (shadow=%s, name %s/%s)" % [d, str(GameState.in_shadow), GameState.player_name, GameState.astronaut] + ("" if same(b, a) else " DIFF: " + diff_keys(b, a)))
	# ---------- 4. judge mode never touches the save
	fresh_game()
	GameState.day = 6
	GameState._start_day(false)
	check(Save.write(), "a normal save exists for the judge test")
	var h0 := file_md5()
	GameState.judge_mode = true
	check(not Save.write() and not Save.autosave() and not Save._write_obj(GameState.save_dict()), "Save.write, autosave and the inner writer all refuse in judge mode")
	for d in [4, 8, 24, 11, 32]:
		Judge.jump_to_day(d)
		GameState.advance(2.0)
	Judge.trigger_storm("large")
	GameState.advance(GameState.storm_total_h + 0.5)           # unsheltered large storm: fatal
	Judge.land_cargo()
	Judge.refill_all()
	GameState.day = 9
	GameState._start_day(false)                                # a day start event
	GameState.damage(1000.0, "storm")                          # death in judge mode
	check(GameState.game_over and GameState.judge_mode, "died in judge mode (judge mode stays on)")
	check(file_md5() == h0, "the save file hash is unchanged after jumps, storms and a death in judge mode")
	GameState.judge_mode = false                               # back to the title
	GameState.new_game()
	check(Save.load_game() and GameState.day == 6 and not GameState.judge_mode, "after judge mode the normal save still loads (day %d)" % GameState.day)
	DirAccess.remove_absolute(TEST_PATH)
	print("save_check FAILS: ", fails)
	get_tree().quit(1 if fails > 0 else 0)
