extends Node2D
# Mission: ONE scene for rock/soil, ice dig and the finale stone (GameState.mission_kind).
# Walk out, do the job, reach the flag, then come back to the EXIT marker at the start and hold E (2 s).
# Suit air runs out! A yellow arrow points to the next target. A storm warning can start mid-mission; the countdown
# belongs to GameState and keeps running when you return to the Outpost: you must then WALK to the shelter.
# Everything you may want to tweak is an exported variable below. Positions are in pixels.

@export var world_size := Vector2(2240, 1120)
@export var base_pos := Vector2(150, 580)             # exit marker = start
@export var exit_radius := 70.0
@export var exit_hold := 2.0
@export var flag_pos := Vector2(2060, 560)
@export var sample_positions: Array[Vector2] = [Vector2(820, 420), Vector2(1240, 600), Vector2(1680, 520)]
@export var ice_pos := Vector2(800, 430)
@export var crater_centers: Array[Vector2] = [Vector2(350, 300), Vector2(714, 696), Vector2(1154, 444), Vector2(1594, 696), Vector2(1950, 330)]
# Serpentine of boulder-wall barriers (solid): you must zigzag through the gaps. Gaps alternate bottom / top.
@export var barrier_x: Array[float] = [560.0, 1000.0, 1440.0, 1880.0]
@export var gap_bottom := Vector2(860, 1060)      # y range of the gap in barriers 1 and 3
@export var gap_top := Vector2(50, 250)           # y range of the gap in barriers 2 and 4
@export var pick_radius := 30.0
@export var flag_radius := 28.0
@export var dark_tint := Color(0.3, 0.34, 0.58)

var kind := "rock"
var player: CharacterBody2D
var hud: CanvasLayer
var world: Node2D
var ground: Node2D
var items: Array = []             # {node, type, done, pos}
var elapsed := 0.0
var suit_total := 100.0
var suit_left := 100.0
var base_speed := 119.0
var samples_got := 0
var ice_done := false
var waypoint_reached := false
var objective_done := false
var ending := false
var digging := false
var crater_count := 0             # slow zones the player is inside (Area2D)
var in_crater := false
var storm_started := false
var storm_at := 30.0              # seconds into the mission when the warning starts (random 25-40%)
var exit_t := 0.0
var suit_bar: HudBar
var suit_label: Label
var obj_label: Label
var storm_label: Label
var crater_label: Label
var prompt: Node2D
var prompt_label: Label
var prompt_bar: ColorRect
var arrow: Node2D
var low_sound_t := 0.0
var target = null                 # current item dictionary, or "exit"

func _ready() -> void:
	Audio.outdoor = true
	Audio.ambience({"suit_breath": 1.0})
	kind = GameState.mission_kind if GameState.mission_kind != "" else "rock"
	suit_total = GameState.suit_seconds()
	suit_left = suit_total
	var rr: Array = Config.data["storms"]["mission_warning_range"]
	storm_at = randf_range(rr[0], rr[1]) * float(Config.data["missions"]["length_s"])
	GameState.in_shelter = false          # there is no shelter out here: only the one at the Outpost counts
	_build_world()
	_build_player()
	_build_ui()
	add_child(load("res://scripts/storm_warning.gd").new())
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
	ground = Node2D.new()
	add_child(ground)
	ground.add_child(_tile("ground_1", Rect2(Vector2.ZERO, world_size)))
	for i in 40:                                   # lighter/darker patches
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
	for r in _barriers():
		ground.add_child(_tile("boulder_wall", r))
	for c in crater_centers:
		ground.add_child(_tile("ground_dark", Rect2(c - Vector2(64, 40), Vector2(128, 80))))
		_sprite("crater_large", c, ground, false)
	# the exit marker: a flat landing pad at the start (walkable), with a label
	_sprite("landing_pad", base_pos + Vector2(0, 96), ground)
	var ex := UIKit.world_label(Text.t("ui.exit_marker"), 16, Color("FFD23F"))
	ex.position = base_pos + Vector2(-60, -118)
	ex.size = Vector2(120, 20)
	ex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ground.add_child(ex)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_collision()
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

# The barrier rectangles (solid).
func _barriers() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i in barrier_x.size():
		var x: float = barrier_x[i]
		if i % 2 == 0:
			out.append(Rect2(x - 32.0, 0.0, 64.0, gap_bottom.x))
		else:
			out.append(Rect2(x - 32.0, gap_top.y, 64.0, world_size.y - gap_top.y))
	return out

# Real collision: solid world walls and Area2D SLOW ZONES for the craters (polygon of the crater floor from
# data/footprints.json; no collision on the rim).
func _poly(key: String) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in Config.load_json("res://data/footprints.json")[key]["poly"]:
		pts.append(Vector2(p[0], p[1]))
	return pts

