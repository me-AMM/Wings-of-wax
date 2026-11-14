extends Node2D
const PauseMenuScript := preload("res://scripts/pause_menu.gd")
# Outpost: the main map. Buildings are Interactable nodes in the scene (move them in the editor!).
# This script: finds the nearest thing to use, shows the E prompt, runs actions, landers, dust, tint.

@export var card_delay := 2.0             # seconds after a day starts before info cards pop up
@export var lander_point := Vector2(640, 752)   # where the cargo lander touches down (feet)
@export var shadow_tint := Color(0.38, 0.42, 0.7)

@onready var world: Node2D = $World
@onready var player: Node2D = $World/Player
@onready var dark: CanvasModulate = $Dark

var hud: CanvasLayer
var current: Interactable = null
var hold_t := 0.0
var hold_active := false
var hold_done := false
var pending_cards: Array = []
var card_wait := 0.0
var busy := false
var lander_sprite: AnimatedSprite2D
var lander_body: StaticBody2D
var crate: Sprite2D
var locks := {}               # Interactable -> {icon, label}
var prompt: Node2D
var prompt_label: Label
var prompt_key: Sprite2D
var prompt_bar: ColorRect
var prompt_back: ColorRect

func _ready() -> void:
	GameState.clock_running = true
	if not GameState.game_started:
		GameState.game_started = true            # the game has really started: first autosave (day start)
		Save.autosave()
	hud = load("res://scripts/hud.gd").new()
	add_child(hud)
	_build_prompt()
	_build_lander()
	_build_locks()
	player.add_child(load("res://scripts/flashlight.gd").new())
	Audio.outdoor = false
	player.stepped.connect(func(p):
		_effect("dust_puff", p + Vector2(0, -2), 0.5, false)
		Audio.play("step"))
	add_child(load("res://scripts/debug_overlay.gd").new())
	GameState.event.connect(_on_event)
	GameState.card.connect(func(k): GameState.card_queue.append(k))
	add_child(load("res://scripts/storm_warning.gd").new())
	GameState.changed.connect(_refresh_visuals)
	_refresh_visuals()
	card_wait = card_delay
	if GameState.day_intro_pending:
		GameState.emit_day_intro()
	hud.show_day_splash()
	player.position = GameState.outpost_spawn
	GameState.outpost_spawn = Vector2(640, 492)
	_refresh_visuals()

# ------------------------------------------------------------------ building the extras
func _build_prompt() -> void:
	prompt = Node2D.new()
	prompt.z_index = 200
	prompt.visible = false
	add_child(prompt)
	prompt_back = ColorRect.new()                       # small dark panel behind the key icon and the verb
	prompt_back.color = Color(0.04, 0.05, 0.1, 0.78)
	prompt_back.position = Vector2(-90, -14)
	prompt_back.size = Vector2(180, 56)
	prompt.add_child(prompt_back)
	prompt_key = Sprite2D.new()
	prompt_key.texture = Art.tex("icon_ekey")
	prompt_key.scale = Vector2(0.5, 0.5)
	prompt.add_child(prompt_key)
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

func _build_lander() -> void:
	var lander := Node2D.new()
	lander.position = lander_point
	world.add_child(lander)
	lander_sprite = AnimatedSprite2D.new()
	lander_sprite.sprite_frames = Art.frames("cargo_lander_touchdown")
	lander_sprite.centered = false
	lander_sprite.offset = -Art.anchor("cargo_lander_touchdown")
	lander_sprite.visible = false
	lander.add_child(lander_sprite)
	# landed cargo lander is solid (footprint from data/footprints.json; static sprite sits 24 px below the anchor)
	lander_body = StaticBody2D.new()
	lander_body.name = "Footprint"
	lander_body.position = Vector2(0, 24)
	lander_body.collision_layer = 0
	lander_body.collision_mask = 0
	var cp := CollisionPolygon2D.new()
	cp.add_to_group("footprint_shape")
	var pts := PackedVector2Array()
	for p in Config.load_json("res://data/footprints.json")["cargo_lander"]["poly"]:
		pts.append(Vector2(p[0], p[1]))
	cp.polygon = pts
	lander_body.add_child(cp)
	lander.add_child(lander_body)
	crate = Sprite2D.new()
	crate.texture = Art.tex("cargo_crate")
	crate.centered = false
	crate.offset = Vector2(-32, -56)
	crate.position = Vector2(86, 6)
	crate.visible = false
	lander.add_child(crate)

