"""Generates scenes/Outpost.tscn (and the tiny overlay scenes) as text.
Run: python tools/footprints.py && python tools/make_outpost.py
Footprints (StaticBody2D "Footprint" with a CollisionPolygon2D) come from data/footprints.json.
After the first run, edit the scene in the Godot editor. Do NOT re-run this if you changed the scene by hand."""
import json, pathlib, random

root = pathlib.Path(__file__).resolve().parent.parent
man = json.load(open(root / "assets" / "manifest.json"))
stills = man["stills"]
fps = json.load(open(root / "data" / "footprints.json"))

ext = {}
ext_lines = []

def res(path, typ):
    if path not in ext:
        ext[path] = str(len(ext) + 1)
        ext_lines.append(f'[ext_resource type="{typ}" path="{path}" id="{ext[path]}"]')
    return f'ExtResource("{ext[path]}")'

def tex(name):
    return res("res://assets/" + stills[name]["path"], "Texture2D")

def script(name):
    return res(f"res://scripts/{name}.gd", "Script")

nodes = []

def node(name, typ, parent=None, groups=None, **props):
    head = f'[node name="{name}" type="{typ}"'
    if parent:
        head += f' parent="{parent}"'
    if groups:
        head += ' groups=[' + ", ".join(f'"{g}"' for g in groups) + ']'
    lines = [head + "]"]
    for k, v in props.items():
        lines.append(f"{k} = {v}")
    nodes.append("\n".join(lines))

def poly_str(pts):
    return "PackedVector2Array(" + ", ".join(f"{p[0]}, {p[1]}" for p in pts) + ")"

def footprint(parent_path, key):
    """Real collision shape under a node: StaticBody2D 'Footprint' + CollisionPolygon2D 'Shape'."""
    if key not in fps:
        return
    node("Footprint", "StaticBody2D", parent_path, collision_layer=1, collision_mask=0)
    node("Shape", "CollisionPolygon2D", parent_path + "/Footprint", groups=["footprint_shape"], polygon=poly_str(fps[key]["poly"]))

def building(name, still, x, y, kind, radius=48, hold=0.0, unlock="", prompt="", index=0, poff=(0, -40), parent="World", fp_key="auto"):
    w, h = stills[still]["size"]
    node(name, "Node2D", parent, position=f"Vector2({x}, {y})", script=script("interactable"),
         kind=f'"{kind}"', index=index, radius=float(radius), hold=float(hold),
         unlock_key=f'"{unlock}"', prompt_key=f'"{prompt}"', prompt_offset=f"Vector2({poff[0]}, {poff[1]})")
    node("Sprite2D", "Sprite2D", f"{parent}/{name}", texture=tex(still), centered="false", offset=f"Vector2({-w // 2}, {-h})")
    footprint(f"{parent}/{name}", still if fp_key == "auto" else fp_key)

def decor(name, still, x, y, parent="World", solid=False):
    w, h = stills[still]["size"]
    node(name, "Node2D", parent, position=f"Vector2({x}, {y})")
    node("Sprite2D", "Sprite2D", f"{parent}/{name}", texture=tex(still), centered="false", offset=f"Vector2({-w // 2}, {-h})")
    if solid:
        footprint(f"{parent}/{name}", still)

def tiled(name, still, x, y, w, h, parent):
    node(name, "TextureRect", parent, layout_mode=0, offset_left=float(x), offset_top=float(y),
         offset_right=float(x + w), offset_bottom=float(y + h), texture=tex(still), expand_mode=1, stretch_mode=1)

W, H = 1280, 960
node("Outpost", "Node2D", script=script("outpost"))
node("Dark", "CanvasModulate", ".")
node("Ground", "Node2D", ".")
tiled("GroundFill", "ground_1", 0, 0, W, H, "Ground")
tiled("PathEast", "path", 250, 440, 830, 64, "Ground")
tiled("PathToPad", "path", 608, 504, 64, 230, "Ground")
tiled("PathToSolar", "path", 250, 200, 700, 64, "Ground")
rng = random.Random(7)
keep_out = [(230, 120, 1100, 300), (250, 230, 1090, 520), (530, 560, 760, 800)]
def free(x, y):
    return not any(a <= x <= c and b <= y <= d for a, b, c, d in keep_out)
n = 0
while n < 26:
    x, y = rng.randrange(1, 19) * 64, rng.randrange(1, 14) * 64
    if free(x + 32, y + 32):
        node(f"Patch{n}", "Sprite2D", "Ground", position=f"Vector2({x}, {y})", texture=tex(rng.choice(["ground_2", "ground_3"])), centered="false")
        n += 1
