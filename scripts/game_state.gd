extends Node
# GameState autoload: ALL game state and ALL rules (docs/02_RULEBOOK.md). No scenes needed.
# Time is in game hours. A day runs from hour 6.0 to hour 30.0 (30 = 06:00 next day).
# Scenes call actions (eat, drink, ...) and read variables. Events (storm, lander, shadow,
# harvest) are plain functions: the day schedule AND the Judge panel call the same ones.

signal changed                          # anything changed (HUD refresh)
signal event(name: String, data: Dictionary)   # lander, storm_warning, storm_hit, storm_clear, shadow, sunrise, day_start, harvest, game_over ...
signal notice(key: String)              # HUD notice (text key in text.json "notices")
signal card(key: String)                # info card to show (text key in text.json "cards")

const DAY_START := 6.0
const DAY_END := 30.0

var cfg: Dictionary
var days: Array

# ---- state (everything below is saved/restored by to_dict / from_dict) ----
var day := 1
var hour := 6.0
var health := 100.0
var health_cap := 100.0
var rations := 5
var radish_meals := 0
var water := 20.0
var oxygen_h := 48.0
var base_pack := 100.0       # % of the pack plugged into the base
var spare_pack := 100.0      # % of the pack on the charger
var dust := [25.0, 25.0, 25.0, 25.0]
var sliders := [1, 1, 1, 0]  # life, food, science, watch: 0 low, 1 medium, 2 high
var research := 0.0
var pending_research: Array = []   # locked values of missions waiting at the lab
var cargo_waiting: Dictionary = {} # {rations, water} waiting on the pad
var science_hist: Dictionary = {}  # day -> science slider level (for the research average)
var in_shadow := false
var blackout := false
var blackout_hours := 0.0
var tray_planted := false
var tray_growth := 0
var tray_high_days := 0
var tray_ready := false
var ate_today := false
var drank_today := false
var watered_today := false
var slept_today := false
var gym_today := false
var last_sleep_total := -999.0
var last_gym_day := 0
var no_drink_days := 0
var no_meal_days := 0
var missions_done := 0
var missions_failed := 0
var in_shelter := false
var storm_state := "none"          # none / warning
var storm_size := ""
var storm_event := ""
var storm_left_h := 0.0
var storm_total_h := 0.0
var storm_hit_hour := 0.0          # scheduled hit (outside missions), 0 = none
var storm_warned := false
var later_damage_pct := 0.0        # storm damage still to be applied over time
var later_left_h := 0.0
var player_name := "Nova"
var astronaut := "a"               # "a" or "b"
var judge_mode := false
var modal_count := 0               # open overlays (clock pauses while > 0)
var day_intro_pending := true      # cards/notices of this day not shown yet
var mission_done_today := false
var pending_shelter := false       # mission ended during a storm warning: go to the shelter
var outpost_spawn := Vector2(640, 492)  # where the player appears when the Outpost opens
var card_queue: Array = []          # info cards waiting to be shown (survives scene changes)
var mission_kind := ""             # set by the Outpost when a mission starts
var last_modal_close_ms := 0
var auto_endings := false         # true in the real game: finishing goes to the ending screens (off in sim_check)
var game_over := false
var game_result := ""              # "" / "success" / "failed"
var total_hours := 0.0             # hours since day 1, 06:00 (for cooldowns)
var queue: Array = []              # today's timed events: {t, name}

func _ready() -> void:
	cfg = Config.data
	days = Config.days
	new_game()

# ---------------------------------------------------------------- new game / save
func new_game() -> void:
	cfg = Config.data
	days = Config.days
	day = 1
	hour = DAY_START
	health = cfg["health"]["start"]
	health_cap = 100.0
	rations = cfg["food"]["start_rations"]
	radish_meals = 0
	water = cfg["water"]["start_l"]
	oxygen_h = cfg["oxygen"]["start_h"]
	base_pack = 100.0
	spare_pack = 100.0
	var d0: float = cfg["dust"]["start_pct"]
	dust = [d0, d0, d0, d0]
	sliders = cfg["power"]["start_sliders"].duplicate()
	research = 0.0
	pending_research = []
	cargo_waiting = {}
	science_hist = {}
	in_shadow = false
	blackout = false
	blackout_hours = 0.0
	tray_planted = false
	tray_growth = 0
	tray_high_days = 0
	tray_ready = false
	last_sleep_total = -999.0
	last_gym_day = 0
	no_drink_days = 0
	no_meal_days = 0
	missions_done = 0
	missions_failed = 0
	in_shelter = false
	storm_state = "none"
	storm_hit_hour = 0.0
	storm_warned = false
	later_damage_pct = 0.0
	later_left_h = 0.0
	judge_mode = false
	game_over = false
	game_result = ""
	total_hours = 0.0
	_start_day(false)