func _build_locks() -> void:
	for it in get_tree().get_nodes_in_group("interactable"):
		if not (it.name in ["Recycler", "Greenhouse", "Console", "Lab", "Pad", "Shelter"]):
			continue               # one lock per building (the tray shares the greenhouse lock)
		var sp: Sprite2D = it.get_node_or_null("Sprite2D")
		if sp == null:
			continue
		var c := sp.offset + sp.texture.get_size() / 2.0
		var ic := Sprite2D.new()
		ic.texture = Art.tex("icon_lock")
		ic.position = c
		ic.scale = Vector2(0.75, 0.75)
		ic.z_index = 50
		it.add_child(ic)
		var lb := UIKit.world_label("", 12)
		lb.position = c + Vector2(-80, 22)
		lb.size = Vector2(160, 18)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.z_index = 50
		it.add_child(lb)
		var back := ColorRect.new()                      # small dark panel behind the lock label
		back.color = Color(0.04, 0.05, 0.1, 0.7)
		back.position = lb.position + Vector2(-4, -1)
		back.size = Vector2(168, 20)
		back.z_index = 49
		it.add_child(back)
		locks[it] = {"icon": ic, "label": lb, "back": back}

# ------------------------------------------------------------------ visuals follow the state
func _refresh_visuals() -> void:
	if not is_inside_tree():
		return
	for it in get_tree().get_nodes_in_group("interactable"):
		var sp: Sprite2D = it.get_node_or_null("Sprite2D")
		if sp == null:
			continue
		var open: bool = it.is_open()
		sp.modulate = Color.WHITE if open else Color(0.45, 0.47, 0.6)
		if it.kind == "panel":
			var step := int(round(GameState.dust[it.index] / 25.0))
			sp.texture = Art.tex(["solar_clean", "solar_dust25", "solar_dust50", "solar_dust75"][clampi(step, 0, 3)])
		elif it.name == "Tray":
			sp.texture = Art.tex("radish_" + GameState.tray_stage())
		elif it.kind == "charger":
			sp.texture = Art.tex("charger_full" if GameState.spare_pack > 0.5 else "charger_empty")
		elif it.kind == "crew_lander":
			it.visible = GameState.finale_cleared      # arrives only after the finale storm has passed
			_set_solid(it.get_node_or_null("Footprint"), it.visible)
		if locks.has(it):
			locks[it]["icon"].visible = not open
			locks[it]["label"].visible = not open
			locks[it]["back"].visible = not open
			locks[it]["label"].text = _lock_text(it)
	crate.visible = not GameState.cargo_waiting.is_empty()
	_set_solid(lander_body, _lander_on_pad())
	if _lander_on_pad() and not lander_sprite.is_playing():
		lander_sprite.visible = true
		lander_sprite.frame = lander_sprite.sprite_frames.get_frame_count("default") - 1
	if GameState.blackout:
		dark.color = Color(0.16, 0.18, 0.32)       # blackout: nearly dark, the flashlight still works
	else:
		dark.color = shadow_tint if GameState.in_shadow else Color.WHITE

func _set_solid(body: Node, on: bool) -> void:
	if body != null:
		body.collision_layer = 1 if on else 0

func _lander_on_pad() -> bool:
	return GameState.day > 4 or (GameState.day == 4 and GameState.hour >= 7.0)

func _on_event(ev_name: String, data: Dictionary) -> void:
	match ev_name:
		"lander":
			_touchdown()
		"day_start":
			hud.show_day_splash()
			card_wait = card_delay
		"panel_cleaned":
			_effect("sparkle", _panel_pos(data["group"]) + Vector2(0, -30), 1.0, true)
		"harvest":
			hud.toast("+%d" % int(data["meals"]), Color("5FC96B"))

