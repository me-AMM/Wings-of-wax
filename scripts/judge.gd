extends Node
# Judge autoload: the debug logic behind the Judge panel. Every function here calls the same
# GameState functions that the day schedule uses. Runs started in Judge mode earn no stars.
# While judge_mode is on, press J in any scene to open the panel.

var panel: Node = null

func _unhandled_input(e: InputEvent) -> void:
	if GameState.judge_mode and e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_J:
		open_panel()

func open_panel(from_title := false) -> void:
	if panel != null and is_instance_valid(panel):
		return
	panel = load("res://scripts/judge_panel.gd").new()
	panel.from_title = from_title
	get_tree().root.add_child(panel)

# ---- starting a judge run (from the title screen)
func begin_judge_run() -> void:
	GameState.new_game()
	GameState.judge_mode = true

func go_outpost() -> void:
	GameState.modal_count = 0
	get_tree().change_scene_to_file("res://scenes/Outpost.tscn")

# ---- jump to the START of day d with the "good player" stock (data/day_snapshots.json)
func jump_to_day(d: int) -> void:
	var snaps: Dictionary = Config.load_json("res://data/day_snapshots.json")
	var snap = snaps.get(str(d))
	if snap == null:
		return
	GameState.from_dict(snap)
	GameState.judge_mode = true
	GameState.card_queue.clear()
	GameState.mission_kind = ""
	GameState.pending_shelter = false
	GameState.clock_running = true

func trigger_storm(size: String) -> void:
	var slot: String = {"small": "small1", "medium": "medium1", "large": "large1", "finale": "finale"}[size]
	GameState.start_storm_warning(size, slot)

func start_shadow() -> void:
	GameState.start_shadow()

func end_shadow() -> void:
	GameState.end_shadow()

func land_cargo() -> void:
	GameState.land_cargo()

func start_mission() -> void:
	var kind = GameState.today()["mission"]
	GameState.mission_kind = kind if kind != null else "rock"
	GameState.mission_done_today = false
	GameState.modal_count = 0
	get_tree().change_scene_to_file("res://scenes/Mission.tscn")

func refill_all() -> void:
	GameState.health = 100.0
	GameState.health_cap = 100.0
	GameState.oxygen_h = Config.data["oxygen"]["max_h"]
	GameState.water = Config.data["water"]["max_l"]
	GameState.base_pack = 100.0
	GameState.spare_pack = 100.0
	GameState.dust = [0.0, 0.0, 0.0, 0.0]
	GameState.rations = maxi(GameState.rations, 5)
	GameState.blackout = false
	GameState.changed.emit()

func toggle_speed() -> bool:
	GameState.time_scale = 1.0 if GameState.time_scale > 1.0 else 4.0
	return GameState.time_scale > 1.0

# ---- presets (they put you right at the interesting moment)
func preset_storm_in_mission() -> void:
	_mission_day(8)

func preset_shadow() -> void:
	jump_to_day(11)
	go_outpost()

func preset_big_storm() -> void:
	_mission_day(24)

func _mission_day(d: int) -> void:
	jump_to_day(d)
	GameState.advance(1.2)          # 07:00: the cargo lander touches down
	GameState.collect_cargo()
	start_mission()