func _build_collision() -> void:
	var walls := StaticBody2D.new()
	walls.name = "WorldWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	var w := world_size
	var rects: Array = [Rect2(-64, -64, w.x + 128, 96), Rect2(-64, w.y - 32, w.x + 128, 96), Rect2(-64, -64, 96, w.y + 128), Rect2(w.x - 32, -64, 96, w.y + 128)]
	rects.append_array(_barriers())
	for r in rects:
		var wp := CollisionPolygon2D.new()
		wp.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		wp.add_to_group("footprint_shape")
		walls.add_child(wp)
	add_child(walls)
	for c in crater_centers:
		var area := Area2D.new()
		area.name = "SlowZone"
		area.position = c
		area.collision_layer = 0
		area.collision_mask = 2
		var sp := CollisionPolygon2D.new()
		sp.polygon = _poly("crater_large_slow")
		sp.add_to_group("slow_shape")
		area.add_child(sp)
		area.body_entered.connect(func(_b): crater_count += 1)
		area.body_exited.connect(func(_b): crater_count = maxi(0, crater_count - 1))
		add_child(area)
	add_child(load("res://scripts/debug_overlay.gd").new())

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/player.gd"))
	player.position = base_pos + Vector2(0, 40)
	world.add_child(player)
	player.world_min = Vector2(40, 40)
	player.world_max = world_size - Vector2(40, 36)
	base_speed = Config.data["player"]["player_speed"]
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(world_size.x)
	cam.limit_bottom = int(world_size.y)
	player.add_child(cam)
	player.add_child(load("res://scripts/flashlight.gd").new())
	player.stepped.connect(func(_p): Audio.play("step"))
	arrow = load("res://scripts/pointer_arrow.gd").new()
	player.add_child(arrow)
	prompt = Node2D.new()
	prompt.z_index = 200
	var key := Sprite2D.new()
	key.texture = Art.tex("icon_ekey")
	key.scale = Vector2(0.5, 0.5)
	prompt.add_child(key)
	prompt_label = UIKit.world_label("", 12)
	prompt_label.position = Vector2(-100, 18)
	prompt_label.size = Vector2(200, 16)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_child(prompt_label)
	prompt_bar = ColorRect.new()
	prompt_bar.color = Color("FFD23F")
	prompt_bar.position = Vector2(-16, 38)
	prompt_bar.size = Vector2(0, 3)
	prompt.add_child(prompt_bar)
	prompt.visible = false
	add_child(prompt)

func _build_ui() -> void:
	hud = load("res://scripts/hud.gd").new()
	add_child(hud)
	var ui := CanvasLayer.new()
	ui.layer = 11
	ui.scale = Vector2(2, 2)
	add_child(ui)
	var ic := UIKit.icon("icon_oxygen", 16)
	ic.position = Vector2(4, 22)
	ui.add_child(ic)
	suit_bar = HudBar.new().setup(70, Color("9BE8FF"))
	suit_bar.position = Vector2(22, 22)
	ui.add_child(suit_bar)
	suit_label = UIKit.label("", 8)
	suit_label.position = Vector2(96, 21)
	ui.add_child(suit_label)
	obj_label = UIKit.label("", 8, Color("FFD23F"))
	obj_label.position = Vector2(4, 40)
	ui.add_child(obj_label)
	storm_label = UIKit.label("", 8, Color("FF8080"))
	storm_label.position = Vector2(0, 72)
	UIKit.box(storm_label, 320, 14)
	storm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(storm_label)
	crater_label = UIKit.label(Text.t("ui.in_crater"), 6, Color("FFD23F"))
	crater_label.position = Vector2(0, 140)
	UIKit.box(crater_label, 320, 12)
	crater_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crater_label.visible = false
	ui.add_child(crater_label)

# ------------------------------------------------------------------ rules
func _in_exit() -> bool:
	return player.position.distance_to(base_pos + Vector2(0, 20)) < exit_radius

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
	in_crater = crater_count > 0
	player.speed = base_speed * (Config.data["missions"]["crater_speed_mult"] if in_crater else 1.0)
	crater_label.visible = in_crater
	# suit air
	var drain: float = delta * (Config.data["missions"]["crater_drain_mult"] if in_crater else 1.0)
	suit_left = maxf(0.0, suit_left - drain)
	var frac := suit_left / suit_total
	suit_bar.set_frac(frac)
	suit_label.text = "%d h" % int(ceil(frac * 8.0))
	var low := frac < 0.25
	suit_label.modulate = Color("FF8080") if low else Color.WHITE
	suit_bar.modulate = Color(1, 0.45, 0.45) if (low and int(Time.get_ticks_msec() / 250) % 2 == 0) else Color.WHITE
	if low:
		low_sound_t -= delta
		if low_sound_t <= 0.0:
			Audio.play("suit_o2_low")
			low_sound_t = 2.0
	if suit_left <= 0.0:
		_suit_out()
		return
	_storm_logic()
	_find_target()
	_update_arrow()
	_exit_hold(delta)
	if Input.is_action_just_pressed("interact") and not digging and target != null and not (target is String):
		_use_target()