func _panel_pos(group: int) -> Vector2:
	for it in get_tree().get_nodes_in_group("interactable"):
		if it.kind == "panel" and it.index == group:
			return it.position
	return player.position

func _touchdown() -> void:
	lander_sprite.visible = true
	lander_sprite.play("default")
	await lander_sprite.animation_finished
	_effect("dust_puff", lander_point + Vector2(0, -4), 2.0, false)
	_effect("dust_puff", lander_point + Vector2(-50, -2), 1.5, false)
	_effect("dust_puff", lander_point + Vector2(50, -2), 1.5, false)
	Audio.play("lander_touchdown")
	_refresh_visuals()

# One-shot effect sprite at a world position (dust_puff, sparkle). Removes itself.
func _effect(anim: String, pos: Vector2, scl: float = 1.0, loop_once_timer: bool = false) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Art.frames(anim)
	s.centered = false
	s.offset = -Art.anchor(anim)
	s.position = pos
	s.scale = Vector2(scl, scl)
	s.z_index = 100
	world.add_child(s)
	s.play("default")
	if loop_once_timer:        # sparkle loops: stop it after a moment
		await get_tree().create_timer(0.8).timeout
		if is_instance_valid(s):
			s.queue_free()
	else:
		await s.animation_finished
		if is_instance_valid(s):
			s.queue_free()

# ------------------------------------------------------------------ every frame
var amb_t := 0.0

# Ambience volumes by distance: suit breath outside, habitat hum near the habitat, recycler hum near the recycler.
func _update_ambience(delta: float) -> void:
	amb_t -= delta
	if amb_t > 0.0:
		return
	amb_t = 0.25
	var levels := {"suit_breath": 0.6}
	for it in get_tree().get_nodes_in_group("interactable"):
		var d: float = player.position.distance_to(it.position)
		if it.name == "Habitat":
			levels["hab_hum"] = clampf(1.0 - d / 260.0, 0.0, 1.0)
		elif it.name == "Recycler" and GameState.sliders[0] >= 1:
			levels["recycler_hum"] = clampf(1.0 - d / 200.0, 0.0, 1.0)
	Audio.ambience(levels)

func _process(delta: float) -> void:
	_update_ambience(delta)
	_clamp_locks()
	GameState.clock_running = GameState.modal_count == 0 and not busy
	player.frozen = busy
	_show_cards(delta)
	if GameState.modal_count > 0 or busy:
		current = null
		prompt.visible = false
		_reset_hold()
		return
	_find_nearest()
	_update_prompt()
	_handle_input(delta)

func _show_cards(delta: float) -> void:
	if card_wait > 0.0:
		card_wait -= delta
		return
	if GameState.card_queue.size() > 0 and GameState.modal_count == 0 and not busy:
		var c: Modal = load("res://scenes/InfoCard.tscn").instantiate()
		c.keys = GameState.card_queue.duplicate()
		GameState.card_queue.clear()
		add_child(c)

func _find_nearest() -> void:
	var best: Interactable = null
	var best_d := 100000.0
	for it in get_tree().get_nodes_in_group("interactable"):
		if not it.visible:
			continue
		var d: float = player.position.distance_to(it.position + Vector2(0, 8))
		if d < it.radius and d < best_d:
			best = it
			best_d = d
	if best != current:
		_reset_hold()
	current = best

func _lock_text(it: Interactable) -> String:
	if it.kind == "shelter":
		return Text.t("ui.opens_during_storm")
	return "%s %d" % [Text.t("ui.opens_on_day"), it.unlock_day()]

