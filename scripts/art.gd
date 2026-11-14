extends Node
# Art autoload: finds textures and builds SpriteFrames BY NAME from assets/manifest.json.
# Art.tex("habitat")  ->  Texture2D        Art.frames("dust_puff") -> SpriteFrames (animation "default")
# Art.astronaut_frames("a") -> SpriteFrames with walk_left, idle_front, interact_front, dig_front ...

var manifest: Dictionary = {}
var _cache := {}

func _init() -> void:
	manifest = Config.load_json("res://assets/manifest.json")

func tex(still_name: String) -> Texture2D:
	if _cache.has(still_name):
		return _cache[still_name]
	var entry = manifest.get("stills", {}).get(still_name)
	var t: Texture2D = null
	if still_name.begins_with("icon_"):          # 32x32 box-downscaled copies (resized by script)
		var dp := "res://assets_derived/icons32/" + still_name + ".png"
		if ResourceLoader.exists(dp):
			t = load(dp)
	if t == null and entry != null:
		t = load("res://assets/" + entry["path"])
	if t == null:
		push_warning("Missing sprite: " + still_name)
		var g := GradientTexture2D.new()      # visible magenta placeholder
		g.width = 32
		g.height = 32
		g.gradient = Gradient.new()
		g.gradient.colors = PackedColorArray([Color.MAGENTA, Color.MAGENTA])
		t = g
	_cache[still_name] = t
	return t

func _add_clip(sf: SpriteFrames, clip: String, anim_name: String) -> void:
	var a = manifest["animations"].get(anim_name)
	if a == null:
		push_warning("Missing animation: " + anim_name)
		return
	sf.add_animation(clip)
	sf.set_animation_speed(clip, float(a["fps_suggested"]))
	sf.set_animation_loop(clip, bool(a["loop"]))
	for f in a["frames"]:                      # frames are listed by name in the manifest
		sf.add_frame(clip, load("res://assets/" + f))

func _empty() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	return sf

# One clip called "default".
func frames(anim_name: String) -> SpriteFrames:
	var sf := _empty()
	_add_clip(sf, "default", anim_name)
	return sf

func astronaut_frames(letter: String) -> SpriteFrames:
	var sf := _empty()
	var prefix := "astronaut_" + letter + "_"
	for key in manifest["animations"]:
		if key.begins_with(prefix):
			_add_clip(sf, key.substr(prefix.length()), key)
	return sf

# Anchor of an animation (point that should sit on the node position).
func anchor(anim_name: String) -> Vector2:
	var a = manifest["animations"].get(anim_name)
	return Vector2(a["anchor"][0], a["anchor"][1]) if a != null else Vector2.ZERO