func to_dict() -> Dictionary:
	var d := {}
	for p in get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and p["name"] not in ["cfg", "days"]:
			var val = get(p["name"])
			d[p["name"]] = val.duplicate(true) if (val is Array or val is Dictionary) else val
	return d

func from_dict(d: Dictionary) -> void:
	for k in d:
		var val = d[k]
		if val is Array or val is Dictionary:
			val = val.duplicate(true)
		set(k, val)
	modal_count = 0
	day_intro_pending = true
	# JSON turns whole numbers into floats: fix the int-like arrays
	sliders = sliders.map(func(x): return int(x))
	rations = int(rations)
	radish_meals = int(radish_meals)
	science_hist = {}
	for k in d.get("science_hist", {}):
		science_hist[int(k)] = int(d["science_hist"][k])
	changed.emit()

# ---------------------------------------------------------------- helpers
func clock_text() -> String:
	var h := fmod(hour, 24.0)
	return "%02d:%02d" % [int(h), int((h - floor(h)) * 60.0)]

func meals_left() -> int:
	return rations + radish_meals

func avg_dust() -> float:
	return (dust[0] + dust[1] + dust[2] + dust[3]) / 4.0

func slider_kw(i: int) -> float:
	var names := ["life", "food", "science", "watch"]
	return cfg["power"]["slider_kw"][names[i]][sliders[i]]

func draw_kw() -> float:
	return slider_kw(0) + slider_kw(1) + slider_kw(2) + slider_kw(3)

func panel_kw() -> float:
	if in_shadow:
		return 0.0
	var out := 0.0
	for dpct in dust:
		out += cfg["power"]["panel_kw"] * (1.0 - dpct / 100.0)
	return out

# Hours the base pack lasts at the current settings (for the HUD "hours left").
func base_hours_left() -> float:
	var net := panel_kw() - draw_kw()
	if net >= 0.0:
		return 99.0
	return base_pack * (cfg["power"]["pack_kwh"] / 100.0) / -net

func today() -> Dictionary:
	return days[clampi(day, 1, days.size()) - 1]

func is_unlocked(building: String) -> bool:
	return day >= cfg["unlock_day"].get(building, 1)

func damage(amount: float) -> void:
	if amount <= 0.0 or game_over:
		return
	health = maxf(0.0, health - amount)
	event.emit("hurt", {"amount": amount})
	if health <= 0.0:
		finish_game("failed")
	changed.emit()

func _goto_ending(result: String) -> void:
	modal_count = 0
	get_tree().change_scene_to_file("res://scenes/EndingSuccess.tscn" if result == "success" else "res://scenes/EndingFailed.tscn")

func heal(amount: float) -> void:
	health = minf(health_cap, health + amount)
	changed.emit()

func finish_game(result: String) -> void:
	if game_over:
		return
	game_over = true
	game_result = result
	clock_running = false
	event.emit("game_over", {"result": result})
	if auto_endings:
		call_deferred("_goto_ending", result)

# ---------------------------------------------------------------- time
# Real-time driver: scenes that want the clock to run add this node to the tree and
# set clock_running = true. 1 game hour = 10 real seconds (config).
var clock_running := false
var time_scale := 1.0     # Judge "speed x4" sets this to 4

func _process(delta: float) -> void:
	if clock_running and not game_over:
		advance(delta * time_scale / cfg["time"]["real_seconds_per_game_hour"])

# Advance the game clock by `hours` (the rules run in steps of at most 0.25 h).
func advance(hours: float) -> void:
	var left := hours
	while left > 0.00001 and not game_over:
		var step := minf(left, 0.25)
		var to_end := DAY_END - hour
		if step > to_end:
			step = to_end
		_step(step)
		left -= step
		if hour >= DAY_END - 0.00001:
			_end_day()
	changed.emit()

