# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# itch.io cover 630x500 from the 1280x720 title capture: the whole title at game resolution, sky padding.
# Run after tools/capture.tscn:  python tools/make_cover.py
import os
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
im = Image.open(os.path.join(ROOT, "docs/screenshots/01_title.png"))
small = im.resize((640, 360), Image.NEAREST)          # exact half: the game's own 640x360 pixels
cover = Image.new("RGB", (630, 500), small.getpixel((2, 2)))   # pad with the sky colour
cover.paste(small.crop((5, 0, 635, 360)), (0, 70))
cover.save(os.path.join(ROOT, "docs/screenshots/itch_cover_630x500.png"))
print("itch_cover_630x500.png written")
