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
const DIRT_ALPHA := 0.30          # dark dirt patch under buildings
const DIRT_WIDE := 1.18           # dirt patch width / ground-contact width
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
	if kind == "outpost":
		_shadows_for_buildings()
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
		var s := make_shadow(w * 1.04)
		s.show_behind_parent = false
		s.position = base + Vector2(0, -3)          # overlaps the bottom 3-4 px of the sprite: no gap
		shadow_layer.add_child(s)
		# follow the node if it is hidden (locked or not landed yet)
		n.visibility_changed.connect(func(): dirt.visible = n.visible; s.visible = n.visible)
		dirt.visible = n.visible
		s.visible = n.visible

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

func _process(delta: float) -> void:
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
