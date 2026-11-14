extends CharacterBody2D
# Player: walks with arrows / WASD. A CharacterBody2D with a small circle at the feet, so it is stopped by the
# "Footprint" StaticBody2D shapes of buildings and props. Origin = the feet (frame anchor 52,88).
# Speed comes from data/config.json (player.player_speed). Diagonals are normalised.
@export var speed := 85.0
@export var world_min := Vector2(80, 120)      # walking limits (inside the boulder wall)
@export var world_max := Vector2(1200, 900)

signal stepped(pos: Vector2)     # every puff_distance pixels walked (dust puff)
var puff_distance := 96.0
var walked := 0.0
var sprite: AnimatedSprite2D
var facing := "front"
var frozen := false          # true while a menu is open or during fades

func _ready() -> void:
	add_to_group("player")
	speed = Config.data["player"]["player_speed"]
	puff_distance = Config.data["player"]["puff_distance"]
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	shape.name = "FeetShape"
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, -3)
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Art.astronaut_frames(GameState.astronaut)
	sprite.centered = false
	sprite.offset = -Art.anchor("astronaut_a_walk_front")     # feet on the origin
	add_child(sprite)
	sprite.play("idle_front")

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if not frozen and GameState.modal_count == 0:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")   # already normalised
	velocity = dir * speed
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = "right" if dir.x > 0 else "left"
		else:
			facing = "front" if dir.y > 0 else "back"
		var before := position
		move_and_slide()
		position = position.clamp(world_min, world_max)
		walked += position.distance_to(before)
		if walked >= puff_distance:
			walked = 0.0
			stepped.emit(position)
		_play("walk_" + facing)
	else:
		_play("idle_" + facing)

func _play(clip: String) -> void:
	if sprite.animation != clip:
		sprite.play(clip)
	# walking animation follows the walking speed (8 fps at the old 55 px/s -> about 12)
	sprite.speed_scale = Config.data["player"]["walk_anim_fps_scale"] if clip.begins_with("walk") else 1.0

# Play the interact (or dig) animation once for a moment.
func play_action(clip: String = "interact_front", seconds: float = 0.6) -> void:
	if sprite.sprite_frames.has_animation(clip):
		sprite.play(clip)
		frozen = true
		await get_tree().create_timer(seconds).timeout
		frozen = false
		sprite.play("idle_front")
		facing = "front"