func _step(dt: float) -> void:
	hour += dt
	total_hours += dt
	# --- power ---
	var out := panel_kw()
	var draw := draw_kw()
	var kwh_per_pct: float = cfg["power"]["pack_kwh"] / 100.0
	if base_pack <= 0.0 and out < draw:
		if not blackout:
			blackout = true
			blackout_hours = 0.0
			notice.emit("blackout")
			event.emit("blackout", {})
	elif blackout and (base_pack > 0.0 or out >= draw):
		blackout = false
	if blackout:
		blackout_hours += dt
		spare_pack = minf(100.0, spare_pack + out * dt / kwh_per_pct)   # sun still charges the spare pack
	else:
		var net := out - draw
		if net >= 0.0:
			spare_pack = minf(100.0, spare_pack + net * dt / kwh_per_pct)
		else:
			base_pack = maxf(0.0, base_pack + net * dt / kwh_per_pct)
	# --- oxygen ---
	if not (blackout and blackout_hours < cfg["power"]["blackout_o2_hold_hours"]):
		var rate: float = cfg["oxygen"]["change_per_day"][sliders[0]]
		if blackout:
			rate = minf(rate, cfg["oxygen"]["change_per_day"][0])
		oxygen_h = clampf(oxygen_h + rate * dt / 24.0, 0.0, cfg["oxygen"]["max_h"])
	if oxygen_h <= 0.0:
		damage(cfg["oxygen"]["empty_damage_per_hour"] * dt)
	# --- storm over-time damage ---
	if later_left_h > 0.0:
		var chunk := minf(dt, later_left_h)
		damage(health * (later_damage_pct / 100.0) * chunk / later_left_h)
		later_left_h -= chunk
	# --- timed events and storm countdown ---
	_run_queue()
	_storm_tick(dt)

func _run_queue() -> void:
	while queue.size() > 0 and queue[0]["t"] <= hour + 0.00001:
		var e: Dictionary = queue.pop_front()
		match e["name"]:
			"lander": land_cargo()

func _storm_tick(dt: float) -> void:
	var st = today().get("storm")
	# scheduled storm (not in a mission): warn when the warning time is reached
	if st != null and not st["in_mission"] and storm_state == "none" and not storm_warned:
		var warn_h: float = storm_warning_seconds(st["size"]) / cfg["time"]["real_seconds_per_game_hour"]
		if hour >= st["at"] - warn_h:
			storm_hit_hour = st["at"]
			start_storm_warning(st["size"], st["event"], maxf(0.0, st["at"] - hour))
	elif storm_state == "warning":
		storm_left_h -= dt
		if storm_left_h <= 0.0:
			storm_hit()

# ---------------------------------------------------------------- day start / end
# Shows today's info cards and HUD notices (scenes call this once when they are ready).
func emit_day_intro() -> void:
	day_intro_pending = false
	var d := today()
	for c in d["cards"]:
		card.emit(c)
	for n in d["notices"]:
		notice.emit(n)
	if sliders[3] == 2 and day < 32 and days[day]["storm"] != null:
		notice.emit("storm_tomorrow")        # storm watch high: warn the day before

func _start_day(emit_intro := true) -> void:
	mission_done_today = false
	hour = DAY_START
	ate_today = false
	drank_today = false
	watered_today = false
	slept_today = false
	gym_today = false
	in_shelter = false
	storm_state = "none"
	storm_warned = false
	storm_hit_hour = 0.0
	var d := today()
	science_hist[day] = sliders[2]
	# shadow on/off follows the config list
	var want_shadow: bool = float(day) in cfg["shadow_days"]  # JSON numbers are floats
	if want_shadow and not in_shadow:
		start_shadow()
	elif in_shadow and not want_shadow:
		end_shadow()
	queue = []
	if d["lander"] != null:
		queue.append({"t": 7.0, "name": "lander"})
	day_intro_pending = true
	if emit_intro:
		emit_day_intro()
	event.emit("day_start", {"day": day})
	changed.emit()

func _end_day() -> void:
	# radish growth
	if tray_planted and not tray_ready:
		if watered_today and sliders[1] > 0:
			tray_growth += 1
			if sliders[1] == 2:
				tray_high_days += 1
			if tray_growth >= cfg["food"]["growth_days"]:
				tray_ready = true
	# health rules
	if not slept_today:
		damage(cfg["time"]["no_sleep_damage"])
	no_drink_days = 0 if drank_today else no_drink_days + 1
	no_meal_days = 0 if ate_today else no_meal_days + 1
	if no_drink_days >= cfg["health"]["no_drink_days"]:
		damage(cfg["health"]["no_drink_damage"])
	if no_meal_days >= cfg["health"]["no_meal_days"]:
		damage(cfg["health"]["no_meal_damage"])
	# gym cap
	var since := day - last_gym_day
	health_cap = 100.0
	if since >= cfg["health"]["gym_cap_days"][1]:
		health_cap = cfg["health"]["gym_cap_values"][1]
	elif since >= cfg["health"]["gym_cap_days"][0]:
		health_cap = cfg["health"]["gym_cap_values"][0]
	health = minf(health, health_cap)
	event.emit("day_end", {"day": day})
	if game_over:
		return
	if day >= cfg["time"]["total_days"]:
		finish_game("success")
		return
	day += 1
	_start_day()

