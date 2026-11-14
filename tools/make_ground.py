# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# Bakes the whole Outpost ground into ONE image: assets_derived/ground_outpost.png (1280x960, 1:1 pixels).
#   - ground_1..3 mixed by a fixed-seed noise map (no visible tiling), speckle contrast lowered 30%
#   - packed-regolith paths (path.png) with irregular dithered borders, from the Path* rects in Outpost.tscn
#   - pebbles, tiny craters, wheel tracks and boot prints near the pad (kept off paths and buildings)
#   - cables and a pipe: solar field -> charger -> habitat, recycler -> habitat, lab -> antenna
# polish.gd hides the old ground rectangles and shows this image instead. Never changes assets/.
# Run:  python tools/make_ground.py   (then godot --headless --path . --import)
import json, math, os, random, re
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1280, 960
SEED = 2026
CONTRAST = 0.7                  # speckle contrast kept (1.0 = original)
EXTRA_PATHS = [(950, 200, 1044, 264), (1000, 264, 1044, 440)]   # connector: solar row -> main path (x0, y0, x1, y1)
BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def load(name):
    return Image.open(os.path.join(ROOT, "assets/sprites/tiles", name)).convert("RGBA")


def soften(im):
    px = list(im.getdata())
    n = len(px)
    mean = [sum(p[i] for p in px) / n for i in range(3)]
    out = Image.new("RGBA", im.size)
    out.putdata([tuple(int(mean[i] + (p[i] - mean[i]) * CONTRAST) for i in range(3)) + (255,) for p in px])
    return out.load()


def value_noise(seed, cell):
    rng = random.Random(seed)
    gw, gh = W // cell + 2, H // cell + 2
    g = [[rng.random() for _ in range(gw)] for _ in range(gh)]

    def f(x, y):
        gx, gy = x / cell, y / cell
        ix, iy = int(gx), int(gy)
        tx, ty = gx - ix, gy - iy
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        a = g[iy][ix] * (1 - tx) + g[iy][ix + 1] * tx
        b = g[iy + 1][ix] * (1 - tx) + g[iy + 1][ix + 1] * tx
        return a * (1 - ty) + b * ty
    return f


def scene_info():
    s = open(os.path.join(ROOT, "scenes/Outpost.tscn"), encoding="utf-8").read()
    rects = []
    for m in re.finditer(r'\[node name="(Path\w*)" type="TextureRect" parent="Ground"\]\n(.*?)\n\n', s, re.S):
        v = {k: float(x) for k, x in re.findall(r'offset_(\w+) = ([-\d.]+)', m.group(2))}
        rects.append((v["left"], v["top"], v["right"], v["bottom"]))
    nodes = {}
    for m in re.finditer(r'\[node name="(\w+)" type="Node2D" parent="World"\]\nposition = Vector2\(([-\d.]+), ([-\d.]+)\)', s):
        nodes[m.group(1)] = (float(m.group(2)), float(m.group(3)))
    # sprite texture + offset per node, for "keep details off buildings"
    blocks = []
    bases = json.load(open(os.path.join(ROOT, "assets_derived/bases.json")))
    extids = dict(re.findall(r'path="(res://[^"]+)" id="(\w+)"', s))
    extids = {v: k for k, v in extids.items()}
    for m in re.finditer(r'\[node name="Sprite2D" type="Sprite2D" parent="World/(\w+)"\]\ntexture = ExtResource\("(\w+)"\)\ncentered = false\noffset = Vector2\(([-\d.]+), ([-\d.]+)\)', s):
        nm, tid, ox, oy = m.group(1), m.group(2), float(m.group(3)), float(m.group(4))
        b = bases.get(extids.get(tid, ""))
        if nm in nodes and b:
            x, y = nodes[nm]
            blocks.append((x + ox + b["bbox_l"] - 6, y + oy + b["top"], x + ox + b["bbox_r"] + 6, y + oy + b["bottom"] + 8))
    return rects + EXTRA_PATHS, nodes, blocks


