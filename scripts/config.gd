# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Config autoload: loads data/config.json (all rule numbers) and data/days.json (the 32-day script).
# Use: Config.data["power"]["panel_kw"]   or   Config.v("power/panel_kw")

var data: Dictionary = {}
var days: Array = []
var donki: Dictionary = {}     # real flares (data/donki_events.json), key = storm slot like "small1"

func _init() -> void:
	data = load_json("res://data/config.json")
	days = load_json("res://data/days.json")
	donki = load_json("res://data/donki_events.json")

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

# "2024-05-03T00:15Z" -> "3 May 2024"
static func nice_date(iso: String) -> String:
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	if iso.length() < 10:
		return iso
	return "%d %s %s" % [int(iso.substr(8, 2)), months[int(iso.substr(5, 2)) - 1], iso.substr(0, 4)]

# Short form for the storm panel footer: "M2.7, 3 May 2024".
func storm_short(slot: String) -> String:
	var e: Dictionary = donki.get(slot, {})
	if e.is_empty():
		return ""
	return "%s, %s" % [e["classType"], nice_date(e["peakTime"])]

# The line shown on every storm banner.
func storm_label(slot: String) -> String:
	var e: Dictionary = donki.get(slot, {})
	if e.is_empty():
		return ""
	var src: String = e.get("source", "NASA DONKI")
	return Text.t("ui.storm_similar") % [e["classType"], nice_date(e["peakTime"]), src]
