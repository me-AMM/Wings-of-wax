extends Node2D
# Mission: ONE scene for rock/soil, ice dig and the finale stone (GameState.mission_kind).
# Walk out, do the job, reach the flag, come back to the base (shelter). Suit air runs out!
# Everything you may want to tweak is an exported variable below. Positions are in pixels.

@export var world_size := Vector2(800, 420)
@export var base_pos := Vector2(70, 230)
@export var base_radius := 56.0
@export var flag_pos := Vector2(730, 200)
@export var sample_positions: Array[Vector2] = [Vector2(240, 150), Vector2(440, 330), Vector2(560, 100)]
@export var ice_pos := Vector2(330, 190)
@export var crater_centers: Array[Vector2] = [Vector2(390, 290), Vector2(620, 160)]
@export var crater_radius := 58.0
@export var pick_radius := 30.0
@export var flag_radius := 28.0
@export var dark_tint := Color(0.3, 0.34, 0.58)

var kind := "rock"
var player: Node2D
var hud: CanvasLayer
var world: Node2D
var items: Array = []             # {node, type, done}
var elapsed := 0.0
var suit_total := 120.0
var suit_left := 120.0
var base_speed := 55.0
var samples_got := 0
var ice_done := false
var waypoint_reached := false
var objective_done := false
var ending := false
var digging := false
var in_crater := false
var storm_started := false
var suit_bar: HudBar
var suit_label: Label
var obj_label: Label
var storm_label: Label
var crater_label: Label
var prompt: Node2D
var prompt_label: Label
var low_sound_t := 0.0

func _ready() -> void:
	kind = GameState.mission_kind if GameState.mission_kind != "" else "rock"
	suit_total = GameState.suit_seconds()
	suit_left = suit_total
	_build_world()
	_build_player()
	_build_ui()
	GameState.event.connect(_on_event)
	GameState.clock_running = true
	_update_objective()

