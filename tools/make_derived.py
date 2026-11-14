# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# Builds derived data from assets/ (never changes assets/):
#   assets_derived/bases.json : for every building / prop / rock sprite, where its VISUAL base is
#     bottom  = last pixel row that is clearly solid (alpha > 128), counted from the top of the image
#     left/right = solid columns in the bottom 6 rows (the part that touches the ground)
#     bbox_l/bbox_r = solid columns of the whole sprite
# polish.gd uses it to put contact shadows and dirt patches exactly under each sprite.
# Run:  python tools/make_derived.py
import json, os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ["assets/sprites/buildings", "assets/sprites/props", "assets/sprites/tiles"]
OUT = os.path.join(ROOT, "assets_derived")


def solid(px, w, x, y):
    return px[x, y][3] > 128


def base_of(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    rows = [y for y in range(h) if any(solid(px, w, x, y) for x in range(w))]
    if not rows:
        return None
    bottom = rows[-1]
    cols_all = [x for x in range(w) if any(solid(px, w, x, y) for y in rows)]
    band = range(max(0, bottom - 5), bottom + 1)
    cols = [x for x in range(w) if any(solid(px, w, x, y) for y in band)]
    return {"w": w, "h": h, "bottom": bottom, "left": cols[0], "right": cols[-1],
            "bbox_l": cols_all[0], "bbox_r": cols_all[-1], "top": rows[0]}


def main():
    os.makedirs(OUT, exist_ok=True)
    data = {}
    for d in DIRS:
        for f in sorted(os.listdir(os.path.join(ROOT, d))):
            if f.endswith(".png"):
                b = base_of(os.path.join(ROOT, d, f))
                if b:
                    data["res://" + d + "/" + f] = b
    with open(os.path.join(OUT, "bases.json"), "w") as fh:
        json.dump(data, fh, indent=1)
    print("bases.json:", len(data), "sprites")


if __name__ == "__main__":
    main()
