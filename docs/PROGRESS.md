# Progress (builder keeps this updated; read it at the start of every session)

State at 10:45, 14 Nov 2026. The visual polish round (POLISH 1-5) is done and committed; Web build exported after it.

## Milestones
- [x] M0 Setup (project.godot, import, git, Web export proven)
- [x] M1 Rules core (data files, GameState, sim_check passes, day_snapshots.json)
- [x] M2 Outpost (map, player, HUD, habitat menu, sliders, info cards, landers)
- [x] M3 Missions (rock, ice dig, finale stone, suit meter, craters, exit marker, lab, research, stars)
- [x] M4 Storms and real data (DONKI events, storm panel with real-event label, shelter, forecast board)
- [x] M5 Whole game (title, character select, story, endings, credits, shadow days, blackout, Judge panel)
- [x] M6 Polish (audio by file name, info cards, HUD, juice)
- [x] M7 Release (Web export, README, credits)

## Later rounds (all committed)
- Quality pass: 640x360 display, collision footprints, Silkscreen font, HUD strip, Judge panel layout.
- Rounds 2-6: finale flow and extraction, storms persist across scenes, fatal large/finale storms, shelter only during storms,
  oxygen/blackout fix, save/load (one slot, autosave 06:00, pause menu, judge mode never saves), Retry day N, sound upgrade.
- Final round: AI watermark and statement, WAV metadata, code headers, Space Weather Log, Fact log, What you learned,
  daily checklist and guided days 1-3, Video mode, 1280x720 screenshots and itch.io cover, sound and visual cleanup,
  three play-tester rounds and their fixes (finale storm now starts when the stone is taken).

## Checks (all pass at f3370fe)
Run from the project folder (console exe in CLAUDE.md):
- `-s tools/sim_check.gd` (32 days vs docs/03), `res://tools/collision_check.tscn`, `res://tools/ui_check.tscn`,
  `res://tools/flow_check.tscn`, `res://tools/judge_check.tscn` (slow, about 8 min), `res://tools/save_check.tscn`,
  `res://tools/o2_check.tscn`, `res://tools/audio_check.tscn`.
- Screenshots: `godot --path . res://tools/capture.tscn` (needs a window) -> docs/screenshots/.

## Known bugs / not verified
1. The day-32 SUCCESS ending has never been reached by hand in the Web build (play-testers were blocked by a hidden,
   2 fps browser pane). flow_check drives the whole path headless and passes. Play it once before recording.
2. Sound was never listened to in the browser. Mix and loudness are checked by code only (audio_check).
3. Browser console showed "DataCloneError ... out of memory" in the audio ring buffer after many reloads in one tab;
   not reproduced. If audio stops in a long session, reload the page.
4. One tester saw a click on the Judge day slider land on "Mission" while the panel was fading in (not reproduced).
5. Day 1 has no drink step: the water recycler opens on day 2 (rulebook), the day script says drink on day 1.
6. Chore loop is 9.6 s at player_speed 119 (target was 15-20 s; the owner asked for the faster speed).
7. Mission 1 (140 s suit) and the finale are easy on suit air (about 49% / 64% left); the storm is the finale's challenge.
8. HUD values have no text labels (48H, two pack numbers); kids may need the info cards to understand them.
9. Some world labels can still sit close to each other near the left map edge on day 1 (lock labels are staggered).

## Visual polish round (done, POLISH 1-5)
- Grounding: dithered contact shadows and dirt patches on each sprite's measured base (tools/make_derived.py -> assets_derived/bases.json).
- Polar sun: long silhouette shadows that turn once per game day, hidden on shadow days (scripts/polish.gd, SUN_* constants).
- Ground: one baked image (tools/make_ground.py -> assets_derived/ground_outpost.png): noise tiles, dithered paths, pebbles,
  tiny craters, tracks, cables, pipe. Re-run it if buildings or paths move. Live boot prints fade over 30 s.
- HUD: health number beside the heart, "?" Facts button in the strip, 6 px safe margin (UIStyle.SAFE), checklist folds with T.
- Light: warm window glows, colour-grade shader, softer flashlight. itch cover: python tools/make_cover.py after capture.
- Not done: mission scene has only the player's shadows (no dirt/ground bake); window glow positions were checked on one capture only.

## Manual steps for AMM
1. Play day 32 to the success ending once (Judge Mode, day 32).
2. itch.io: zip build/web/, HTML5, embed 1280x720, cover docs/screenshots/itch_cover_630x500.png.
3. Record the 30 s video with Video mode on (Judge panel). The AI watermark stays on screen.
4. Push to GitHub. Confirm with the organizers that AI-generated art and code are fine (disclosed in game and README).