# ------------------------------------------------------------------ world
func _tile(still: String, rect: Rect2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Art.tex(still)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.position = rect.position
	r.size = rect.size
	return r

func _sprite(still: String, pos: Vector2, parent: Node, bottom_aligned := true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.tex(still)
	s.centered = false
	var sz := s.texture.get_size()
	s.offset = Vector2(-sz.x / 2.0, -sz.y) if bottom_aligned else -sz / 2.0
	s.position = pos
	parent.add_child(s)
	return s

func _build_world() -> void:
	var dark := CanvasModulate.new()
	dark.color = dark_tint if GameState.in_shadow else Color.WHITE
	add_child(dark)
	var ground := Node2D.new()
	add_child(ground)
	ground.add_child(_tile("ground_1", Rect2(Vector2.ZERO, world_size)))
	for i in 12:                                   # a few lighter/darker patches
		var p := Vector2((i * 197) % int(world_size.x - 64), (i * 131) % int(world_size.y - 64))
		var s := Sprite2D.new()
		s.texture = Art.tex("ground_2" if i % 2 == 0 else "ground_3")
		s.centered = false
		s.position = p.snapped(Vector2(64, 64))
		ground.add_child(s)
	ground.add_child(_tile("boulder_wall", Rect2(0, 0, world_size.x, 32)))
	ground.add_child(_tile("boulder_wall", Rect2(0, world_size.y - 32, world_size.x, 32)))
	ground.add_child(_tile("boulder_wall", Rect2(0, 0, 32, world_size.y)))
	ground.add_child(_tile("boulder_wall", Rect2(world_size.x - 32, 0, 32, world_size.y)))
	for c in crater_centers:
		ground.add_child(_tile("ground_dark", Rect2(c - Vector2(64, 40), Vector2(128, 80))))
		_sprite("crater_large", c, ground, false)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	# base: shelter sprite marks the start / safe zone
	_sprite("shelter", base_pos + Vector2(0, -40), world)
	# objectives
	if kind == "rock":
		for p in sample_positions:
			var n := _sprite("sample_spot", p, world)
			items.append({"node": n, "type": "sample", "done": false, "pos": p})
	elif kind == "ice":
		var n := _sprite("ice_deposit", ice_pos, world)
		items.append({"node": n, "type": "ice", "done": false, "pos": ice_pos})
	if kind == "finale":
		var st := AnimatedSprite2D.new()
		st.sprite_frames = Art.frames("rare_stone_glow")
		st.centered = false
		st.offset = -Art.anchor("rare_stone_glow")
		st.position = flag_pos
		world.add_child(st)
		st.play("default")
		items.append({"node": st, "type": "stone", "done": false, "pos": flag_pos})
	else:
		var fl := AnimatedSprite2D.new()
		fl.sprite_frames = Art.frames("waypoint_flag_pulse")
		fl.centered = false
		fl.offset = -Art.anchor("waypoint_flag_pulse")
		fl.position = flag_pos
		world.add_child(fl)
		fl.play("default")
		items.append({"node": fl, "type": "flag", "done": false, "pos": flag_pos})

func _build_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/player.gd"))
	player.position = base_pos + Vector2(0, 30)
	world.add_child(player)
	player.world_min = Vector2(40, 40)
	player.world_max = world_size - Vector2(40, 36)
	base_speed = Config.data["player"]["walk_speed"]
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(world_size.x)
	cam.limit_bottom = int(world_size.y)
	player.add_child(cam)
	prompt = Node2D.new()
	prompt.z_index = 200
	var key := Sprite2D.new()
	key.texture = Art.tex("icon_ekey")
	key.scale = Vector2(0.4, 0.4)
	prompt.add_child(key)
	prompt_label = UIKit.label("", 8)
	prompt_label.position = Vector2(-60, 10)
	prompt_label.size = Vector2(120, 12)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_child(prompt_label)
	prompt.visible = false
	add_child(prompt)

func _build_ui() -> void:
	hud = load("res://scripts/hud.gd").new()
	add_child(hud)
	var ui := CanvasLayer.new()
	ui.layer = 11
	add_child(ui)
	var ic := UIKit.icon("icon_oxygen", 14)
	ic.position = Vector2(4, 36)
	ui.add_child(ic)
	suit_bar = HudBar.new().setup(70, Color("9BE8FF"))
	suit_bar.position = Vector2(20, 35)
	ui.add_child(suit_bar)
	suit_label = UIKit.label("", 9)
	suit_label.position = Vector2(94, 33)
	ui.add_child(suit_label)
	obj_label = UIKit.label("", 9, Color("FFD23F"))
	obj_label.position = Vector2(4, 52)
	ui.add_child(obj_label)
	storm_label = UIKit.label("", 10, Color("FF8080"))
	storm_label.position = Vector2(0, 66)
	storm_label.size = Vector2(320, 14)
	storm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(storm_label)
	crater_label = UIKit.label(Text.t("ui.in_crater"), 8, Color("FFD23F"))
	crater_label.position = Vector2(0, 140)
	crater_label.size = Vector2(320, 12)
	crater_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crater_label.visible = false
	ui.add_child(crater_label)

# ------------------------------------------------------------------ rules
func _in_base() -> bool:
	return player.position.distance_to(base_pos + Vector2(0, 10)) < base_radius

func _update_objective() -> void:
	var txt := ""
	if objective_done:
		txt = Text.t("ui.obj_back")
	elif kind == "rock":
		txt = "%s %d/3" % [Text.t("ui.obj_rock"), samples_got] if samples_got < 3 else Text.t("ui.obj_flag")
	elif kind == "ice":
		txt = Text.t("ui.obj_ice") if not ice_done else Text.t("ui.obj_flag")
	else:
		txt = Text.t("ui.obj_stone")
	obj_label.text = txt

func _check_objective() -> void:
	var done := false
	if kind == "rock":
		done = samples_got >= 3 and waypoint_reached
	elif kind == "ice":
		done = ice_done and waypoint_reached
	else:
		done = waypoint_reached           # finale: picking up the stone counts as the waypoint
	if done and not objective_done:
		objective_done = true
		hud.say(Text.t("ui.obj_back"))
	_update_objective()

func _process(delta: float) -> void:
	if ending:
		return
	var running: bool = GameState.modal_count == 0
	GameState.clock_running = running
	player.frozen = digging or not running
	if not running:
		return
	elapsed += delta
	# craters: slow and more suit air used
	in_crater = false
	for c in crater_centers:
		if player.position.distance_to(c) < crater_radius:
			in_crater = true
	player.speed = base_speed * (Config.data["missions"]["crater_speed_mult"] if in_crater else 1.0)
	crater_label.visible = in_crater
	# suit air
	var drain: float = delta * (Config.data["missions"]["crater_drain_mult"] if in_crater else 1.0)
	suit_left = maxf(0.0, suit_left - drain)
	var frac := suit_left / suit_total
	suit_bar.set_frac(frac)
	suit_label.text = "%d h" % int(ceil(frac * 8.0))
	suit_label.modulate = Color("FF8080") if frac < 0.25 else Color.WHITE
	if frac < 0.25:
		low_sound_t -= delta
		if low_sound_t <= 0.0:
			Audio.play("suit_o2_low")
			low_sound_t = 2.0
	if suit_left <= 0.0:
		_suit_out()
		return
	_storm_logic()
	_find_target()
	if Input.is_action_just_pressed("interact") and not digging:
		_use_target()
	if Input.is_action_just_pressed("ui_cancel") and not digging:
		_abort_menu()

func _storm_logic() -> void:
	var st = GameState.today()["storm"]
	if st != null and st["in_mission"] and not storm_started:
		var at: float = Config.data["missions"]["length_s"] * Config.data["storms"]["mission_warning_at_fraction"]
		if elapsed >= at:
			storm_started = true
			GameState.start_storm_warning(st["size"], st["event"])
	if GameState.storm_state == "warning":
		GameState.in_shelter = _in_base()
		storm_label.text = "%s %d s  -  %s" % [Text.t("ui.storm_incoming"), int(ceil(GameState.storm_left_h * 10.0)),
			Text.t("ui.storm_in_shelter") if GameState.in_shelter else Text.t("ui.storm_run")]
	else:
		storm_label.text = ""

var target = null     # current item dictionary, or "base"

func _find_target() -> void:
	target = null
	var best := 1e9
	for it in items:
		if it["done"] or it["type"] == "flag":
			continue
		var d: float = player.position.distance_to(it["pos"])
		if d < pick_radius and d < best:
			target = it
			best = d
	# waypoint flag is automatic
	if not waypoint_reached and kind != "finale":
		if player.position.distance_to(flag_pos) < flag_radius:
			waypoint_reached = true
			hud.say(Text.t("ui.waypoint_reached"))
			Audio.play("waypoint_reached")
			_check_objective()
	if target == null and _in_base():
		target = "base"
	if target == null or digging:
		prompt.visible = false
		return
	prompt.visible = true
	var p: Vector2 = base_pos + Vector2(0, -50) if (target is String) else target["pos"] + Vector2(0, -50)
	prompt.position = p
	prompt_label.text = _target_text()

func _target_text() -> String:
	if target is String:
		return Text.t("ui.return_base")
	match target["type"]:
		"sample": return Text.t("ui.collect_sample")
		"ice": return Text.t("ui.dig_ice")
		"stone": return Text.t("ui.take_stone")
	return ""

func _use_target() -> void:
	if target == null:
		return
	if target is String:
		_end(objective_done or waypoint_reached, "ui.mission_done" if objective_done else "ui.mission_result_aborted")
		return
	match target["type"]:
		"sample":
			target["done"] = true
			target["node"].visible = false
			samples_got += 1
			Audio.play("sample_pickup")
			hud.toast("+1", Color("FFD23F"))
			_check_objective()
		"stone":
			target["done"] = true
			target["node"].visible = false
			waypoint_reached = true
			Audio.play("rare_stone")
			_check_objective()
		"ice":
			_start_dig(target)

func _start_dig(it: Dictionary) -> void:
	digging = true
	player.play_action("dig_front", 99.0)
	var bar = load("res://scripts/ice_dig_bar.gd").new()
	add_child(bar)
	bar.finished.connect(func(hits: int):
		digging = false
		player.frozen = false
		player.sprite.play("idle_front")
		if hits >= bar.hits_needed:
			it["done"] = true
			ice_done = true
			hud.toast("+" + Text.t("ui.obj_ice"), Color("9BE8FF"))
			_check_objective()
		_update_objective())

func _abort_menu() -> void:
	var m := MenuModal.new()
	m.title_text = Text.t("ui.abort_title")
	m.items = [
		{"icon": "icon_rock", "text": Text.t("ui.keep_going")},
		{"icon": "icon_storm", "text": Text.t("ui.abort_mission"), "call": func(): _end(waypoint_reached, "ui.mission_result_aborted" if waypoint_reached else "ui.mission_result_lost")},
	]
	add_child(m)
	m.build()

func _suit_out() -> void:
	GameState.damage(Config.data["health"]["suit_empty_damage"])
	Audio.play("hurt")
	_end(false, "ui.suit_empty")

func _on_event(ev_name: String, data: Dictionary) -> void:
	if ending:
		return
	if ev_name == "storm_hit":
		if data["failed"]:
			_end(false, "ui.mission_failed")
		elif GameState.in_shelter:
			_end(waypoint_reached, "ui.mission_done" if objective_done else "ui.mission_result_aborted")

# Finish: record the result, show it, go back to the outpost.
func _end(success: bool, msg_key: String) -> void:
	if ending:
		return
	ending = true
	GameState.clock_running = false
	GameState.finish_mission(kind, success)
	if GameState.storm_state == "warning":
		GameState.pending_shelter = true     # storm still coming: you go straight to the shelter
	GameState.outpost_spawn = Vector2(640, 800)
	var m := MenuModal.new()
	m.title_text = Text.t("ui.mission_done") if success else Text.t("ui.mission_failed")
	m.items = [{"icon": "icon_research" if success else "icon_storm", "text": Text.t("ui.ok"), "sub": Text.t(msg_key),
		"call": func(): get_tree().change_scene_to_file("res://scenes/Outpost.tscn")}]
	m.menu_width = 250.0
	add_child(m)
	m.build()