func _prompt_text(it: Interactable) -> String:
	if not it.is_open():
		return _lock_text(it)
	match it.kind:
		"tray":
			if GameState.tray_ready:
				return Text.t("ui.harvest")
			if not GameState.tray_planted:
				return Text.t("ui.plant_radish")
			return Text.t("ui.water_radish") if not GameState.watered_today else Text.t("ui.radish_growing")
		"pad":
			if not GameState.cargo_waiting.is_empty():
				return Text.t("ui.collect_cargo")
			return Text.t("ui.start_mission") if GameState.today()["mission"] != null and not GameState.mission_done_today else ""
		"panel", "charger":
			return Text.t(it.prompt_key)
	return Text.t(it.prompt_key) if it.prompt_key != "" else ""

# Lock labels sit on their building but are kept inside the screen (never clipped by the edge or the HUD strip).
func _clamp_locks() -> void:
	var view: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	if not is_inside_tree():
		return
	for it in locks:
		if not is_instance_valid(it):
			continue
		var d: Dictionary = locks[it]
		if not is_instance_valid(d["label"]) or not d["label"].visible:
			continue
		var sp: Sprite2D = it.get_node("Sprite2D")
		var c: Vector2 = it.global_position + sp.offset + sp.texture.get_size() / 2.0 + Vector2(0, 22)
		var lbl_w := 160.0
		c.x = clampf(c.x, view.position.x + lbl_w / 2.0 + 6.0, view.end.x - lbl_w / 2.0 - 6.0)
		c.y = clampf(c.y, view.position.y + 56.0, view.end.y - 70.0)
		d["label"].global_position = c - Vector2(lbl_w / 2.0, 0)
		d["back"].global_position = d["label"].global_position + Vector2(-4, -1)

func _update_prompt() -> void:
	if current == null:
		prompt.visible = false
		return
	if not current.is_open():                           # a locked building shows its lock label only
		prompt.visible = false
		return
	prompt.visible = true
	# keep the prompt inside the visible screen (below the HUD strip)
	var view: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	var pp: Vector2 = current.position + current.prompt_offset
	pp.x = clampf(pp.x, view.position.x + 110.0, view.end.x - 110.0)
	pp.y = clampf(pp.y, view.position.y + 66.0, view.end.y - 70.0)
	prompt.position = pp
	prompt_label.text = _prompt_text(current)
	prompt_key.visible = current.is_open()
	prompt_bar.size.x = 32.0 * (hold_t / current.hold) if (hold_active and current.hold > 0.0) else 0.0

func _reset_hold() -> void:
	hold_t = 0.0
	hold_active = false
	hold_done = false

func _handle_input(delta: float) -> void:
	if current == null:
		return
	if Time.get_ticks_msec() - GameState.last_modal_close_ms < 300:
		return
	if not current.is_open():
		if Input.is_action_just_pressed("interact"):
			hud.toast(Text.t("ui.shelter_closed") if current.kind == "shelter" else _lock_text(current))
		return
	if current.hold <= 0.0:
		if Input.is_action_just_pressed("interact"):
			do_interact(current)
		return
	# hold-to-act
	if Input.is_action_pressed("interact") and not hold_done:
		hold_active = true
		hold_t += delta
		if hold_t >= current.hold:
			hold_done = true
			hold_active = false
			Audio.play("interact_done")
			do_interact(current)
	elif not Input.is_action_pressed("interact"):
		_reset_hold()

# ------------------------------------------------------------------ actions
func do_interact(it: Interactable) -> void:
	match it.kind:
		"habitat":
			var m = load("res://scenes/HabitatMenu.tscn").instantiate()
			m.outpost = self
			add_child(m)
		"recycler":
			if GameState.drink() == "":
				hud.toast(Text.t("ui.drank"), Color("9BE8FF"))
				Audio.play("drink")
			else:
				hud.toast(Text.t("ui.drank"))
		"tray":
			_use_tray()
		"console":
			add_child(load("res://scenes/SliderPanel.tscn").instantiate())
		"panel":
			GameState.clean_panel(it.index)
			GameState.advance(Config.data["power"]["clean_hours_per_group"])
			Audio.play("clean_panel")
		"charger":
			GameState.swap_packs()
			Audio.play("pack_swap")
			hud.toast(Text.t("ui.pack_base") + " %d%%" % int(round(GameState.base_pack)), Color("9BE8FF"))
		"lab":
			var g := GameState.process_samples()
			if g > 0.0:
				hud.toast("+%s%% %s" % [str(snappedf(g, 0.1)), Text.t("ui.research")], Color("8A5CF5"))
				Audio.play("lab_process")
			else:
				hud.toast(Text.t("ui.lab_nothing"))
		"board":
			_read_board()
		"pad":
			_use_pad()
		"shelter":
			do_shelter()
		"crew_lander":
			pass                                      # nothing to do: it takes you home by itself

