"""Computes collision footprints from the sprite alpha (no guessing). Pillow only.
Run: python tools/footprints.py   -> writes data/footprints.json
Points are relative to the sprite ORIGIN = bottom centre of the image (the node origin in the scenes).
Footprint = bottom 25% (20-30%) of the opaque bounding box, inset 8% per side. Round buildings get an
ellipse polygon. Crater slow zone = contour from the alpha, inset (relative to the image CENTRE)."""
import json, math, pathlib
from PIL import Image

root = pathlib.Path(__file__).resolve().parent.parent
man = json.load(open(root / "assets" / "manifest.json"))
stills = man["stills"]

# name: (kind, fraction of bbox height used, side inset)
SOLID = {
    "habitat": ("ellipse", 0.28, 0.08), "greenhouse": ("ellipse", 0.28, 0.08),
    "water_recycler": ("ellipse", 0.28, 0.08), "shelter": ("ellipse", 0.28, 0.08),
    "science_lab": ("rect", 0.25, 0.08), "solar_clean": ("rect", 0.22, 0.04),
    "slider_console": ("rect", 0.25, 0.08), "charger_full": ("rect", 0.25, 0.08),
    "forecast_board": ("rect", 0.25, 0.08), "antenna": ("rect", 0.20, 0.30),
    "cargo_lander": ("rect", 0.22, 0.08), "crew_lander": ("rect", 0.22, 0.08),
    "radish_empty": ("rect", 0.30, 0.10), "rocks_2": ("rect", 0.30, 0.08),
}

def bbox_alpha(im):
    a = im.split()[3].point(lambda v: 255 if v > 40 else 0)
    return a.getbbox(), a

out = {}
for name, (shape, frac, inset) in SOLID.items():
    im = Image.open(root / "assets" / stills[name]["path"]).convert("RGBA")
    W, H = im.size
    (x0, y0, x1, y1), _ = bbox_alpha(im)
    bw, bh = x1 - x0, y1 - y0
    fh = max(6, round(bh * frac))
    left, right = x0 + bw * inset, x1 - bw * inset
    top, bottom = y1 - fh, y1
    ox, oy = W / 2.0, H           # origin = bottom centre of the image
    if shape == "ellipse":
        cx, cy = (left + right) / 2, (top + bottom) / 2
        rx, ry = (right - left) / 2, (bottom - top) / 2
        pts = [(cx + rx * math.cos(2 * math.pi * i / 16), cy + ry * math.sin(2 * math.pi * i / 16)) for i in range(16)]
    else:
        pts = [(left, top), (right, top), (right, bottom), (left, bottom)]
    out[name] = {"shape": shape, "poly": [[round(px - ox, 1), round(py - oy, 1)] for px, py in pts]}

# crater slow zone (sprite is drawn centred): contour from the alpha, inset from the rim
im = Image.open(root / "assets" / stills["crater_large"]["path"]).convert("RGBA")
W, H = im.size
(x0, y0, x1, y1), a = bbox_alpha(im)
cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
apx = a.load()
pts = []
for i in range(24):
    ang = 2 * math.pi * i / 24
    r = 0
    while True:
        px, py = int(cx + (r + 1) * math.cos(ang)), int(cy + (r + 1) * math.sin(ang))
        if not (0 <= px < W and 0 <= py < H) or apx[px, py] == 0:
            break
        r += 1
    rr = max(8, r * 0.72 - 4)        # inner floor: inset from the rim
    pts.append([round(cx + rr * math.cos(ang) - W / 2, 1), round(cy + rr * math.sin(ang) - H / 2, 1)])
out["crater_large_slow"] = {"shape": "polygon", "poly": pts}

(root / "data" / "footprints.json").write_text(json.dumps(out, indent=1), encoding="utf-8")
for k, v in out.items():
    xs = [p[0] for p in v["poly"]]
    ys = [p[1] for p in v["poly"]]
    print(f"{k:18s} {v['shape']:8s} x {min(xs):7.1f}..{max(xs):6.1f}  y {min(ys):7.1f}..{max(ys):6.1f}")
