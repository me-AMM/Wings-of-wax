# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# itch.io cover 630x500 from the 1280x720 title capture: a centre crop, 1:1 pixels (no resampling).
# Run after tools/capture.tscn:  python tools/make_cover.py
import os
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
im = Image.open(os.path.join(ROOT, "docs/screenshots/01_title.png"))
x0, y0 = (im.width - 630) // 2, (im.height - 500) // 2
im.crop((x0, y0, x0 + 630, y0 + 500)).save(os.path.join(ROOT, "docs/screenshots/itch_cover_630x500.png"))
print("itch_cover_630x500.png written")
