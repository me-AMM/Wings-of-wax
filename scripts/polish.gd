# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Quick visuals, code only (no new art): soft contact shadows, camera smoothing, vignette, slow blinking lights on the
# charger / recycler / lab, an occasional sparkle on the solar panels, and a screen shake helper.
# Added by the Outpost and Mission scenes:  polish.setup(self, player, "outpost" or "mission")

static var _shadow_tex: Texture2D
static var _dot_tex: Texture2D

var host: Node
var player: Node2D
var cam: Camera2D
var vignette: TextureRect
var sparkle_t := 3.0
var panels: Array = []

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]    # 4x4 ordered dither, pixel-art soft edges
const SHADOW_ALPHA := 0.45        # contact shadow core
const SHADOW_FLAT := 0.25         # contact shadow height / width
const DIRT_ALPHA := 0.38          # dark dirt patch under buildings
const DIRT_WIDE := 1.18           # dirt patch width / ground-contact width
# POLAR SUN: at the south pole the Sun circles low on the horizon, so shadows are long and turn once a day.
const SUN_ALPHA := 0.27           # long shadow darkness
const SUN_LENGTH := 1.5           # shadow length / object height
const SUN_MAX := 44.0             # longest shadow in px (big domes would cast a huge grey blob otherwise)
const SUN_FLAT := 0.55            # top-down view squashes the north-south part of the direction
const SUN_PHASE := 0.0            # turn the whole clock (radians) if the shadows point the wrong way at 06:00
var sun_group: CanvasGroup        # all long shadows: drawn as one layer, so overlaps never get darker
var sun_items: Array = []         # [shadow Sprite2D, node] pairs
var player_sun: Sprite2D
# BOOT PRINTS: the astronaut leaves a small print every PRINT_STEP px that fades over PRINT_FADE s (outpost only)
const PRINT_STEP := 10.0
const PRINT_FADE := 30.0
const PRINT_MAX := 120            # oldest prints are removed first (keeps the Web build cheap)
var print_layer: Node2D
var last_print := Vector2.INF
var print_side := 1.0
static var _shadow_cache := {}
static var _bases := {}

# Visual base of every sprite (from assets_derived/bases.json, made by tools/make_derived.py)
static func bases() -> Dictionary:
	if _bases.is_empty():
		var f := FileAccess.open("res://assets_derived/bases.json", FileAccess.READ)
		if f != null:
			_bases = JSON.parse_string(f.get_as_text())
	return _bases

# A flat dithered ellipse, drawn 1:1 so the dither stays crisp. Core alpha, then an ordered-dither edge.
static func ellipse_texture(w: int, h: int, core: float, color: Color, seed_v: int = 0, rough: float = 0.0) -> Texture2D:
	var key := "%d_%d_%s_%s_%d_%s" % [w, h, core, color.to_html(), seed_v, rough]
	if _shadow_cache.has(key):
		return _shadow_cache[key]
	w = maxi(w, 4)
	h = maxi(h, 2)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var bumps: Array = []                 # irregular edge: a few sine bumps around the rim
	for i in 3:
		bumps.append([rng.randf_range(2.0, 5.0), rng.randf_range(0.0, TAU), rng.randf_range(0.04, 0.1) * rough])
	for y in h:
		for x in w:
			var dx := (x + 0.5 - w * 0.5) / (w * 0.5)
			var dy := (y + 0.5 - h * 0.5) / (h * 0.5)
			var r := sqrt(dx * dx + dy * dy)
			var ang := atan2(dy, dx)
			var lim := 1.0
			for bmp in bumps:
				lim -= bmp[2] * (0.5 + 0.5 * sin(ang * round(bmp[0]) + bmp[1]))
			if r > lim:
				continue
			var t := r / lim                          # 0 centre .. 1 rim
			var k := 1.0 if t < 0.55 else 1.0 - (t - 0.55) / 0.45
			var a := core
			if k < 1.0:                               # dithered soft edge: pixel on or off, never blurred
				if k * 16.0 <= BAYER[(y % 4) * 4 + (x % 4)]:
					continue
				a = core * 0.75
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	var tex := ImageTexture.create_from_image(img)
	_shadow_cache[key] = tex
	return tex

