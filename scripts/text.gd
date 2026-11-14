# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Text autoload: ALL player-visible text lives in data/text.json.
# Text.t("ui.start")  ->  "Start".   Text.card("solar") -> {title, body, source}.

var data: Dictionary = {}

func _init() -> void:
	if FileAccess.file_exists("res://data/text.json"):
		data = JSON.parse_string(FileAccess.get_file_as_string("res://data/text.json"))

func t(path: String) -> String:
	var cur: Variant = data
	for part in path.split("."):
		if cur is Dictionary and cur.has(part):
			cur = cur[part]
		else:
			return "[" + path + "]"   # visible marker for a missing string
	return str(cur)

func card(key: String) -> Dictionary:
	return data.get("cards", {}).get(key, {"title": key, "body": "", "source": ""})

func list(path: String) -> Array:
	var cur: Variant = data
	for part in path.split("."):
		cur = cur.get(part, [])
	return cur if cur is Array else []
