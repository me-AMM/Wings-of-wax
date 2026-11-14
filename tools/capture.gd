# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Store / video screenshots at 1280x720 (exact 2x of the 640x360 game, Nearest) into docs/screenshots/.
#   godot --path . res://tools/capture.tscn          (needs a window, not --headless)
# Video mode is on: no JUDGE MODE label, no debug overlay; the AI watermark stays.
const OUT := "res://docs/screenshots/"

func snap(file: String) -> void:
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	img.save_png(OUT + file)
	print("saved ", file)

func go(scene: String) -> void:
	get_tree().change_scene_to_file(scene)
	for i in 12:
		await get_tree().process_frame

func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func prep(day: int) -> void:
	GameState.new_game()
	GameState.auto_endings = false
	GameState.game_started = true
	Save.path = "user://capture_unused.json"          # never touch a real save
	if day > 1:
		Judge.jump_to_day(day)
	GameState.video_mode = true
	GameState.tutorial_off = day > 1
	GameState.day_intro_pending = false
	GameState.card_queue.clear()
	GameState.cards_seen = ["welcome", "solar_storms", "osdr_gym", "csa_radish"]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().process_frame
	# 1. title
	await go("res://scenes/Title.tscn")
	await wait(0.6)
	await snap("01_title.png")
	# 2. outpost with the power sliders open (day 3)
	prep(3)
	GameState.outpost_spawn = Vector2(830, 250)
	await go("res://scenes/Outpost.tscn")
	await wait(1.8)
	var sp = load("res://scenes/SliderPanel.tscn").instantiate()
	get_tree().current_scene.add_child(sp)
	await wait(0.4)
	await snap("02_outpost_sliders.png")
	GameState.modal_count = 0
	# 3. storm during a mission with the real flare label (day 8, medium storm = X5.8 of 11 May 2024)
	prep(8)
	GameState.mission_kind = "ice"
	await go("res://scenes/Mission.tscn")
	await wait(0.5)
	GameState.start_storm_warning("medium", "medium1", -1.0, true)
	await wait(1.2)
	await snap("03_storm_mission_real_flare.png")
	# 4. shadow day (day 11)
	prep(11)
	GameState.outpost_spawn = Vector2(560, 470)
	await go("res://scenes/Outpost.tscn")
	await wait(1.8)
	await snap("04_shadow_day.png")
	# 5. day 1 with the guided goal and the daily checklist
	prep(1)
	GameState.tutorial_off = false
	await go("res://scenes/Outpost.tscn")
	await wait(1.8)
	await snap("05_day1_goals.png")
	# 6. Space Weather Log
	prep(24)
	GameState.storms_survived = ["small1", "medium1", "small2", "small3", "small4", "small5"]
	GameState.log_return = "res://scenes/Title.tscn"
	await go("res://scenes/SpaceWeatherLog.tscn")
	await wait(0.5)
	await snap("06_space_weather_log.png")
	# 7. success ending with the stars
	prep(32)
	GameState.judge_mode = false
	GameState.research = 100.0
	await go("res://scenes/EndingSuccess.tscn")
	await wait(3.2)
	await snap("07_ending_stars.png")
	GameState.video_mode = false
	get_tree().quit()
