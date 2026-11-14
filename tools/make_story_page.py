# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# One 1280x720 comic page from story_1..3 side by side with thin panel borders (for the video). Never changes assets/.
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
page = Image.new("RGB", (1280, 720), (8, 8, 16))
d = ImageDraw.Draw(page)
gap, top = 16, 120
pw = (1280 - 4 * gap) // 3
for i in range(3):
    im = Image.open(os.path.join(ROOT, f"assets/sprites/screens/story_{i + 1}.png")).convert("RGB")
    k = pw / im.width
    im = im.resize((pw, int(im.height * k)), Image.NEAREST)
    x = gap + i * (pw + gap)
    y = (720 - im.height) // 2
    page.paste(im, (x, y))
    d.rectangle([x - 3, y - 3, x + im.width + 2, y + im.height + 2], outline=(232, 226, 210), width=3)
page.save(os.path.join(ROOT, "assets_derived/story_page.png"))
print("story_page.png", pw)
