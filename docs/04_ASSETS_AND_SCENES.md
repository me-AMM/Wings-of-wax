# 04 Assets, scenes and Godot setup

Compact asset index: docs/ASSET_INDEX.md (sizes, frame counts, fps, anchors). Full detail: assets/manifest.json (29 KB: do not read it whole; query it with a short script). Rules from the art side: assets/README.md.

## Godot project settings
- Godot 4.7.2, GDScript. Project folder = this folder (create project.godot here). Name: "Junior Astronaut Mission Trainer".
- Viewport 320x180, window override 1280x720, stretch mode "viewport", scale mode integer. Default texture filter Nearest, no mipmaps, snap 2D transforms and vertices to pixel. Tile grid 64x64. Renderer: Compatibility.
- Autoloads: GameState (all state and rules), Config (loads data/config.json), Text (loads data/text.json, get("key")), Audio (play(name), ambience control, mute toggle), later Judge (debug panel logic).
- Input map: move_up/down/left/right (arrows + WASD), interact (E), pause/mute (M), judge toggle on the title screen only.
- Web export preset "Web", output build/web/index.html. Test the web export EARLY (first milestone) and after each major milestone.
- Folders: scenes/, scripts/, data/, assets/ (given), audio/sfx, audio/ambience, tools/ (python helpers), build/ (ignored by git).

## Naming and loading
- Frames: `<character>_<action>_<direction>_<frame>.png`, frame numbers start at 0. Frame-name directions: front / back / left / right. Still names use south / north / west / east (front = south, back = north, left = west, right = east).
- Astronaut animation frames are 104x104 with the feet at y=88; anchor (52, 88) in EVERY frame. The 92x92 stills (astro_a_south etc.) are on a different canvas: for a standing pose use `*_idle_<direction>_0.png`.
- Astronaut B (pink) is a recolor of A: identical frames and timing. Character A has blue accents, B pink.
- Animation clips available: walk (4 directions x 4 frames), idle (4 directions x 2), interact_front (3), dig_front (4) for each astronaut; cargo_lander_touchdown (6, once, 128x192 bottom-aligned, last frame = landed position of cargo_lander.png), dust_puff (4, once), sparkle (4), waypoint_flag_pulse (4), storm_specks (3), rare_stone_glow (4), radish_ready_sway (2).
- Build SpriteFrames in code from the manifest (a helper script that registers each clip by name with the suggested fps and loop flag). Suggested fps: walk 8, idle 2, interact/dig 6, lander 8 once, dust puff 10 once, sparkle 8, flag 6, specks 8, stone glow 6, radish sway 2.
- Icons are 64x64 files; show at 32 or 64.

## What is where (stills by role)
- Characters: astro_a/b_<south|north|west|east>, portrait_a, portrait_b (character select).
- Buildings: habitat, greenhouse, water_recycler, science_lab, shelter, landing_pad, solar_clean / solar_dust25 / solar_dust50 / solar_dust75 (swap by dust %, per group), charger_full (pack on charger), charger_empty (empty slot).
- Props: slider_console, forecast_board, cargo_lander, cargo_crate, crew_lander, antenna, radish_empty / radish_sprout / radish_growing / radish_ready.
- Tiles: ground_1..3, ground_dark (shadowed crater), path, rocks_1..2, crater_small (outpost) and crater_large (missions), boulder_wall (map edge).
- Mission objects: sample_spot, ice_deposit, rare_stone, waypoint_flag.
- Effects: dust_puff, sparkle, storm_specks.
- Icons: heart, clock, sun, moon, water, ration, radish, oxygen, pack, pack_low, research, rock, ice, storm, blackout, lock, gym, sleep, ekey, star_full, star_empty.
- UI: ui_panel (9-slice, margins 13 left/right, 14 top/bottom; menus and info cards), ui_panel_hazard (spare), button_normal / button_hover / button_pressed (horizontal 3-slice, margin 17, fixed height 32, min width 38), bar_frame (3-slice, margin 8) + bar_fill (plain white 128x16: clip to the inner rect x 3-125, y 4-13 and tint per bar with modulate: health red, oxygen cyan, research purple), slider_track (zones low x 7-43, medium x 46-81, high x 84-120) + slider_knob, storm_frame (3-slice, margin 9, hazard-stripe ends), dig_bar (192x32, green target zone x 78-114, track inner x 4-187, y 8-22) + dig_marker (12x32, centre it on the marker position), forecast_screen (320x180 background for the forecast board scene).
- Screens (320x180): title_screen, select_bg, story_1, story_2, story_3, ending_success, ending_failed, credits_bg.

## Made in Godot, not sprites
Shadow darkness (CanvasModulate), flashlight (PointLight2D with a generated gradient texture; visual only), storm screen tint, blinking lights (storm icon, charger, water recycler: modulate or tween on the stills), all text.

## Scenes (16)
Full screens: Title (Start, Judge mode), CharacterSelect (portraits + name), Story (3 pages), Outpost (main), Mission (parameter: rock / ice / finale), ForecastBoard, EndingSuccess, EndingFailed, Credits.
Overlays: HUD, SliderPanel, InfoCard, StormWarning (countdown with storm_frame and the real-event label), IceDigBar, JudgePanel, HabitatMenu (Eat / Sleep / Gym).

### Outpost (scrolling world, Camera2D follows the player with limits)
- Buildings are large against the 320x180 view (habitat 192x192), so the world is several screens wide. Walking speed: tune so a full chore loop (habitat -> recycler -> greenhouse -> solar field -> habitat) takes about 25-30 s; awake time per day is only 160 s and a mission costs 90 s.
- Suggested layout (owner will adjust in the editor): habitat in the centre; water recycler and greenhouse close to it on the left; solar field with console and charger to the north; science lab (with the forecast board) to the east; landing pad to the south; radiation shelter on the far east edge; boulder_wall around the border; ground tiles with a few rocks and craters; a path tile between buildings.
- Interaction points (E): habitat door (HabitatMenu), recycler (drink), greenhouse tray (water / plant / harvest), slider console (SliderPanel), each panel group (hold E 2 s to clean), charger (hold E 2 s to swap packs), lab (process samples), forecast board (ForecastBoard scene), landing pad (collect cargo / start mission), shelter (enter), crew lander (day 32). Locked buildings show icon_lock and "opens on day N".
- Use the E key prompt icon (icon_ekey) near the nearest interactable.
- Dust puff when a lander touches down and when the player walks on dust; sparkle when a panel is cleaned.

### Mission scene
~90 s separate screen. Suit meter (displayed as "8 h", really 120 s; 180 s on mission 1). Rock/soil: collect sample_spot items and reach waypoint_flag. Ice: dig at ice_deposit with the IceDigBar (stop the marker in the green zone). Finale: find rare_stone (glow animation). Craters (crater_large, ground_dark inside) slow the player and drain suit oxygen 1.25x. Storm warning appears mid-mission (see docs/01); the player runs back to the shelter/pad.

### Habitat menu
One E press at the habitat door: three buttons Eat (the player picks a ration or a radish meal; show icon_ration / icon_radish and what is left), Sleep (icon_sleep), Gym (icon_gym, shows cooldown). Disabled options show why (already ate today, cooldown, not enough time).

