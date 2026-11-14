# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Save autoload: ONE slot, user://save.json (on the web build user:// lives in the browser, IndexedDB).
# File: {version, checksum, saved_at, data (the state), day_start (the 06:00 state of that day)}.
# - Autosave at the start of every day (06:00) once the game has started. Manual save from the pause menu.
# - JUDGE MODE NEVER TOUCHES THE SAVE: write() refuses while GameState.judge_mode is true (hard guard, here, not in the callers).
# - A missing or damaged file never crashes: read() reports an error and Load Game shows a message.
var path := "user://save.json"      # (tests switch it to a separate file)
const VERSION := 1

func _ready() -> void:
	GameState.event.connect(_on_event)

func _on_event(ev_name: String, _data: Dictionary) -> void:
	if ev_name == "day_start" and GameState.game_started:
		autosave()

func _sum(obj: Dictionary) -> String:
	var body := {"version": obj["version"], "saved_at": obj["saved_at"], "data": obj["data"], "day_start": obj["day_start"]}
	# normalise through JSON first: parsing turns every number into a float, so ints would hash differently otherwise
	var norm = JSON.parse_string(JSON.stringify(body, "", true))
	return JSON.stringify(norm, "", true).md5_text()

func exists() -> bool:
	return FileAccess.file_exists(path)

# "" when saving is possible now, else the text key (ui.*) that says why not.
func can_save(in_mission := false) -> String:
	if GameState.judge_mode:
		return "ui.save_no_judge"
	if in_mission:
		return "ui.save_no_mission"
	if GameState.storm_state == "warning":
		return "ui.save_no_storm"
	return ""

func _write_obj(data: Dictionary) -> bool:
	if GameState.judge_mode:             # HARD GUARD: judge runs never write the save
		return false
	var obj := {"version": VERSION, "saved_at": int(Time.get_unix_time_from_system()), "data": data, "day_start": GameState.day_start_state}
	obj["checksum"] = _sum(obj)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(obj, "", true))
	f.close()
	return true

# Manual save of the current state.
func write(in_mission := false) -> bool:
	if GameState.judge_mode or can_save(in_mission) != "":
		return false
	return _write_obj(GameState.save_dict())

# The 06:00 autosave: data = the day-start state.
func autosave() -> bool:
	if GameState.judge_mode or not GameState.game_started:
		return false
	return _write_obj(GameState.day_start_state.duplicate(true))

# {ok, error, obj}
func read() -> Dictionary:
	if not exists():
		return {"ok": false, "error": "no save"}
	var text := FileAccess.get_file_as_string(path)
	var obj = JSON.parse_string(text)
	if typeof(obj) != TYPE_DICTIONARY:
		return {"ok": false, "error": "damaged"}
	for k in ["version", "checksum", "saved_at", "data", "day_start"]:
		if not obj.has(k):
			return {"ok": false, "error": "damaged"}
	if int(obj["version"]) != VERSION or typeof(obj["data"]) != TYPE_DICTIONARY or typeof(obj["day_start"]) != TYPE_DICTIONARY:
		return {"ok": false, "error": "version"}
	if _sum(obj) != str(obj["checksum"]):
		return {"ok": false, "error": "checksum"}
	if obj["data"].get("judge_mode", false):
		return {"ok": false, "error": "judge state"}       # a judge state is never loaded
	if not obj["data"].has("day"):
		return {"ok": false, "error": "damaged"}
	return {"ok": true, "error": "", "obj": obj}

# {day, saved_at} or {}
func summary() -> Dictionary:
	var r := read()
	if not r["ok"]:
		return {}
	return {"day": int(r["obj"]["data"]["day"]), "saved_at": int(r["obj"]["saved_at"])}

func saved_time_text(unix: int) -> String:
	var bias: int = Time.get_time_zone_from_system()["bias"]
	var dt := Time.get_datetime_dict_from_unix_time(unix + bias * 60)
	return "%02d:%02d" % [dt["hour"], dt["minute"]]

# Load the save into GameState. Returns false (nothing changed) if the file is missing or damaged.
func load_game() -> bool:
	var r := read()
	if not r["ok"]:
		return false
	var obj: Dictionary = r["obj"]
	GameState.new_game()                    # clean state first (also clears judge_mode and time scale)
	GameState.from_dict(obj["data"])
	var ds: Dictionary = obj["day_start"]
	GameState.day_start_state = ds.duplicate(true) if int(ds.get("day", -1)) == GameState.day else GameState.save_dict()
	GameState.game_started = true
	return true
