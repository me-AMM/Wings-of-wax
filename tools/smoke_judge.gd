# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Judge functions: jump to days 4, 8, 24, storms, shadow, mission preset.
var n := 0
func _process(_d: float) -> void:
	n += 1
	if n == 3:
		Judge.begin_judge_run()
		for d in [4, 8, 24, 11, 32]:
			Judge.jump_to_day(d)
			print("day ", GameState.day, " research ", GameState.research, " meals ", GameState.meals_left(), " water ", snappedf(GameState.water, 0.1), " shadow ", GameState.in_shadow, " queue ", GameState.queue.size(), " judge ", GameState.judge_mode)
		Judge.jump_to_day(4)
		Judge.trigger_storm("medium")
		print("storm ", GameState.storm_state, " ", GameState.storm_size)
		Judge.land_cargo()
		Judge.start_shadow()
		Judge.refill_all()
		print("speed ", Judge.toggle_speed(), " ", GameState.time_scale)
		Judge.open_panel(true)
	if n == 20:
		print("panel open: ", Judge.panel != null)
		Judge.preset_big_storm()
		get_tree().root.add_child(Node.new())
	if n == 40:
		pass
	if n == 25:
		print("scene: ", get_tree().current_scene.name if get_tree().current_scene else "none", " day ", GameState.day, " kind ", GameState.mission_kind)
		get_tree().quit()