# ---------------------------------------------------------------- actions (scenes call these)
# Each returns "" when it worked, or a text key (ui.*) saying why not.
func eat(kind: String) -> String:
	if ate_today:
		return "ui.already_ate"
	if kind == "radish" and radish_meals > 0:
		radish_meals -= 1
	elif kind == "ration" and rations > 0:
		rations -= 1
	else:
		return "ui.no_food"
	ate_today = true
	heal(cfg["health"]["meal_heal"])
	return ""

func recycler_return() -> float:
	return cfg["water"]["recycler_return"][sliders[0]]

func drink() -> String:
	if drank_today:
		return "ui.drank"
	drank_today = true
	water = maxf(0.0, water - cfg["water"]["drink_l"] * (1.0 - recycler_return()))
	if water < cfg["water"]["warn_below_l"]:
		notice.emit("water_low")
	changed.emit()
	return ""

func plant_radish() -> void:
	if not tray_planted:
		tray_planted = true
		tray_growth = 0
		tray_high_days = 0
		tray_ready = false
		changed.emit()

func water_radish() -> String:
	if not tray_planted or tray_ready or watered_today:
		return "ui.radish_growing"
	watered_today = true
	water = maxf(0.0, water - cfg["water"]["radish_l"] * (1.0 - recycler_return()))
	changed.emit()
	return ""

# Harvest and replant in the same visit.
func harvest_radish() -> bool:
	if not tray_ready:
		return false
	var n: int = cfg["food"]["harvest_meals"]
	if tray_high_days >= cfg["food"]["bonus_high_days_needed"]:
		n = cfg["food"]["harvest_meals_bonus"]
	radish_meals += n
	tray_planted = false
	tray_ready = false
	plant_radish()
	event.emit("harvest", {"meals": n})
	return true

# "empty", "sprout", "growing", "ready" (sprite names radish_<state>)
func tray_stage() -> String:
	if not tray_planted:
		return "empty"
	if tray_ready:
		return "ready"
	return "sprout" if tray_growth < 3 else "growing"

func can_sleep() -> String:
	if slept_today:
		return "ui.already_slept"
	if blackout:
		return "ui.blackout_no_sleep"
	if total_hours - last_sleep_total < cfg["time"]["sleep_cooldown_hours"]:
		return "ui.too_late"
	return ""

func sleep() -> String:
	var why := can_sleep()
	if why != "":
		return why
	slept_today = true
	last_sleep_total = total_hours
	heal(cfg["health"]["sleep_heal"][sliders[2]])
	advance(minf(cfg["time"]["sleep_hours"], DAY_END - hour))
	return ""

func can_gym() -> String:
	if gym_today or day - last_gym_day < cfg["health"]["gym_cooldown_days"] and last_gym_day > 0:
		return "ui.gym_cooldown"
	if hour + 1.0 > DAY_END:
		return "ui.too_late"
	return ""

func gym() -> String:
	var why := can_gym()
	if why != "":
		return why
	gym_today = true
	last_gym_day = day
	base_pack = maxf(0.0, base_pack - cfg["power"]["gym_kwh"] / (cfg["power"]["pack_kwh"] / 100.0))
	heal(cfg["health"]["gym_heal"])
	health_cap = 100.0
	advance(1.0)
	return ""

func set_slider(i: int, level: int) -> void:
	sliders[i] = clampi(level, 0, 2)
	if i == 2:
		science_hist[day] = sliders[2]
	changed.emit()

func clean_panel(group: int) -> void:
	dust[group] = 0.0
	event.emit("panel_cleaned", {"group": group})
	changed.emit()

func swap_packs() -> void:
	var t := base_pack
	base_pack = spare_pack
	spare_pack = t
	if blackout and base_pack > 0.0:
		blackout = false
	event.emit("pack_swap", {})
	changed.emit()

# ---------------------------------------------------------------- events (schedule + Judge call these)
func land_cargo() -> void:
	var d := today()
	var add: float = cfg["dust"]["lander_add_pct"]
	for i in 4:
		dust[i] = minf(cfg["dust"]["max_pct"], dust[i] + add)
	var r := 2           # (Judge "land cargo" on a day without a lander brings a small default)
	var w := 3
	if d["lander"] != null:
		r = d["lander"]["rations"]
		w = d["lander"]["water"]
	cargo_waiting = {"rations": r, "water": w}
	notice.emit("cargo_landed")
	event.emit("lander", {"rations": r, "water": w})
	changed.emit()

