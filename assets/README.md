# Junior Astronaut Mission Trainer: sprite handoff

All art was generated in Pixel Lab (AI, Tier 1) during the hackathon and then recolored or composed with the
Python scripts in `source/`. 16-color palette. No outside art.

## Contents
- `sprites/`: final approved still sprites, by category (characters, buildings, props, tiles, mission, effects, icons, ui, screens)
- `animations/`: individual PNG frames, one file per frame (characters, effects, objects)
- `manifest.json`: machine-readable index (paths, sizes, frame lists, suggested fps, anchors, 9-slice margins, UI numbers, palette)
- `palette.png`: the 16 colors as a 16x1 strip
- `source/`: prompt list (`sprite_prompts.csv`) and generator scripts (they need PIXELLAB_API_KEY in the environment)

## Display settings (Godot 4)
- Base resolution 320x180, window 1280x720 (x4), stretch mode "viewport".
- Default Texture Filter = Nearest, no mipmaps, snap 2D transforms to pixel. Tile grid 64x64.

## Naming
- Frames: `<character>_<action>_<direction>_<frame>.png`, e.g. `astronaut_a_walk_left_2.png` (frame numbers start at 0).
- Directions in frame names: front / back / left / right. Still names use south / north / west / east
  (front = south, back = north, left = west, right = east).
- Load frames by name in code; do not rely on file order.

## Things the images do not tell you
1. Astronaut animation frames are 104x104 with the feet row at y=88; anchor (52, 88) in every frame.
   The approved astronaut stills are 92x92 on a different canvas: for a standing pose use `*_idle_<direction>_0.png`.
2. Astronaut B (pink) is a recolor of astronaut A: same frames and timing.
3. Icons are 64x64 files; show them at 32 or 64.
4. Solar panels: `solar_clean` = 0% dust, `solar_dust25`, `solar_dust50`, `solar_dust75`.
5. Radish tray stages: `radish_empty`, `radish_sprout`, `radish_growing`, `radish_ready`.
6. Charger: `charger_full` (pack on the charger) and `charger_empty` (empty slot).
7. Cargo lander touchdown frames are 128x192, bottom-aligned; the last frame matches the landed position of `cargo_lander.png`.
8. UI: see `nine_slice` and `ui_layout` in the manifest. Buttons and the frames stretch horizontally only (3-slice).
   `bar_fill` is a plain white bar: clip it to the inner rectangle of `bar_frame` and tint it per bar with modulate.
   The ice-dig bar: fixed green target zone; `dig_marker.png` is a separate sprite that moves along the track.
9. `ui_panel_hazard.png` is a spare (hazard-stripe panel).

## Suggested frame rates (change freely)
walk 8 fps, idle 2 fps, interact and dig 6 fps (loop), lander touchdown 8 fps (once), dust puff 10 fps (once),
sparkle 8, flag pulse 6, storm specks 8, stone glow 6, radish sway 2 (loops).

## Made in Godot, not sprites
Shadow darkness (CanvasModulate), flashlight (PointLight2D with a gradient texture), storm screen tint,
blinking lights (storm icon, charger, water recycler: modulate or tween on the stills), and all text including the font.

## Credits and statement for the submission
- Art: AI-generated pixel art made with Pixel Lab during the event (Tier 1 subscription), then recolored and composed with Python scripts. Prompts are in `source/sprite_prompts.csv`.
- Space weather data: NASA CCMC DONKI. The 2003 flare: NOAA / ESA. Research sources: see the research report.
- Made with Godot. Not endorsed by NASA.
- Font: still to be decided (Godot default, or a free pixel font with an open license and a credit line).
