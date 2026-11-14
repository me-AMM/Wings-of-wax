# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Runs a mission of each kind and finishes it, to catch runtime errors.
var n := 0
var m: Node
var kinds := ["rock", "ice", "finale"]
var ki := 0
func _process(_d: float) -> void:
	n += 1
	if n == 3:
		GameState.new_game()
		GameState.day = 4
		GameState._start_day(false)
		_start()
	if n == 40 and m:
		m.player.position = m.flag_pos
		for it in m.items:
			if it["type"] == "sample":
				m.player.position = it["pos"]
				m.target = it
				m._use_target()
		m.player.position = m.flag_pos
	if n == 50 and m:
		m._find_target()
		for it in m.items:
			if it["type"] == "ice":
				it["done"] = true
				m.ice_done = true
			if it["type"] == "stone":
				it["done"] = true
				m.waypoint_reached = true
		m._check_objective()
		m.player.position = m.base_pos + Vector2(0, 20)
		m._find_target()
		m._use_target()
		print(m.kind, " ending=", m.ending, " pending=", GameState.pending_research, " done_today=", GameState.mission_done_today)
	if n == 55:
		for c in m.get_children():
			if c is Modal:
				c.close_modal()
		m.queue_free()
		ki += 1
		n = 2
		GameState.mission_done_today = false
		if ki >= kinds.size():
			print("OK missions")
			get_tree().quit()
		else:
			GameState.mission_kind = kinds[ki]
			GameState.modal_count = 0
			call_deferred("_start")
func _start() -> void:
	GameState.mission_kind = kinds[ki]
	m = load("res://scenes/Mission.tscn").instantiate()
	get_tree().root.add_child(m)
