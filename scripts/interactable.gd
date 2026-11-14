# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
class_name Interactable
extends Node2D
# Put this on any node (origin = bottom centre of a building) to make it usable with E.
# Edit the exported values in the editor: radius = how close the player must be, hold = seconds to hold E.
@export var kind := ""            # habitat, recycler, tray, console, panel, charger, lab, board, pad, shelter, crew_lander
@export var index := 0            # panel group number (0-3)
@export var radius := 48.0
@export var hold := 0.0
@export var unlock_key := ""      # key in config.json "unlock_day" (empty = always open)
@export var prompt_key := ""      # text key shown near the E icon (e.g. "ui.drink")
@export var prompt_offset := Vector2(0, -40)

func _ready() -> void:
	add_to_group("interactable")

func is_open() -> bool:
	if kind == "shelter":                       # the shelter opens only while a storm warning is active
		return GameState.storm_state == "warning"
	return unlock_key == "" or GameState.is_unlocked(unlock_key)

func unlock_day() -> int:
	return int(Config.data["unlock_day"].get(unlock_key, 1))
