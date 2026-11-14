extends SceneTree
# Plays a scripted "good player" through GameState (no scenes) and compares each day with docs/03.
# Run:  godot --headless --path . -s tools/sim_check.gd
# Also runs the docs/02 test cases (shadow check, dust effects) and writes data/day_snapshots.json.

const GYM_DAYS := [2, 5, 7, 14, 18, 22, 26, 29, 31]
const SHADOW_DAYS := [11, 12, 25, 26]
var gs: Node
var snaps := {}          # day -> state at the START of that day (Judge day jump)
var report: Array = []
var fails := 0

func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.event.connect(_on_event)
	test_shadow()
	test_dust()
	play_full_game()
	print_report()
	var f := FileAccess.open("res://data/day_snapshots.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(snaps))
	f.close()
	print("day_snapshots.json written (", snaps.size(), " days). FAILS: ", fails)
	quit(1 if fails > 0 else 0)

func _on_event(name: String, data: Dictionary) -> void:
	if name == "day_start" and recording:
		snaps[int(data["day"])] = gs.to_dict()
	elif name == "day_end" and recording:
		var d: Dictionary = gs.today()
		var e: Dictionary = d["expect"]
		var dm: int = gs.meals_left() - int(e["meals"])
		var dw: float = gs.water - float(e["water"])
		var dr: float = gs.research - float(e["research"])
		var bad: bool = absi(dm) > 1 or absf(dw) > 0.3 or absf(dr) > 2.0
		if bad:
			fails += 1
		report.append("day %2d %s meals %d (%+d) water %.1f (%+.1f) research %.1f (%+.1f) | o2 %.0f dust %.0f packs %.0f/%.0f hp %.0f %s" % [
			gs.day, "BAD" if bad else "ok ", gs.meals_left(), dm, gs.water, dw, gs.research, dr,
			gs.oxygen_h, gs.avg_dust(), gs.base_pack, gs.spare_pack, gs.health, "BLACKOUT" if gs.blackout else ""])

var recording := false

# ------------------------------------------------------------------ test cases from docs/02
func test_shadow() -> void:
	# [life, food, science, watch] -> expected pack points left (sum of both packs, in %) and blackout hour
	var cases := [
		{"name": "all low", "s": [0, 0, 0, 0], "left": 60.0, "blackout": false},
		{"name": "life medium, rest low", "s": [1, 0, 0, 0], "left": 20.0, "blackout": false},
		{"name": "all medium", "s": [1, 1, 1, 1], "left": 0.0, "blackout": true},
	]
	for c in cases:
		gs.new_game()
		gs.day = 11
		gs._start_day()
		gs.sliders = c["s"].duplicate()
		var blackout_at := -1.0
		var t := 0.0
		while t < 48.0:
			gs.advance(0.25)
			t += 0.25
			if gs.base_pack <= 0.0 and gs.spare_pack > 0.0:
				gs.swap_packs()
			if gs.blackout and blackout_at < 0.0:
				blackout_at = t
		var left: float = gs.base_pack + gs.spare_pack
		var ok: bool = absf(left - c["left"]) < 2.0 and (blackout_at > 0.0) == c["blackout"]
		if c["blackout"]:
			ok = ok and absf(blackout_at - 40.0) < 1.0   # about 8 h before sunrise
		if not ok:
			fails += 1
		print("SHADOW ", c["name"], ": packs left ", snappedf(left, 0.1), " (want ", c["left"], ") blackout at h ", blackout_at, " ", "ok" if ok else "FAIL")

func test_dust() -> void:
	# medium sliders, 24 h: [dust %, pack to read, start value, expected change]
	var cases := [[0.0, "spare", 0.0, 80.0], [25.0, "spare", 0.0, 30.0], [50.0, "base", 100.0, -20.0], [75.0, "base", 100.0, -70.0]]
	for c in cases:
		gs.new_game()
		gs.sliders = [1, 1, 1, 1]
		gs.dust = [c[0], c[0], c[0], c[0]]
		gs.base_pack = 100.0
		gs.spare_pack = 0.0
		gs.advance(24.0)
		var got: float = (gs.spare_pack if c[1] == "spare" else gs.base_pack - 100.0)
		var ok: bool = absf(got - c[3]) < 2.0
		if not ok:
			fails += 1
		print("DUST ", c[0], "%: ", c[1], " pack change ", snappedf(got, 0.1), " (want ", c[3], ") ", "ok" if ok else "FAIL")

# ------------------------------------------------------------------ the good player
func sliders_for(d: int) -> Array:
	var w := 0 if d < 5 else (2 if d >= 23 else 1)
	if d in SHADOW_DAYS:
		return [0, 1, 0, 0]
	if d in [13, 14, 27, 28]:
		return [2, 1, 1, w]
	return [1, 1, 1, w]

func play_full_game() -> void:
	gs.new_game()
	recording = true
	snaps[1] = gs.to_dict()
	var guard := 0
	while not gs.game_over and guard < 40:
		guard += 1
		play_day(gs.day)
		if gs.finale_cleared:                # day 32: the clock stops after the finale storm
			gs._end_day()
	recording = false

func play_day(d: int) -> void:
	var s := sliders_for(d)
	for i in 4:
		gs.set_slider(i, s[i])
	# swap so the fuller pack runs the base and the emptier one charges
	if gs.spare_pack > gs.base_pack + 5.0:
		gs.swap_packs()
	# clean panels (solar field opens on day 3), not in the dark
	if d >= 3 and not gs.in_shadow and gs.avg_dust() > 0.0:
		for i in 4:
			gs.clean_panel(i)
		gs.advance(1.0)
	if gs.hour < 7.01:
		gs.advance(7.01 - gs.hour)
	gs.collect_cargo()
	if gs.pending_research.size() > 0 and d >= 4:
		gs.process_samples()
	# food and water
	gs.eat("radish" if gs.radish_meals > 0 else "ration")
	gs.drink()
	if d >= 2:
		if gs.tray_ready:
			gs.harvest_radish()
		elif not gs.tray_planted:
			gs.plant_radish()
		gs.water_radish()
	if d in GYM_DAYS:
		gs.gym()
	# mission
	var day_data: Dictionary = gs.today()
	var kind = day_data["mission"]
	var storm = day_data["storm"]
	if kind != null:
		if gs.hour < 8.0:
			gs.advance(8.0 - gs.hour)
		gs.advance(gs.cfg["missions"]["game_hours_used"])
		if storm != null and storm["in_mission"]:
			gs.start_storm_warning(storm["size"], storm["event"])
		gs.finish_mission(kind, true)
		if storm == null or not storm["in_mission"]:
			gs.process_samples()
	if storm != null:
		var wait := 0
		while gs.storm_state != "warning" and gs.hour < 29.0 and wait < 200:    # the shelter opens only during a storm
			gs.advance(0.25)
			wait += 1
		gs.shelter_until_day_end()
		return
	if gs.hour < 22.0:
		gs.advance(22.0 - gs.hour)
	gs.sleep()

func print_report() -> void:
	for line in report:
		print(line)
