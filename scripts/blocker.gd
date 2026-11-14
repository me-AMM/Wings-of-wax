class_name Blocker
extends Node2D
# Solid footprint at the base of a sprite (origin = bottom centre). The player cannot walk into it.
# footprint = (width, height) in pixels; change it in the Inspector. (0, 0) = walkable.
@export var footprint := Vector2.ZERO

func _ready() -> void:
	if footprint != Vector2.ZERO:
		add_to_group("blocker")

func rect() -> Rect2:
	return Rect2(global_position.x - footprint.x / 2.0, global_position.y - footprint.y, footprint.x, footprint.y)
