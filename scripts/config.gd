extends Node
# Config autoload: loads data/config.json (all rule numbers) and data/days.json (the 32-day script).
# Use: Config.data["power"]["panel_kw"]   or   Config.v("power/panel_kw")

var data: Dictionary = {}
var days: Array = []

func _init() -> void:
	data = load_json("res://data/config.json")
	days = load_json("res://data/days.json")

static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Bad JSON in " + path)
		return {}
	return parsed

# Look up "a/b/c" inside config.json.
func v(path: String) -> Variant:
	var cur: Variant = data
	for part in path.split("/"):
		cur = cur[part]
	return cur
