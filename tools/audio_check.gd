extends Node
# Audio check:  godot --headless --path . res://tools/audio_check.tscn
# All Priority 1 files exist, are not silent, peak at about -3 dB, and the ambience loops are seamless (8 s).
var fails := 0
const P1 := ["step", "interact_done", "hurt", "lander_touchdown", "sample_pickup", "storm_warning", "storm_hit", "ui_click", "success", "fail"]
const P2 := ["interact_hold", "clean_panel", "pack_swap", "slider_tick", "harvest", "lab_process", "waypoint_reached", "ice_dig_hit", "suit_o2_low", "shelter_door", "info_card", "warning_low", "star"]
const P3 := ["eat", "drink", "sleep", "gym", "heal", "water_radish", "plant", "building_unlock", "power_down", "mission_start", "ice_dig_miss", "rare_stone", "countdown_tick", "storm_clear", "shadow_start", "sunrise", "flashlight", "ui_hover", "notice", "day_start"]

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

# Reads the raw WAV file (16-bit mono, 44 byte header) so the check does not depend on the import settings.
func samples(path: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var d := FileAccess.get_file_as_bytes(path)
	if d.size() < 46:
		return out
	for i in range(44, d.size() - 1, 2):
		out.append(d.decode_s16(i) / 32768.0)
	return out

func _ready() -> void:
	await get_tree().process_frame
	for n in P1:
		var x := samples("res://audio/sfx/%s.wav" % n)
		var peak := 0.0
		for v in x:
			peak = maxf(peak, absf(v))
		check(x.size() > 100 and peak > 0.2 and peak <= 0.72, "Priority 1 '%s': %d samples (%.0f ms), peak %.2f (%.1f dB)" % [n, x.size(), x.size() * 1000.0 / 22050.0, peak, 20.0 * log(maxf(peak, 0.0001)) / log(10.0)])
	for n in P2 + P3:
		var x := samples("res://audio/sfx/%s.wav" % n)
		var peak := 0.0
		for v in x:
			peak = maxf(peak, absf(v))
		check(x.size() > 50 and peak > 0.1, "'%s' exists and is not silent (peak %.2f)" % [n, peak])
	# the storm alarm loop is 1 s and starts and ends near zero (no click at the loop point)
	var sw := samples("res://audio/sfx/storm_warning.wav")
	check(absf(sw.size() / 22050.0 - 1.0) < 0.01 and absf(sw[sw.size() - 1]) < 0.05 and absf(sw[0]) < 0.05, "storm_warning is a 1 s loop that starts and ends near zero")
	for n in ["suit_breath", "hab_hum", "recycler_hum"]:
		var x := samples("res://audio/ambience/%s.wav" % n)
		var steps := 0.0
		for i in range(1, x.size()):
			steps += absf(x[i] - x[i - 1])
		var avg_step: float = steps / float(x.size() - 1)
		var seam := absf(x[0] - x[x.size() - 1])
		check(absf(x.size() / 22050.0 - 8.0) < 0.05 and seam <= maxf(4.0 * avg_step, 0.01), "loop '%s': 8 s, seam jump %.4f vs average step %.4f" % [n, seam, avg_step])
	print("audio_check FAILS: ", fails)
	get_tree().quit(1 if fails > 0 else 0)
