extends Node
# Instantiates every full-screen scene once (Title, CharacterSelect, Story, endings, Credits, Board) to catch errors.
var n := 0
var cur: Node
var list := ["Title", "CharacterSelect", "Story", "EndingSuccess", "EndingFailed", "Credits", "ForecastBoard", "Outpost", "Mission"]
func _process(_d: float) -> void:
	n += 1
	if n == 3:
		GameState.new_game()
		GameState.research = 87.5
		GameState.mission_kind = "ice"
	if n >= 3 and (n - 3) % 12 == 0:
		var i := (n - 3) / 12
		if cur:
			cur.queue_free()
		if i >= list.size():
			print("flow ok")
			get_tree().quit()
			return
		cur = load("res://scenes/%s.tscn" % list[i]).instantiate()
		get_tree().root.add_child(cur)
		print("loaded ", list[i], " stars=", GameState.stars())