def main():
    rects, nodes, blocks = scene_info()
    tiles = [soften(load(f"ground_{i}.png")) for i in (1, 2, 3)]
    path = soften(load("path.png"))
    img = Image.new("RGBA", (W, H))
    px = img.load()
    n1, n2 = value_noise(SEED, 96), value_noise(SEED + 1, 40)
    edge = value_noise(SEED + 2, 9)
    is_path = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            b = BAYER[(y % 4) * 4 + (x % 4)] / 16.0 - 0.5
            v = n1(x, y) * 0.7 + n2(x, y) * 0.3 + b * 0.08     # dithered blend between the three ground tiles
            t = 0 if v < 0.5 else (1 if v < 0.62 else 2)
            c = tiles[t][x % 64, y % 64]
            # path: signed distance into the nearest rect vs a noisy border (-5..+4 px), dithered 2 px band
            d = -99.0
            for (x0, y0, x1, y1) in rects:
                if x0 - 8 <= x < x1 + 8 and y0 - 8 <= y < y1 + 8:
                    d = max(d, min(x - x0, x1 - 1 - x, y - y0, y1 - 1 - y))
            if d > -8:
                lim = edge(x, y) * 9.0 - 5.0
                if d > lim + 1 or (d > lim - 1 and b + 0.5 > 0.5 - (d - lim) * 0.25):
                    c = path[x % 64, y % 64]
                    is_path[y][x] = True
            px[x, y] = c
    rng = random.Random(SEED)

    def free(x, y, r):
        if not (70 + r <= x < W - 70 - r and 70 + r <= y < H - 70 - r):
            return False
        for (x0, y0, x1, y1) in blocks:
            if x0 - r <= x <= x1 + r and y0 - r <= y <= y1 + r:
                return False
        for dy in (-r - 3, 0, r + 3):
            for dx in (-r - 3, 0, r + 3):
                yy, xx = int(y + dy), int(x + dx)
                if 0 <= yy < H and 0 <= xx < W and is_path[yy][xx]:
                    return False
        return True

    def shade(x, y, k):
        if 0 <= x < W and 0 <= y < H:
            r, g, b, a = px[x, y]
            px[x, y] = (max(0, min(255, int(r * k))), max(0, min(255, int(g * k))), max(0, min(255, int(b * k))), 255)

    # pebbles: a dark pixel with a light top pixel (lit from above)
    for _ in range(170):
        x, y = rng.randrange(W), rng.randrange(H)
        if free(x, y, 2):
            shade(x, y, 0.62)
            shade(x + 1, y, 0.7)
            shade(x, y - 1, 1.22)
    # tiny craters: dark upper rim, light lower rim, 3-5 px radius
    for _ in range(40):
        x, y, r = rng.randrange(W), rng.randrange(H), rng.randint(3, 5)
        if not free(x, y, r + 2):
            continue
        for a in range(0, 360, 8):
            ex, ey = x + round(r * math.cos(math.radians(a))), y + round(r * 0.6 * math.sin(math.radians(a)))
            shade(ex, ey, 0.72 if ey < y else 1.18)
        for dy in range(-1, 2):
            for dx in range(-r + 2, r - 1):
                shade(x + dx, y + dy, 0.88)
    # wheel tracks: two dotted parallel curves leaving the pad to the east
    pad = nodes.get("Pad", (640, 780))
    for off in (0, 11):
        for i in range(0, 170, 2):
            tx = pad[0] + 70 + i
            ty = pad[1] - 30 + off + int(16 * math.sin(i / 60.0))
            if free(tx, ty, 0):
                shade(tx, ty, 0.78)
                shade(tx + 1, ty, 0.84)
    # boot prints: a short walk west of the pad (pairs of 2x1 dents)
    for i in range(9):
        bx, by = pad[0] - 110 - i * 9, pad[1] - 20 + (3 if i % 2 else -3) + i
        if free(bx, by, 0):
            for dx in (0, 1):
                shade(bx + dx, by, 0.75)
    # cables (dark 2 px + dotted light top) and a pipe (3 px, grey with a highlight)
    def seg(points, kind):
        for (ax, ay), (bx, by) in zip(points, points[1:]):
            n = int(max(abs(bx - ax), abs(by - ay)))
            for i in range(n + 1):
                x = int(ax + (bx - ax) * i / max(n, 1))
                y = int(ay + (by - ay) * i / max(n, 1))
                if kind == "cable":
                    for (dx, dy) in ((0, 0), (1, 0), (0, 1), (1, 1)):
                        if 0 <= x + dx < W and 0 <= y + dy < H:
                            px[x + dx, y + dy] = (34, 32, 38, 255)
                    if i % 3 == 0 and 0 <= y - 1 < H:
                        px[x, y - 1] = (96, 92, 98, 255) if ay == by else px[x, y - 1]
                else:
                    for k, col in ((-1, (58, 60, 68, 255)), (0, (150, 154, 160, 255)), (1, (98, 100, 108, 255)), (2, (40, 40, 48, 255))):
                        xx, yy = (x, y + k) if ay == by else (x + k, y)
                        if 0 <= xx < W and 0 <= yy < H:
                            px[xx, yy] = col
    g = lambda nm, dx=0, dy=0: (nodes[nm][0] + dx, nodes[nm][1] + dy)
    if all(k in nodes for k in ("Panel0", "Panel3", "Charger", "Habitat", "Recycler", "Lab", "Antenna")):
        seg([g("Panel0", 0, 6), g("Charger", 0, 6)], "cable")                          # solar field -> charger
        seg([g("Charger", 14, 2), (g("Charger")[0] + 14, 330), (g("Habitat")[0] + 70, 330), (g("Habitat")[0] + 70, 410)], "cable")
        seg([g("Recycler", 30, -24), g("Habitat", -40, -24)], "pipe")                  # recycler -> habitat
        seg([g("Lab", -40, -40), (g("Antenna")[0], g("Lab")[1] - 40), g("Antenna", 0, -6)], "cable")   # lab -> antenna
    os.makedirs(os.path.join(ROOT, "assets_derived"), exist_ok=True)
    img.save(os.path.join(ROOT, "assets_derived/ground_outpost.png"))
    print("ground_outpost.png written,", len(rects), "path rects,", len(blocks), "sprites kept clear")


if __name__ == "__main__":
    main()
