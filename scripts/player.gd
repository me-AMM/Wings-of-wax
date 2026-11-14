extends Node2D
# Player: walks with arrows / WASD, animation frames built from the manifest by name.
# The node origin is the astronaut's feet (frame anchor 52,88 sits on it).
@export var speed := 55.0                      # set from config.json (player/walk_speed) at start
@export var world_min := Vector2(80, 120)      # walking limits (inside the boulder wall)
@export var world_max := Vector2(1200, 900)

var sprite: AnimatedSprite2D
var facing := "front"
var blockers: Array = []     # Rect2 footprints the player cannot enter (set by the Outpost)
var frozen := false          # true while a menu is open or during fades

func _ready() -> void:
	speed = Config.data["player"]["walk_speed"]
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Art.astronaut_frames(GameState.astronaut)
	sprite.centered = false
	sprite.offset = -Art.anchor("astronaut_a_walk_front")     # feet on the origin
	add_child(sprite)
	sprite.play("idle_front")

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if not frozen and GameState.modal_count == 0:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = "right" if dir.x > 0 else "left"
		else:
			facing = "front" if dir.y > 0 else "back"
		var step := dir * speed * delta
		var nx := (position + Vector2(step.x, 0)).clamp(world_min, world_max)
		if not _blocked(nx):
			position = nx
		var ny := (position + Vector2(0, step.y)).clamp(world_min, world_max)
		if not _blocked(ny):
			position = ny
		_play("walk_" + facing)
	else:
		_play("idle_" + facing)

func _blocked(p: Vector2) -> bool:
	for r in blockers:
		if r.has_point(p):
			return true
	return false

func _play(clip: String) -> void:
	if sprite.animation != clip:
		sprite.play(clip)

# Play the interact (or dig) animation once for a moment.
func play_action(clip: String = "interact_front", seconds: float = 0.6) -> void:
	if sprite.sprite_frames.has_animation(clip):
		sprite.play(clip)
		frozen = true
		await get_tree().create_timer(seconds).timeout
		frozen = false
		sprite.play("idle_front")
		facing = "front"
