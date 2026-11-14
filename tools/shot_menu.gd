extends Node
var n := 0
var o: Node
func _process(_d: float) -> void:
	n += 1
	if n == 3:
		GameState.new_game()
		GameState.day = 5
		GameState._start_day(false)
		GameState.card_queue.clear()
		o = load("res://scenes/Outpost.tscn").instantiate()
		get_tree().root.add_child(o)
	if n == 20:
		var m = load("res://scenes/HabitatMenu.tscn").instantiate()
		m.outpost = o
		o.add_child(m)
	if n == 40:
		get_viewport().get_texture().get_image().save_png("E:/AMUNi/shot12.png")
		get_tree().quit()