func collect_cargo() -> bool:
	if cargo_waiting.is_empty():
		return false
	rations += int(cargo_waiting["rations"])
	water = minf(cfg["water"]["max_l"], water + float(cargo_waiting["water"]))
	cargo_waiting = {}
	event.emit("cargo_collected", {})
	changed.emit()
	return true

func start_shadow() -> void:
	in_shadow = true
	notice.emit("shadow_start")
	event.emit("shadow", {"on": true})
	changed.emit()

func end_shadow() -> void:
	in_shadow = false
	notice.emit("sunrise")
	event.emit("sunrise", {})
	changed.emit()

func storm_warning_seconds(size: String) -> float:
	var key := "warning_seconds_low" if sliders[3] == 0 else "warning_seconds_high"
	return float(cfg["storms"][key][size])

# Start a storm warning now. left_h = game hours until the hit (default: full warning length).
func start_storm_warning(size: String, ev: String = "", left_h: float = -1.0) -> void:
	storm_state = "warning"
	storm_warned = true
	storm_size = size
	storm_event = ev
	storm_total_h = storm_warning_seconds(size) / cfg["time"]["real_seconds_per_game_hour"]
	storm_left_h = storm_total_h if left_h < 0.0 else left_h
	event.emit("storm_warning", {"size": size, "event": ev, "left_h": storm_left_h, "total_h": storm_total_h})

# The countdown reached zero. Damage depends on in_shelter (set by enter_shelter()).
# Returns a result dict {sheltered, damage_pct, failed}.
func storm_hit() -> Dictionary:
	var size := storm_size
	var res := {"sheltered": in_shelter, "damage_pct": 0.0, "failed": false, "size": size}
	storm_state = "none"
	if size == "large" or size == "finale":
		if in_shelter:
			damage(cfg["storms"]["shelter_damage_big"])
			res["damage_pct"] = 5.0
		else:
			res["failed"] = true
			missions_failed += 1
			if size == "finale":
				finish_game("failed")
			elif mission_done_today and pending_research.size() > 0:
				pending_research.pop_back()      # today's samples are lost
	elif not in_shelter:
		var now: float = cfg["storms"]["unsheltered_now_pct"][size]
		var later: float = cfg["storms"]["unsheltered_later_pct"][size]
		damage(health * now / 100.0)
		later_damage_pct = later
		later_left_h = cfg["storms"]["later_hours"]
		res["damage_pct"] = now + later
	event.emit("storm_hit", res)
	event.emit("storm_clear", {})
	changed.emit()
	return res

# Shelter: forced sleep until the day ends, counts as that day's sleep. Scenes stop the player.
func enter_shelter() -> void:
	in_shelter = true
	if not slept_today:
		slept_today = true
		heal(cfg["health"]["sleep_heal"][sliders[2]])
	event.emit("shelter_enter", {})

# Sleep through the rest of the day in the shelter (storm hits during this advance).
func shelter_until_day_end() -> void:
	enter_shelter()
	advance(DAY_END - hour)

# ---------------------------------------------------------------- missions and research
# Average of the daily science slider over the mission day and the 3 days before it.
func locked_research_value() -> float:
	var vals: Array = cfg["research"]["per_mission_pct"]
	var n: int = cfg["research"]["average_days"]
	var total := 0.0
	var count := 0
	for d in range(day - n + 1, day + 1):
		if science_hist.has(d):
			total += vals[science_hist[d]]
			count += 1
	return total / maxf(1.0, count)

func suit_seconds() -> float:
	var key := "suit_seconds_first" if missions_done == 0 else "suit_seconds"
	return float(cfg["missions"][key])

# kind: "rock" / "ice" / "finale". success: samples kept (finished or waypoint reached).
func finish_mission(kind: String, success: bool) -> void:
	if success:
		missions_done += 1
		if kind != "finale":
			pending_research.append(locked_research_value())
	else:
		missions_failed += 1
	mission_done_today = true
	event.emit("mission_end", {"kind": kind, "success": success})
	changed.emit()

func process_samples() -> float:
	var gained := 0.0
	for v in pending_research:
		gained += v
	pending_research = []
	research = minf(100.0, research + gained)
	if gained > 0.0:
		event.emit("lab_processed", {"gained": gained})
	changed.emit()
	return gained

func stars() -> int:
	var th: Array = cfg["research"]["star_thresholds"]
	var n := 0
	for i in th.size():
		if research >= th[i] - 0.001:
			n = i + 1
	return n
