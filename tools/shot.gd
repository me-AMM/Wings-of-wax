extends SceneTree
# Takes a screenshot of a scene for quick visual checks (needs a window, not --headless).
# godot --path . -s tools/shot.gd -- res://scenes/Outpost.tscn out.png [setup_name]
var frames := 0
var out_path := "res://build/shot.png"
var scene_node: Node

var args: PackedStringArray

func _initialize() -> void:
	args = OS.get_cmdline_user_args()

func _start() -> void:
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/Outpost.tscn"
	if args.size() > 1:
		out_path = args[1]
	var setup: String = args[2] if args.size() > 2 else ""
	var gs = root.get_node("GameState")
	gs.new_game()
	match setup:
		"day2":
			gs.day = 2
			gs._start_day(false)
		"day3":
			gs.day = 3
			gs._start_day(false)
		"day4":
			gs.day = 4
			gs._start_day(false)
			gs.advance(1.5)
		"shadow":
			gs.day = 11
			gs._start_day(false)
	scene_node = load(scene_path).instantiate()
	root.add_child(scene_node)
	if args.size() > 4 and scene_node.has_node("World/Player"):
		scene_node.get_node("World/Player").position = Vector2(float(args[3]), float(args[4]))

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		_start()
	if frames == 160:
		var img := root.get_texture().get_image()
		img.save_png(out_path)
		print("saved ", out_path, " ", img.get_size())
		quit()
	return false