# craters in the outpost are walkable decoration (no collision)
for i, (cx, cy) in enumerate([(200, 700), (1050, 820), (260, 300)]):
    node(f"Crater{i}", "Sprite2D", "Ground", position=f"Vector2({cx}, {cy})", texture=tex("crater_small"))
# boulder wall: visible strips + solid invisible walls at the world limits (see WorldWalls)
tiled("WallTop", "boulder_wall", 0, 0, W, 64, "Ground")
tiled("WallBottom", "boulder_wall", 0, H - 64, W, 64, "Ground")
tiled("WallLeft", "boulder_wall", 0, 0, 64, H, "Ground")
tiled("WallRight", "boulder_wall", W - 64, 0, 64, H, "Ground")
node("WorldWalls", "StaticBody2D", ".", collision_layer=1, collision_mask=0)
for nm, (x0, y0, x1, y1) in {"Top": (-64, -64, W + 64, 64), "Bottom": (-64, H - 64, W + 64, H + 64),
                              "Left": (-64, -64, 64, H + 64), "Right": (W - 64, -64, W + 64, H + 64)}.items():
    node("Wall" + nm, "CollisionPolygon2D", "WorldWalls", groups=["footprint_shape"], polygon=poly_str([(x0, y0), (x1, y0), (x1, y1), (x0, y1)]))

node("World", "Node2D", ".", y_sort_enabled="true")
# --- buildings: origin = bottom centre of the sprite; hold = seconds to hold E ---
building("Habitat", "habitat", 640, 440, "habitat", 62, 0, "habitat", "ui.habitat", poff=(0, -24))
building("Recycler", "water_recycler", 470, 440, "recycler", 55, 0, "recycler", "ui.drink", poff=(0, -24))
# greenhouse + tray are ONE unit: the tray sits in front of the door, touching the base. Same action from both.
building("Greenhouse", "greenhouse", 330, 440, "tray", 60, 0, "greenhouse", "", poff=(0, -24))
building("Tray", "radish_empty", 330, 458, "tray", 50, 0, "greenhouse", "", poff=(0, -40))
for i in range(4):
    building(f"Panel{i}", "solar_clean", 300 + 130 * i, 200, "panel", 56, 2.0, "solar", "ui.clean_panel", i, poff=(0, -30))
building("Console", "slider_console", 830, 200, "console", 40, 0, "solar", "ui.sliders", poff=(0, -50))
building("Charger", "charger_full", 910, 200, "charger", 38, 2.0, "solar", "ui.swap_packs", poff=(0, -50))
building("Lab", "science_lab", 940, 440, "lab", 62, 0, "lab", "ui.lab_process", poff=(0, -24))
building("Board", "forecast_board", 1130, 440, "board", 40, 0, "lab", "ui.forecast_board", poff=(0, -50))
building("Pad", "landing_pad", 640, 780, "pad", 70, 0, "pad", "", poff=(0, -120), fp_key="none")   # flat: walkable
building("Shelter", "shelter", 1130, 660, "shelter", 60, 0, "shelter", "ui.enter_shelter", poff=(0, -40))
building("CrewLander", "crew_lander", 900, 780, "crew_lander", 70, 0, "", "ui.crew_lander", poff=(0, -60))
decor("Antenna", "antenna", 790, 390, solid=True)
for i in range(14):
    x, y = rng.randrange(120, 1160), rng.randrange(120, 880)
    if free(x, y) and not (100 < x < 360 and y > 600):
        big = rng.random() < 0.5
        decor(f"Rock{i}", "rocks_2" if big else "rocks_1", x, y, solid=big)     # big rocks solid, small ones decoration
# --- player: CharacterBody2D with a small circle at the feet (made in player.gd) ---
node("Player", "CharacterBody2D", "World", position="Vector2(640, 492)", script=script("player"), collision_layer=2, collision_mask=1)
node("Camera2D", "Camera2D", "World/Player", limit_left=0, limit_top=0, limit_right=W, limit_bottom=H)

out = ["[gd_scene load_steps=%d format=3]" % (len(ext) + 1), ""] + ext_lines
text = "\n\n".join(["\n".join(out)] + nodes) + "\n"
(root / "scenes" / "Outpost.tscn").write_text(text, encoding="utf-8")
print("Outpost.tscn written with", len(nodes), "nodes")

for scene, scr in [("InfoCard", "info_card"), ("HabitatMenu", "habitat_menu"), ("SliderPanel", "slider_panel")]:
    (root / "scenes" / f"{scene}.tscn").write_text(
        f'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/{scr}.gd" id="1"]\n\n'
        f'[node name="{scene}" type="CanvasLayer"]\nscript = ExtResource("1")\n', encoding="utf-8")
