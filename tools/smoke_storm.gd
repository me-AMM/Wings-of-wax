# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Day 4: storm after the mission. Checks warning, hit damage, shelter, and the real-event label.
var n := 0
func _process(_d: float) -> void:
	n += 1
	if n == 3:
		GameState.new_game()
		GameState.day = 4
		GameState._start_day(false)
		GameState.advance(11.0)        # to 17:00: warning starts (30 s = 3 h before 20:00)
		print("state ", GameState.storm_state, " label: ", Config.storm_label(GameState.storm_event))
		var o = load("res://scenes/Outpost.tscn").instantiate()
		get_tree().root.add_child(o)
	if n == 20:
		var hp: float = GameState.health
		GameState.advance(4.0)
		print("unsheltered: health ", hp, " -> ", GameState.health, " state ", GameState.storm_state)
		var b = load("res://scenes/ForecastBoard.tscn").instantiate()
		get_tree().root.add_child(b)
	if n == 30:
		GameState.new_game()
		GameState.day = 24
		GameState._start_day(false)
		GameState.start_storm_warning("large", "large1")
		GameState.enter_shelter()
		var h2: float = GameState.health
		GameState.advance(20.0)
		print("large sheltered: ", h2, " -> ", GameState.health)
		get_tree().quit()