# A contact shadow sprite of the given width (flat, dark core, dithered edge), centred on its position.
static func make_shadow(width: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Shadow"
	var w := int(maxf(width, 8.0))
	s.texture = ellipse_texture(w, int(round(w * SHADOW_FLAT)), SHADOW_ALPHA, Color(0.02, 0.02, 0.05))
	s.show_behind_parent = true
	return s

# Where a node's sprite really touches the ground: {pos (local to the node), width}. Null if unknown.
static func sprite_base(sp: Node2D) -> Dictionary:
	if not (sp is Sprite2D) or sp.texture == null:
		return {}
	var b: Dictionary = bases().get(sp.texture.resource_path, {})
	if b.is_empty():
		return {}
	var top_left: Vector2 = sp.position + sp.offset
	if sp.centered:
		top_left -= sp.texture.get_size() * 0.5
	var cx: float = (b["left"] + b["right"] + 1) * 0.5
	return {"pos": top_left + Vector2(cx, b["bottom"] + 1), "width": float(b["right"] - b["left"] + 1),
		"bbox": float(b["bbox_r"] - b["bbox_l"] + 1)}

static func dot_texture() -> Texture2D:
	if _dot_tex == null:
		var g := GradientTexture2D.new()
		g.width = 12
		g.height = 12
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		g.gradient = Gradient.new()
		g.gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_dot_tex = g
	return _dot_tex

func setup(host_node: Node, player_node: Node2D, kind: String) -> void:
	host = host_node
	player = player_node
	# 1. contact shadow under the player
	var ps := make_shadow(20.0)
	ps.position = Vector2(0, -2)          # overlaps the boots (feet are on the origin)
	player.add_child(ps)
	player.move_child(ps, 0)
	player_sun = Sprite2D.new()
	player_sun.name = "SunShadow"
	player_sun.centered = false
	player_sun.show_behind_parent = true
	player_sun.modulate = Color(0.02, 0.02, 0.06, SUN_ALPHA)
	player.add_child(player_sun)
	player.move_child(player_sun, 0)
	# 2. camera smoothing (the project snaps 2D transforms to whole pixels, so the picture stays crisp)
	for c in player.get_children():
		if c is Camera2D:
			cam = c
	if cam != null:
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 9.0
	# 3. vignette
	_build_vignette()
	GameState.changed.connect(_update_vignette)
	_update_vignette()
	_build_grade()
	if kind == "outpost":
		_window_glows()
		_baked_ground()
		_shadows_for_buildings()
		if sun_group != null:                         # one layer: the astronaut's shadow never doubles a building's
			player.remove_child(player_sun)
			player_sun.show_behind_parent = false
			player_sun.modulate = Color(0.02, 0.02, 0.06)
			sun_group.add_child(player_sun)
		_blinking_lights()

func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5                       # under the HUD (layer 10), so the HUD stays fully readable
	add_child(layer)
	var g := GradientTexture2D.new()
	g.width = 160
	g.height = 90
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 1.0)
	g.gradient = Gradient.new()
	g.gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.15)])      # 15% at the edges
	vignette = TextureRect.new()
	vignette.texture = g
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.size = Vector2(640, 360)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vignette)

# warmer in sunlight, cooler on shadow days
func _update_vignette() -> void:
	if vignette != null:
		vignette.modulate = Color(0.2, 0.3, 0.75) if GameState.in_shadow else Color(1.0, 0.72, 0.4)

# GROUND: one baked image (tools/make_ground.py) replaces the tiled ground, the hard-edged path rectangles and the
# ground patches. Craters and boulder walls stay. If the image is missing, the old ground is kept.
func _baked_ground() -> void:
	var ground: Node = host.get_node_or_null("Ground")
	var tex: Texture2D = load("res://assets_derived/ground_outpost.png") if ResourceLoader.exists("res://assets_derived/ground_outpost.png") else null
	if ground == null or tex == null:
		return
	for c in ground.get_children():
		if c.name == "GroundFill" or String(c.name).begins_with("Path") or String(c.name).begins_with("Patch"):
			c.visible = false
	var g := Sprite2D.new()
	g.name = "BakedGround"
	g.texture = tex
	g.centered = false
	ground.add_child(g)
	ground.move_child(g, 0)
	print_layer = Node2D.new()
	print_layer.name = "BootPrints"
	ground.add_child(print_layer)

func _boot_prints() -> void:
	if print_layer == null or player == null:
		return
	var feet := player.global_position
	if last_print == Vector2.INF:
		last_print = feet
		return
	if feet.distance_to(last_print) < PRINT_STEP:
		return
	var dir := (feet - last_print).normalized()
	last_print = feet
	print_side = -print_side                          # left, right, left...
	var side := Vector2(-dir.y, dir.x) * 2.0 * print_side
	var bp := Sprite2D.new()
	bp.texture = ellipse_texture(4, 2, 0.35, Color(0.05, 0.05, 0.08))
	bp.position = (feet + side).round()
	print_layer.add_child(bp)
	var tw := bp.create_tween()
	tw.tween_property(bp, "modulate:a", 0.0, PRINT_FADE)
	tw.tween_callback(bp.queue_free)
	if print_layer.get_child_count() > PRINT_MAX:
		print_layer.get_child(0).queue_free()

