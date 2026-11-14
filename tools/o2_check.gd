# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Oxygen and blackout rules (docs/02), run headless:  godot --headless --path . res://tools/o2_check.tscn
#  a. life support low for 48 game hours: the reserve falls 12 h per day.
#  b. both packs empty in shadow (blackout): backup life support holds the reserve for 24 game hours, then it falls 2 h per game hour.
#  c. reserve at 0: Health -5 per game hour; Health 0 = failed ending with the "ran out of air" reason.
#  d. a swapped-in charged pack ends the blackout and the normal rules resume.
var fails := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shadow_blackout() -> void:
	GameState.new_game()
	GameState.auto_endings = false
	GameState.day = 11
	GameState._start_day(false)            # day 11: crater-rim shadow, panels make 0 kW
	GameState.base_pack = 0.0
	GameState.spare_pack = 0.0

func _ready() -> void:
	await get_tree().process_frame
	# a. life support low, 48 h in sunlight
	GameState.new_game()
	GameState.auto_endings = false
	GameState.set_slider(0, 0)
	GameState.advance(48.0)
	check(absf(GameState.oxygen_h - 24.0) < 0.6 and not GameState.blackout, "a. life support low, 48 h: reserve 48 -> %.1f h (want 24, -12 per day)" % GameState.oxygen_h)
	# b. blackout: hold 24 h, then -2 h per game hour
	shadow_blackout()
	GameState.advance(0.5)
	check(GameState.blackout, "b. both packs at 0% in shadow: BLACKOUT starts")
	GameState.advance(23.0)
	check(absf(GameState.oxygen_h - 48.0) < 0.1, "b. first 24 h of blackout: backup life support holds the reserve (%.1f h)" % GameState.oxygen_h)
	GameState.advance(10.0)
	check(absf(GameState.oxygen_h - 28.0) < 1.0, "b. after 24 h the reserve falls 2 h per hour: 10 more hours -> %.1f h (want 28)" % GameState.oxygen_h)
	# c. empty reserve hurts, Health 0 = failed ending (reason air)
	shadow_blackout()
	GameState.advance(0.25)
	GameState.oxygen_h = 0.0
	GameState.blackout_hours = 40.0
	GameState.slept_today = true
	var hp := GameState.health
	GameState.advance(4.0)
	check(absf((hp - GameState.health) - 20.0) < 1.5, "c. reserve at 0: Health -5 per hour (%.0f -> %.0f in 4 h)" % [hp, GameState.health])
	var guard := 0
	while not GameState.game_over and guard < 40:
		GameState.slept_today = true
		GameState.advance(1.0)
		guard += 1
	check(GameState.game_over and GameState.game_result == "failed" and GameState.fail_reason == "air", "c. Health reaches 0: failed ending, reason '%s'" % GameState.fail_reason)
	# d. a charged pack ends the blackout
	shadow_blackout()
	GameState.advance(0.25)
	check(GameState.blackout, "d. blackout is on before the swap")
	GameState.spare_pack = 100.0
	GameState.swap_packs()
	GameState.advance(0.5)
	check(not GameState.blackout and GameState.base_pack > 90.0, "d. swapping in a charged pack ends the blackout (base %.0f%%)" % GameState.base_pack)
	var o0 := GameState.oxygen_h
	GameState.set_slider(0, 0)
	GameState.advance(12.0)
	check(absf((o0 - GameState.oxygen_h) - 6.0) < 0.8, "d. normal rules resume: life low, 12 h -> -%.1f h (want 6)" % (o0 - GameState.oxygen_h))
	print("o2_check FAILS: ", fails)
	get_tree().quit(1 if fails > 0 else 0)
