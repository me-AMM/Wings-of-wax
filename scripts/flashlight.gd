# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends PointLight2D
# Visual-only flashlight on the player. On during shadow days (and blackouts) so the dark filter stays playable.
@export var light_radius := 150.0

func _ready() -> void:
	var g := GradientTexture2D.new()
	g.width = 256
	g.height = 256
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.gradient = Gradient.new()
	g.gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])          # softer edge: bright core, long gentle fall-off
	g.gradient.colors = PackedColorArray([Color(1, 0.97, 0.88, 1), Color(1, 0.97, 0.88, 0.5), Color(1, 0.97, 0.88, 0)])
	texture = g
	texture_scale = light_radius / 128.0
	energy = 1.1
	position = Vector2(0, -30)
	GameState.changed.connect(_update)
	_update()

func _update() -> void:
	var on: bool = GameState.in_shadow or GameState.blackout
	if on != enabled:
		Audio.play("flashlight")
	enabled = on
