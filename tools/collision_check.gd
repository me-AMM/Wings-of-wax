extends Node
# Headless collision check for the Outpost (run as a scene):
#   godot --headless --path . res://tools/collision_check.tscn
# For every footprint: centre blocked, a point 12 px outside free, no overlaps, spawn free,
# every interaction point reachable from the spawn (A* on a 4 px grid), and the chore-loop time.
const CELL := 4.0
const MAP := Vector2(1280, 960)
var fails := 0
var space: PhysicsDirectSpaceState2D
var circle := CircleShape2D.new()

func _ready() -> void:
	circle.radius = 5.0
	var o = load("res://scenes/Outpost.tscn").instantiate()
	add_child(o)
	for i in 4:
		await get_tree().physics_frame
	space = get_viewport().world_2d.direct_space_state
	_run(o)
	get_tree().quit(1 if fails > 0 else 0)

func _blocked_point(p: Vector2) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collision_mask = 1
	return space.intersect_point(q, 1).size() > 0

func _blocked_circle(p: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = circle
	q.transform = Transform2D(0, p + Vector2(0, -3))     # same offset as the player's feet shape
	q.collision_mask = 1
	return space.intersect_shape(q, 1).size() > 0

func _poly_world(shape: CollisionPolygon2D) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in shape.polygon:
		pts.append(shape.global_transform * p)
	return pts

func _run(o: Node) -> void:
	var shapes: Array = []
	for s in get_tree().get_nodes_in_group("footprint_shape"):
		if s.get_parent().collision_layer != 0 and s.get_parent().get_parent().name != "Outpost":
			shapes.append(s)
	print("%-12s %-8s %-10s %-8s" % ["object", "centre", "12px out", "reach"])
	# --- per-footprint checks
	for s in shapes:
		var owner_name: String = s.get_parent().get_parent().name
		var pts := _poly_world(s)
		var c := Vector2.ZERO
		var maxy := -1e9
		for p in pts:
			c += p
			maxy = maxf(maxy, p.y)
		c /= pts.size()
		var centre := _blocked_point(c)
		var out_free := not _blocked_circle(Vector2(c.x, maxy + 12.0))
		if not centre or not out_free:
			fails += 1
			print("FAIL %-8s centre blocked=%s outside free=%s" % [owner_name, centre, out_free])
	# --- overlaps (footprints of different owners)
	for i in shapes.size():
		for j in range(i + 1, shapes.size()):
			var a := _poly_world(shapes[i])
			var b := _poly_world(shapes[j])
			if Geometry2D.intersect_polygons(a, b).size() > 0:
				fails += 1
				print("FAIL overlap: ", shapes[i].get_parent().get_parent().name, " x ", shapes[j].get_parent().get_parent().name)
	# --- grid + A*
	var cols := int(MAP.x / CELL)
	var rows := int(MAP.y / CELL)
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, cols, rows)
	astar.cell_size = Vector2(CELL, CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in rows:
		for x in cols:
			if _blocked_circle(Vector2(x, y) * CELL):
				astar.set_point_solid(Vector2i(x, y), true)
	var spawn: Vector2 = o.get_node("World/Player").position
	var sc := Vector2i(spawn / CELL)
	if astar.is_point_solid(sc):
		fails += 1
		print("FAIL spawn is blocked")
	# --- reachability of every interaction point
	var stands := {}
	for it in get_tree().get_nodes_in_group("interactable"):
		if it.radius <= 0.0 or not it.visible:
			continue
		var target: Vector2 = it.global_position + Vector2(0, 8)
		var best := Vector2i(-1, -1)
		var best_d := 1e9
		var r := int(it.radius / CELL)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cell := Vector2i(target / CELL) + Vector2i(dx, dy)
				if not astar.is_in_boundsv(cell) or astar.is_point_solid(cell):
					continue
				if (Vector2(cell) * CELL).distance_to(target) >= it.radius - 2.0:
					continue
				var d := (Vector2(cell) * CELL).distance_to(spawn)
				if d < best_d:
					best_d = d
					best = cell
		var ok := best.x >= 0 and astar.get_id_path(sc, best).size() > 0
		stands[it.name] = best
		print("%-12s %-8s %-10s %-8s r=%d" % [it.name, "blocked" if true else "", "free", "OK" if ok else "FAIL", it.radius])
		if not ok:
			fails += 1
	# --- chore loop: habitat door -> recycler -> greenhouse tray -> solar console -> habitat
	var order := ["Recycler", "Tray", "Console", "Habitat"]
	var cur := sc
	var total := 0.0
	for nm in order:
		var path := astar.get_point_path(cur, stands[nm])
		for k in range(1, path.size()):
			total += path[k].distance_to(path[k - 1])
		cur = stands[nm]
	var speed: float = Config.data["player"]["player_speed"]
	print("chore loop: %d px at %d px/s = %.1f s (target 15-20 s)" % [total, speed, total / speed])
	print("collision_check FAILS: ", fails)