func _storm_logic() -> void:
	var st = GameState.today()["storm"]
	if st != null and st["in_mission"] and not storm_started and elapsed >= storm_at:
		_start_storm(st)
	if GameState.storm_state == "warning":
		storm_label.text = Text.t("ui.storm_run_outpost")
	else:
		storm_label.text = ""

func _start_storm(st: Dictionary) -> void:
	storm_started = true
	GameState.start_storm_warning(st["size"], st["event"], -1.0, true)   # mission countdown: x0.4, at least 20 s

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
	if target == null and _in_exit():
		target = "exit"
	if target == null or digging:
		prompt.visible = false
		return
	prompt.visible = true
	var p: Vector2 = base_pos + Vector2(0, -50) if (target is String) else target["pos"] + Vector2(0, -50)
	prompt.position = p
	prompt_label.text = _target_text()

func _target_text() -> String:
	if target is String:
		return Text.t("ui.hold_exit")
	match target["type"]:
		"sample": return Text.t("ui.collect_sample")
		"ice": return Text.t("ui.dig_ice")
		"stone": return Text.t("ui.take_stone")
	return ""

# Hold E for 2 s at the exit marker: finishes the mission (or aborts it: samples kept only if the waypoint was reached).
func _exit_hold(delta: float) -> void:
	if target is String and not digging and Input.is_action_pressed("interact"):
		exit_t += delta
		prompt_bar.size.x = 32.0 * clampf(exit_t / exit_hold, 0.0, 1.0)
		if exit_t >= exit_hold:
			_end(objective_done or waypoint_reached, "ui.mission_done" if objective_done else ("ui.mission_result_aborted" if waypoint_reached else "ui.mission_result_lost"))
	else:
		exit_t = 0.0
		prompt_bar.size.x = 0.0

# Yellow pointer arrow circling the player toward the nearest open target, then the exit.
func _update_arrow() -> void:
	var dest := base_pos + Vector2(0, 20)
	var best := 1e9
	if not objective_done:
		for it in items:
			if it["done"] or (it["type"] == "flag" and waypoint_reached):
				continue
			var d: float = player.position.distance_to(it["pos"])
			if d < best:
				best = d
				dest = it["pos"]
	var dist := player.position.distance_to(dest)
	arrow.visible = dist > 80.0
	arrow.rotation = (dest - player.position).angle()
	arrow.position = Vector2(0, -34) + Vector2.from_angle(arrow.rotation) * 24.0

func _use_target() -> void:
	if target == null or target is String:
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

func _suit_out() -> void:
	GameState.damage(Config.data["health"]["suit_empty_damage"])
	Audio.play("hurt")
	_end(false, "ui.suit_empty")

func _on_event(ev_name: String, data: Dictionary) -> void:
	if ending or GameState.game_over:
		return
	# a large/finale storm that hits while you are still out here: mission failed (the game handles the finale itself)
	if ev_name == "storm_hit" and data["failed"]:
		_end(false, "ui.mission_failed")

# Finish: hand the result to GameState (it waits if a storm is still counting down), show it, go back to the Outpost.
# The mission does NOT clear the storm: walk to the shelter at the Outpost.
func _end(success: bool, msg_key: String) -> void:
	if ending:
		return
	ending = true
	GameState.clock_running = false
	var st = GameState.today()["storm"]
	if st != null and st["in_mission"] and not storm_started and GameState.storm_state == "none":
		_start_storm(st)                       # you were quick: the planned storm starts now, at the Outpost
	GameState.submit_mission(kind, success)
	GameState.outpost_spawn = Vector2(640, 800)
	var m := MenuModal.new()
	m.title_text = Text.t("ui.mission_done") if success else Text.t("ui.mission_failed")
	m.items = [{"icon": "icon_research" if success else "icon_storm", "text": Text.t("ui.ok"), "sub": Text.t(msg_key),
		"call": func(): get_tree().change_scene_to_file("res://scenes/Outpost.tscn")}]
	m.menu_width = 250.0
	add_child(m)
	m.build()
