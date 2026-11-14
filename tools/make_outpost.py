"""Generates scenes/Outpost.tscn (and the tiny overlay scenes) as text.
Run once: python tools/make_outpost.py
After that, edit the scene in the Godot editor. Do NOT re-run this if you changed the scene by hand."""
import json, pathlib, random

root = pathlib.Path(__file__).resolve().parent.parent
man = json.load(open(root / "assets" / "manifest.json"))
stills = man["stills"]

ext = {}      # path -> id
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

def node(name, typ, parent=None, **props):
    lines = [f'[node name="{name}" type="{typ}"' + (f' parent="{parent}"]' if parent else "]")]
    for k, v in props.items():
        lines.append(f"{k} = {v}")
    nodes.append("\n".join(lines))

def building(name, still, x, y, kind, radius=48, hold=0.0, unlock="", prompt="", index=0, poff=(0, -40), parent="World"):
    w, h = stills[still]["size"]
    node(name, "Node2D", parent, position=f"Vector2({x}, {y})", script=script("interactable"),
         kind=f'"{kind}"', index=index, radius=float(radius), hold=float(hold),
         unlock_key=f'"{unlock}"', prompt_key=f'"{prompt}"', prompt_offset=f"Vector2({poff[0]}, {poff[1]})")
    node("Sprite2D", "Sprite2D", f"{parent}/{name}", texture=tex(still), centered="false",
         offset=f"Vector2({-w // 2}, {-h})")

def decor(name, still, x, y, parent="World"):
    w, h = stills[still]["size"]
    node(name, "Sprite2D", parent, position=f"Vector2({x}, {y})", texture=tex(still), centered="false",
         offset=f"Vector2({-w // 2}, {-h})")

def tiled(name, still, x, y, w, h, parent):
    node(name, "TextureRect", parent, layout_mode=0, offset_left=float(x), offset_top=float(y),
         offset_right=float(x + w), offset_bottom=float(y + h), texture=tex(still), expand_mode=1, stretch_mode=1)

W, H = 1280, 960
node("Outpost", "Node2D", script=script("outpost"))
node("Dark", "CanvasModulate", ".")
node("Ground", "Node2D", ".")
tiled("GroundFill", "ground_1", 0, 0, W, H, "Ground")
# paths between buildings
tiled("PathEast", "path", 250, 440, 830, 64, "Ground")
tiled("PathToPad", "path", 608, 504, 64, 230, "Ground")
tiled("PathToSolar", "path", 250, 200, 700, 64, "Ground")
# ground patches and craters (placed by a seeded random, not on buildings)
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
for i, (cx, cy) in enumerate([(200, 700), (1050, 820), (260, 300)]):
    node(f"Crater{i}", "Sprite2D", "Ground", position=f"Vector2({cx}, {cy})", texture=tex("crater_small"))
# boulder wall around the map edge
tiled("WallTop", "boulder_wall", 0, 0, W, 64, "Ground")
tiled("WallBottom", "boulder_wall", 0, H - 64, W, 64, "Ground")
tiled("WallLeft", "boulder_wall", 0, 0, 64, H, "Ground")
tiled("WallRight", "boulder_wall", W - 64, 0, 64, H, "Ground")

node("World", "Node2D", ".", y_sort_enabled="true")
# --- buildings (position = bottom centre; hold = seconds to hold E) ---
building("Habitat", "habitat", 640, 440, "habitat", 62, 0, "habitat", "ui.habitat", poff=(0, -24))
building("Recycler", "water_recycler", 470, 440, "recycler", 55, 0, "recycler", "ui.drink", poff=(0, -24))
building("Tray", "radish_empty", 330, 504, "tray", 40, 0, "greenhouse", "", poff=(0, -40))
building("Greenhouse", "greenhouse", 330, 440, "greenhouse", 0.0, 0, "greenhouse", "")
for i in range(4):
    building(f"Panel{i}", "solar_clean", 300 + 130 * i, 200, "panel", 56, 2.0, "solar", "ui.clean_panel", i, poff=(0, -30))
building("Console", "slider_console", 830, 200, "console", 40, 0, "solar", "ui.sliders", poff=(0, -50))
building("Charger", "charger_full", 910, 200, "charger", 38, 2.0, "solar", "ui.swap_packs", poff=(0, -50))
building("Lab", "science_lab", 940, 440, "lab", 62, 0, "lab", "ui.lab_process", poff=(0, -24))
building("Board", "forecast_board", 1130, 440, "board", 40, 0, "lab", "ui.forecast_board", poff=(0, -50))
building("Pad", "landing_pad", 640, 780, "pad", 70, 0, "pad", "", poff=(0, -120))
building("Shelter", "shelter", 1130, 660, "shelter", 60, 0, "shelter", "ui.enter_shelter", poff=(0, -40))
building("CrewLander", "crew_lander", 900, 780, "crew_lander", 70, 0, "", "ui.crew_lander", poff=(0, -60))
decor("Antenna", "antenna", 790, 390)
for i in range(14):
    x, y = rng.randrange(120, 1160), rng.randrange(120, 880)
    if free(x, y) and not (100 < x < 360 and y > 600):
        decor(f"Rock{i}", rng.choice(["rocks_1", "rocks_2"]), x, y)
# --- player ---
node("Player", "Node2D", "World", position="Vector2(640, 492)", script=script("player"))
node("Camera2D", "Camera2D", "World/Player", limit_left=0, limit_top=0, limit_right=W, limit_bottom=H)

# fix: the Greenhouse node has no interactable behaviour; make it a plain sprite
out = ["[gd_scene load_steps=%d format=3]" % (len(ext) + 1), ""] + ext_lines + [""] + nodes
text = "\n\n".join(["\n".join(out[:2 + len(ext_lines)])] + nodes) + "\n"
(root / "scenes" / "Outpost.tscn").write_text(text, encoding="utf-8")
print("Outpost.tscn written with", len(nodes), "nodes")

# --- tiny overlay scenes: a root CanvasLayer with a script ---
for scene, scr in [("InfoCard", "info_card"), ("HabitatMenu", "habitat_menu"), ("SliderPanel", "slider_panel")]:
    (root / "scenes" / f"{scene}.tscn").write_text(
        f'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/{scr}.gd" id="1"]\n\n'
        f'[node name="{scene}" type="CanvasLayer"]\nscript = ExtResource("1")\n', encoding="utf-8")
print("overlay scenes written")
