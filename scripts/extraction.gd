extends Control
# Extraction: a short still scene. The astronaut walks to the crew lander, boards it, the lander lifts off,
# then the game ends with the success ending (stars, then credits). E skips.
var astro: AnimatedSprite2D
var lander: Sprite2D
var done := false

func _ready() -> void:
	GameState.clock_running = false
	var sky := ColorRect.new()
	sky.color = Color("0B0D1A")
	sky.size = Vector2(640, 360)
	add_child(sky)
	for i in 40:                                              # stars
		var s := ColorRect.new()
		s.color = Color(0.9, 0.93, 1, 0.8)
		s.size = Vector2(2, 2)
		s.position = Vector2(randi() % 640, randi() % 200)
		add_child(s)
	var ground := TextureRect.new()
	ground.texture = Art.tex("ground_1")
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.position = Vector2(0, 250)
	ground.size = Vector2(640, 110)
	add_child(ground)
	lander = Sprite2D.new()
	lander.texture = Art.tex("crew_lander")
	lander.centered = false
	lander.offset = Vector2(-96, -192)
	lander.position = Vector2(470, 330)
	add_child(lander)
	astro = AnimatedSprite2D.new()
	astro.sprite_frames = Art.astronaut_frames(GameState.astronaut)
	astro.centered = false
	astro.offset = -Art.anchor("astronaut_a_walk_right")
	astro.position = Vector2(90, 334)
	add_child(astro)
	astro.play("walk_right")
	var txt := UIKit.world_label(Text.list("extraction")[0], 16)
	txt.position = Vector2(0, 24)
	txt.size = Vector2(640, 24)
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(txt)
	var skip := UIKit.world_label(Text.t("ui.extraction_skip"), 16)
	skip.position = Vector2(540, 330)
	add_child(skip)
	_play()

func _play() -> void:
	var tw := create_tween()
	tw.tween_property(astro, "position:x", 420.0, 2.6)          # walk to the lander door
	await tw.finished
	if done:
		return
	astro.visible = false                                       # boards
	await get_tree().create_timer(0.6).timeout
	Audio.play("lander_touchdown")
	var lift := create_tween()
	lift.tween_property(lander, "position:y", -260.0, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await lift.finished
	_finish()

func _finish() -> void:
	if done:
		return
	done = true
	GameState.finish_game("success")             # -> EndingSuccess (stars) -> Credits
	if not GameState.auto_endings:
		get_tree().change_scene_to_file("res://scenes/EndingSuccess.tscn")

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact"):
		_finish()
