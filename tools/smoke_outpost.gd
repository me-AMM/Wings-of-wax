extends Node
# Calls every interaction once on day 4 and lets time run, to catch runtime errors.
var n := 0
var o: Node
func _process(_d: float) -> void:
	n += 1
	var gs = GameState
	if n == 3:
		gs.new_game()
		gs.day = 4
		gs._start_day(false)
		o = load("res://scenes/Outpost.tscn").instantiate()
		get_tree().root.add_child(o)
	if n == 10:
		gs.advance(1.2)   # lander at 07:00
	if n == 80:
		for it in get_tree().get_nodes_in_group("interactable"):
			if it.kind in ["", "greenhouse", "crew_lander", "board"]:
				continue
			print("interact ", it.kind)
			o.do_interact(it)
		o.hud.toast("test")
		o.hud.say("test notice")
	if n == 100:
		for m in o.get_children():
			if m is Modal:
				m.close_modal()
		gs.advance(3.0)
		o.do_gym()
	if n == 160:
		print("ok: day ", gs.day, " hour ", gs.hour, " meals ", gs.meals_left(), " cargo ", gs.cargo_waiting)
		get_tree().quit()