# GROUNDING: every building, prop and rock of the Outpost gets a dark dithered dirt patch and a contact shadow,
# both centred on the sprite's real visual base (bases.json) and drawn on the ground layer, under every sprite.
# (Node origins sit below the visual base on purpose: footprints reach down to the origin so y-sort is right.)
func _shadows_for_buildings() -> void:
	var world: Node = host.get_node_or_null("World")
	var ground: Node = host.get_node_or_null("Ground")
	if world == null or ground == null:
		return
	var dirt_layer := Node2D.new()
	dirt_layer.name = "DirtPatches"
	ground.add_child(dirt_layer)
	sun_group = CanvasGroup.new()
	sun_group.name = "SunShadows"
	sun_group.self_modulate = Color(1, 1, 1, SUN_ALPHA)
	ground.add_child(sun_group)
	var shadow_layer := Node2D.new()
	shadow_layer.name = "ContactShadows"
	ground.add_child(shadow_layer)
	for n in world.get_children():
		var sp: Sprite2D = n.get_node_or_null("Sprite2D")
		if sp == null:
			continue
		if n.name in ["Panel0", "Panel1", "Panel2", "Panel3"]:
			panels.append(n)
		var b := sprite_base(sp)
		if b.is_empty() or n.name == "Pad":          # the pad is flat: no shadow
			continue
		var base: Vector2 = n.position + b["pos"]
		var w: float = b["width"]
		var seed_v := hash(String(n.name))
		var dw := int(w * DIRT_WIDE + 6)
		var dirt := Sprite2D.new()
		dirt.texture = ellipse_texture(dw, int(dw * 0.36), DIRT_ALPHA, Color(0.10, 0.09, 0.09), seed_v, 1.0)
		dirt.position = base + Vector2(0, -2)
		dirt_layer.add_child(dirt)
		var s := make_shadow(w * 1.12)
		s.show_behind_parent = false
		s.position = base + Vector2(0, -3)          # overlaps the bottom 3-4 px of the sprite: no gap
		shadow_layer.add_child(s)
		# long sun shadow: the sprite's own silhouette, skewed along the sun direction (updated in _process)
		var ls := Sprite2D.new()
		ls.texture = sp.texture
		ls.centered = false
		ls.offset = sp.position + sp.offset - b["pos"]          # pixels relative to the visual base
		ls.position = base
		ls.modulate = Color(0.02, 0.02, 0.06)
		sun_group.add_child(ls)
		var hb: Dictionary = bases().get(sp.texture.resource_path, {})
		var height: float = float(hb.get("bottom", 32) - hb.get("top", 0) + 1)
		sun_items.append([ls, sp, minf(SUN_LENGTH, SUN_MAX / height)])
		# follow the node if it is hidden (locked or not landed yet)
		n.visibility_changed.connect(func(): dirt.visible = n.visible; s.visible = n.visible; ls.visible = n.visible)
		dirt.visible = n.visible
		s.visible = n.visible
		ls.visible = n.visible

# WARM GLOWS: small additive warm lights on windows and doors (pixel positions inside the sprite image)
const GLOWS := {"Habitat": [Vector2(48, 122), Vector2(150, 150)], "Lab": [Vector2(130, 88)], "Charger": [Vector2(35, 16)]}
const GLOW_COLOR := Color(1.0, 0.78, 0.45, 0.45)
func _window_glows() -> void:
	var world: Node = host.get_node_or_null("World")
	if world == null:
		return
	for nm in GLOWS:
		var n: Node2D = world.get_node_or_null(nm)
		if n == null:
			continue
		var sp: Sprite2D = n.get_node("Sprite2D")
		for px in GLOWS[nm]:
			var g := Sprite2D.new()
			g.texture = dot_texture()
			g.scale = Vector2(2.0, 1.6)
			g.modulate = GLOW_COLOR
			g.position = sp.position + sp.offset + px
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			g.material = mat
			n.add_child(g)
			var tw := g.create_tween().set_loops()      # gentle breathing, never a hard blink
			tw.tween_property(g, "modulate:a", GLOW_COLOR.a * 0.55, 1.8 + randf())
			tw.tween_property(g, "modulate:a", GLOW_COLOR.a, 1.8 + randf())

