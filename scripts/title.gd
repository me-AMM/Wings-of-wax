extends Control
# Title screen: Start and Judge mode. The 320x180 art is shown at exactly 2x (Nearest); buttons are real 640x360 pixels.

func _ready() -> void:
	GameState.clock_running = false
	GameState.judge_mode = false
	GameState.auto_endings = true
	var bg: TextureRect = $Background
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(640, 360)
	var start := UIKit.button(Text.t("ui.start"), 160)
	start.position = Vector2(240, 224)
	start.pressed.connect(_on_start)
	add_child(start)
	var judge := UIKit.button(Text.t("ui.judge_mode"), 160)
	judge.position = Vector2(240, 268)
	judge.pressed.connect(_on_judge)
	add_child(judge)
	start.grab_focus()
	start.focus_neighbor_bottom = judge.get_path()
	judge.focus_neighbor_top = start.get_path()

func _on_start() -> void:
	Audio.play("ui_click")
	GameState.new_game()
	var next := "res://scenes/CharacterSelect.tscn"
	get_tree().change_scene_to_file(next if ResourceLoader.exists(next) else "res://scenes/Outpost.tscn")

func _on_judge() -> void:
	Audio.play("ui_click")
	Judge.begin_judge_run()
	Judge.open_panel(true)

func _unhandled_input(e: InputEvent) -> void:
	var f := get_viewport().gui_get_focus_owner()
	if e.is_action_pressed("interact") and f is Button:
		f.pressed.emit()
	elif e.is_action_pressed("move_down") or e.is_action_pressed("move_up"):
		var next_f: Control = f.find_next_valid_focus() if e.is_action_pressed("move_down") else f.find_prev_valid_focus()
		if next_f:
			next_f.grab_focus()
