# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends Node
# Audio autoload. Sounds are wired BY FILE NAME: Audio.play("step") plays audio/sfx/step.wav (or .ogg/.mp3).
# A missing file is skipped silently. Ambience only (no music): suit_breath, hab_hum, recycler_hum
# (audio/ambience/<name>.ogg|wav). ALL ambience goes silent while a storm warning is active. M mutes everything.
# Buses (made here): SFX, Outdoor (SFX with a low-pass: the Moon is silent, you hear through the suit), Ambience.

const SFX_DIR := "res://audio/sfx/"
const AMB_DIR := "res://audio/ambience/"
const EXTS := ["wav", "ogg", "mp3"]
const LOOPS := ["storm_warning"]               # sounds that loop while "on"

var outdoor := false                          # true on missions: sounds go through the low-pass bus
var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _loops := {}                              # name -> AudioStreamPlayer
var _amb := {}                                # name -> {player, target}
var _levels := {}                             # requested ambience volumes (0..1) from the scene
var _muted := false
var _last_ms := {}                            # sound -> last start time (anti-spam, 60 ms)
var _duck_t := 0.0                            # ambience ducks 6 dB while this is > 0
const VARY := ["step", "sample_pickup", "ui_click"]
const IMPORTANT := ["hurt", "lander_touchdown", "success", "fail", "sample_pickup", "interact_done", "warning_low", "suit_o2_low", "harvest", "waypoint_reached", "rare_stone"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("SFX")
	_make_bus("Outdoor")
	_make_bus("Ambience")
	_make_bus("Alarm")
	# mix: SFX -6 dB, Ambience -18 dB, the storm alarm and storm hit (Alarm bus) the loudest at 0 dB
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -6.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Outdoor"), -6.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), -18.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Alarm"), 0.0)
	var out_idx := AudioServer.get_bus_index("Outdoor")
	if AudioServer.get_bus_effect_count(out_idx) == 0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 3200.0
		AudioServer.add_bus_effect(out_idx, lp)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM      # real streams: bus effects (low-pass) and loops work on the web too
		add_child(p)
		_pool.append(p)
	for n in ["suit_breath", "hab_hum", "recycler_hum"]:
		var s := _load(AMB_DIR + n)
		if s != null:
			_loopify(s)
			var p := AudioStreamPlayer.new()
			p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
			p.stream = s
			p.bus = "Ambience"
			p.volume_db = -80.0
			add_child(p)
			p.play()
			_amb[n] = {"player": p, "vol": 0.0}
	# central sounds for state events
	GameState.event.connect(_on_event)
	GameState.notice.connect(func(k): Audio.play("warning_low" if k in ["pack_low", "water_low", "oxygen_low", "blackout"] else "notice"))

func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

func _load(path_no_ext: String) -> AudioStream:
	if _streams.has(path_no_ext):
		return _streams[path_no_ext]
	var s: AudioStream = null
	for e in EXTS:
		var p: String = path_no_ext + "." + e
		if ResourceLoader.exists(p):
			s = load(p)
			break
	_streams[path_no_ext] = s            # null is cached too: a missing file is skipped silently
	return s

func _loopify(s: AudioStream) -> void:
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / (4 if s.stereo else 2) if s.format == AudioStreamWAV.FORMAT_16_BITS else s.data.size()
	elif "loop" in s:
		s.loop = true

# Play a sound effect once.
func play(sound_name: String) -> void:
	var s := _load(SFX_DIR + sound_name)
	if s == null:
		return
	if sound_name in LOOPS:
		loop(sound_name, true)
		return
	# no spam: the same sound at most once every 60 ms, and at most 2 copies playing at once
	var now := Time.get_ticks_msec()
	if now - int(_last_ms.get(sound_name, -1000)) < 60:
		return
	var copies := 0
	for p in _pool:
		if p.playing and p.get_meta("sound", "") == sound_name:
			copies += 1
	if copies >= 2:
		return
	_last_ms[sound_name] = now
	if sound_name in IMPORTANT:
		_duck_t = 0.4
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.set_meta("sound", sound_name)
			# missions: the muffled Outdoor bus; in the outpost: the normal SFX bus; storm alarm and hit: the Alarm bus
			p.bus = "Alarm" if sound_name in ["storm_warning", "storm_hit"] else ("Outdoor" if outdoor else "SFX")
			p.pitch_scale = randf_range(0.95, 1.05) if sound_name in VARY else 1.0       # +-5% variation
			p.volume_db = 0.0                    # loudness is set per group in the files (tools/make_sfx.py)
			p.play()
			return

# Start / stop a looping sound (storm_warning loops during the countdown).
func loop(sound_name: String, on: bool) -> void:
	if on:
		if _loops.has(sound_name):
			return
		var s := _load(SFX_DIR + sound_name)
		if s == null:
			return
		_loopify(s)
		var p := AudioStreamPlayer.new()
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		p.stream = s
		p.bus = "Alarm" if sound_name == "storm_warning" else "SFX"
		add_child(p)
		p.play()
		_loops[sound_name] = p
	elif _loops.has(sound_name):
		_loops[sound_name].queue_free()
		_loops.erase(sound_name)

# Scenes ask for ambience volumes, e.g. {"suit_breath": 1.0, "hab_hum": 0.5}. Storms override (silence).
func ambience(levels: Dictionary) -> void:
	_levels = levels

func _process(delta: float) -> void:
	_duck_t = maxf(0.0, _duck_t - delta)
	var storm: bool = GameState.storm_state == "warning"
	for n in _amb:
		var target: float = 0.0 if storm else float(_levels.get(n, 0.0))
		var a: Dictionary = _amb[n]
		if _duck_t > 0.0 and not storm:
			target *= 0.5                    # duck about 6 dB under important effects
		a["vol"] = move_toward(a["vol"], target, delta * 2.0)      # 0.5 s fades in and out
		a["player"].volume_db = linear_to_db(maxf(a["vol"], 0.0001))      # the Ambience bus is at -18 dB
	if not storm and _loops.has("storm_warning"):
		loop("storm_warning", false)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("mute"):
		_muted = not _muted
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), _muted)

func _on_event(ev_name: String, data: Dictionary) -> void:
	match ev_name:
		"hurt":
			if data.get("amount", 0.0) >= 1.0:
				play("hurt")
		"shadow": play("shadow_start")
		"sunrise": play("sunrise")
		"day_start": play("day_start")
		"blackout": play("power_down")
		"storm_clear": loop("storm_warning", false); play("storm_clear")
		"building_unlock": play("building_unlock")