# COLOUR GRADE: one full-screen shader under the vignette and HUD. Cool shadows, warm highlights, tiny contrast lift.
# Shadow days: deeper blue. Keep it subtle (readability first).
const GRADE_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 shadow_tint = vec3(0.94, 0.98, 1.06);
uniform vec3 light_tint = vec3(1.04, 1.01, 0.95);
uniform float contrast = 1.05;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c *= mix(shadow_tint, light_tint, smoothstep(0.2, 0.75, l));
	c = (c - 0.5) * contrast + 0.5;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""
var grade: ColorRect
func _build_grade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4                       # world below, vignette (5) and HUD (10) above
	add_child(layer)
	grade = ColorRect.new()
	grade.size = Vector2(640, 360)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = GRADE_SHADER
	grade.material = ShaderMaterial.new()
	grade.material.shader = sh
	layer.add_child(grade)
	GameState.changed.connect(_update_grade)
	_update_grade()

func _update_grade() -> void:
	if grade == null:
		return
	var m: ShaderMaterial = grade.material
	if GameState.in_shadow:
		m.set_shader_parameter("shadow_tint", Vector3(0.86, 0.94, 1.14))
		m.set_shader_parameter("light_tint", Vector3(0.98, 1.0, 1.06))
	else:
		m.set_shader_parameter("shadow_tint", Vector3(0.94, 0.98, 1.06))
		m.set_shader_parameter("light_tint", Vector3(1.04, 1.01, 0.95))

# slow blinking lights on the charger, the recycler and the lab
func _blinking_lights() -> void:
	var spots := {"Charger": [Vector2(-6, 8), UIStyle.GOOD], "Recycler": [Vector2(0, 6), UIStyle.INFO], "Lab": [Vector2(-52, 10), UIStyle.DANGER]}
	var world: Node = host.get_node_or_null("World")
	for nm in spots:
		var n: Node2D = world.get_node_or_null(nm)
		if n == null:
			continue
		var sp: Sprite2D = n.get_node("Sprite2D")
		var d := Sprite2D.new()
		d.texture = dot_texture()
		d.modulate = spots[nm][1]
		d.position = Vector2(spots[nm][0].x, sp.offset.y + spots[nm][0].y)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		d.material = mat
		d.z_index = 5
		n.add_child(d)
		var tw := d.create_tween().set_loops()
		tw.tween_property(d, "modulate:a", 0.15, 1.1 + 0.3 * randf())
		tw.tween_property(d, "modulate:a", 1.0, 1.1 + 0.3 * randf())

# ground direction of the shadows: one full turn per 24 game hours
func sun_dir() -> Vector2:
	var a := TAU * GameState.hour / 24.0 + SUN_PHASE
	return Vector2(cos(a), sin(a) * SUN_FLAT)

func _update_sun() -> void:
	var on := not GameState.in_shadow       # shadow days: the Sun is blocked, no long shadows
	var d := -sun_dir()                       # a pixel h above the base lands h * length along the direction
	if sun_group != null:
		sun_group.visible = on
		for it in sun_items:
			var ls: Sprite2D = it[0]
			ls.texture = it[1].texture           # follows texture swaps (dusty panels, empty charger)
			ls.transform = Transform2D(Vector2(1, 0), d * it[2], ls.position)
	if player_sun != null:
		player_sun.visible = on
		var ps: AnimatedSprite2D = null
		for c in player.get_children():
			if c is AnimatedSprite2D:
				ps = c
		if ps != null and ps.sprite_frames != null:
			player_sun.texture = ps.sprite_frames.get_frame_texture(ps.animation, ps.frame)
			player_sun.offset = ps.offset
			player_sun.flip_h = ps.flip_h
			var origin := Vector2.ZERO
			if player_sun.get_parent() == sun_group:      # in the shared layer: follow the player's feet
				origin = player.global_position
			player_sun.transform = Transform2D(Vector2(1, 0), d * SUN_LENGTH, origin)

func _process(delta: float) -> void:
	_update_sun()
	_boot_prints()
	# an occasional sparkle on a solar panel
	if panels.is_empty() or GameState.in_shadow:
		return
	sparkle_t -= delta
	if sparkle_t <= 0.0:
		sparkle_t = randf_range(3.0, 6.0)
		var pn: Node2D = panels[randi() % panels.size()]
		if host.has_method("_effect"):
			host.call("_effect", "sparkle", pn.global_position + Vector2(randf_range(-40, 40), randf_range(-34, -12)), 0.6, true)

# short screen shake (camera offset)
func shake(strength: float = 6.0, seconds: float = 0.35) -> void:
	if cam == null:
		return
	var tw := create_tween()
	var steps := int(seconds / 0.04)
	for i in steps:
		var k := 1.0 - float(i) / steps
		tw.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)
