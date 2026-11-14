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

# One shared generated texture: a narrow dark ellipse, 25% alpha, soft edge.
static func shadow_texture() -> Texture2D:
	if _shadow_tex == null:
		var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 64:
				var dx := (x + 0.5 - 32.0) / 32.0
				var dy := (y + 0.5 - 8.0) / 8.0
				var d := dx * dx + dy * dy
				if d <= 1.0:
					img.set_pixel(x, y, Color(0, 0, 0, 0.25 * (1.0 if d < 0.6 else (1.0 - d) / 0.4)))
		_shadow_tex = ImageTexture.create_from_image(img)
	return _shadow_tex

# A contact shadow of the given width, drawn BEHIND its parent's sprite.
static func make_shadow(width: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Shadow"
	s.texture = shadow_texture()
	s.scale = Vector2(maxf(width, 8.0) / 64.0, 0.8)
	s.show_behind_parent = true
	return s

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
	var ps := make_shadow(22.0)
	ps.position = Vector2(0, -1)
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

# every building and prop of the Outpost gets a soft contact shadow, about 60% of its footprint width
func _shadows_for_buildings() -> void:
	var world: Node = host.get_node_or_null("World")
	if world == null:
		return
	for n in world.get_children():
		var sp: Sprite2D = n.get_node_or_null("Sprite2D")
		if sp == null or n.name in ["Pad"]:
			continue
		var shape: CollisionPolygon2D = n.get_node_or_null("Footprint/Shape")
		var width: float = sp.texture.get_size().x * 0.5
		var y := -2.0
		if shape != null:
			var minx := 1e9
			var maxx := -1e9
			var maxy := -1e9
			for p in shape.polygon:
				minx = minf(minx, p.x)
				maxx = maxf(maxx, p.x)
				maxy = maxf(maxy, p.y)
			width = (maxx - minx) * 0.6
			y = maxy - 2.0
		var s := make_shadow(width)
		s.position = Vector2(0, y)
		n.add_child(s)
		n.move_child(s, 0)
		if n.name in ["Panel0", "Panel1", "Panel2", "Panel3"]:
			panels.append(n)

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