func _use_tray() -> void:
	if GameState.tray_ready:
		GameState.harvest_radish()
		GameState.water_radish()
		Audio.play("harvest")
	elif not GameState.tray_planted:
		GameState.plant_radish()
		GameState.water_radish()
		hud.toast(Text.t("ui.plant_radish"), Color("5FC96B"))
		Audio.play("plant")
	elif GameState.water_radish() == "":
		hud.toast(Text.t("ui.water_radish"), Color("9BE8FF"))
		Audio.play("water_radish")
	else:
		hud.toast(Text.t("ui.radish_growing"))

func _use_pad() -> void:
	if GameState.collect_cargo():
		hud.toast(Text.t("ui.collect_cargo"), Color("FFD23F"))
		Audio.play("sample_pickup")
		return
	var m = GameState.today()["mission"]
	if m != null and not GameState.mission_done_today:
		start_mission(m)

func start_mission(kind: String) -> void:
	GameState.mission_kind = kind
	if ResourceLoader.exists("res://scenes/Mission.tscn"):
		Scenes.go("res://scenes/Mission.tscn")
	else:
		hud.toast("Mission scene comes in M3")

func _read_board() -> void:
	GameState.outpost_spawn = Vector2(1130, 475)
	Scenes.go("res://scenes/ForecastBoard.tscn")

func do_sleep() -> void:
	busy = true
	await hud.fade_to_black(0.6)
	var r := GameState.sleep()
	Audio.play("sleep")
	await get_tree().create_timer(0.5).timeout
	await hud.fade_from_black(0.6)
	busy = false
	if r != "":
		hud.toast(Text.t(r))

func do_gym() -> void:
	player.play_action("interact_front", 1.0)
	var r := GameState.gym()
	if r == "":
		hud.toast("+%d" % int(Config.data["health"]["gym_heal"]), Color("FF8080"))
		Audio.play("gym")
	else:
		hud.toast(Text.t(r))

# Shelter: forced sleep until the day ends (counts as the day's sleep).
func do_shelter() -> void:
	if GameState.storm_state != "warning":
		hud.toast(Text.t("ui.shelter_closed"))
		return
	busy = true
	Audio.play("shelter_door")
	await hud.fade_to_black(0.6)
	GameState.shelter_until_day_end()
	await get_tree().create_timer(0.6).timeout
	await hud.fade_from_black(0.8)
	if GameState.finale_cleared:                  # the finale storm passed while you were sheltered
		_crew_touchdown()
		return
	busy = false

# Finale: the crew lander comes down next to the pad, then the extraction scene, then the ending.
func _crew_touchdown() -> void:
	busy = true
	_refresh_visuals()
	var cl: Node2D = $World/CrewLander
	var sp: Sprite2D = cl.get_node("Sprite2D")
	sp.position.y = -360.0
	var tw := create_tween()
	tw.tween_property(sp, "position:y", 0.0, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	Audio.play("lander_touchdown")
	_effect("dust_puff", cl.position + Vector2(-70, -4), 2.0, false)
	_effect("dust_puff", cl.position + Vector2(70, -4), 2.0, false)
	await get_tree().create_timer(1.4).timeout
	await hud.fade_to_black(0.8)
	Scenes.go("res://scenes/Extraction.tscn")

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and GameState.modal_count == 0 and not busy:
		var m := PauseMenuScript.new()
		m.hud = hud
		add_child(m)
		get_viewport().set_input_as_handled()
