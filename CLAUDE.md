# Junior Astronaut Mission Trainer (CLAUDE.md, read first)

NASA Space Apps Challenge 2026, Cairo. Challenge: "Build a Junior Astronaut Mission Trainer" (game for kids 7-12, real trade-offs, 2-3 resources, credited NASA data).
Game: 2D top-down lunar south-pole outpost, one astronaut, 32-day run (4 real minutes per game day), Godot 4.7.2 (GDScript), web export for itch.io.
Owner: AMM, solo, beginner in Godot. He tweaks scenes in the editor after you build them. Keep code simple, commented and easy to adjust.

## Deadline and what gets judged
- Submission: Saturday 14 Nov 2026, about 2 PM Cairo time. Plan for a stable, good-looking game 4-5 hours before that.
- Judges mostly watch a 30-second video, not the game. Judges score: idea, and use of the NASA resources listed below. So the game must LOOK good on camera and SHOW the real NASA data on screen (flare class, date, source) in the first minutes of play.
- Polish the first 12 days most. All 32 days must still run to the ending.

## NASA resources the game must visibly use
NASA DONKI (real flares drive the 8 storms), NASA OSDR (gym card), RadLab (storm card), Canadian Space Agency food toolkit (radish card). Credits screen lists all of them and says "Not endorsed by NASA". No NASA logos anywhere.

## Read these docs (they are the source of truth, in this order)
1. docs/01_DECISIONS.md : decisions made, conflicts, clarifications. Overrides the others where they disagree.
2. docs/02_RULEBOOK.md : every number the code needs.
3. docs/03_DAY_SCRIPT.md : the 32-day script, run-at-a-glance table, storms.
4. docs/04_ASSETS_AND_SCENES.md : asset map, scene list, Godot settings.
5. docs/05_AUDIO_TEXT_CREDITS.md : sound wiring, info cards, credits, AI statement.
Asset index: assets/manifest.json (paths, sizes, frame lists, fps, anchors, 9-slice, UI numbers) and assets/README.md.

## Environment
- Godot console exe: "E:\AMUNi\Wings of wax\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
- Web export templates 4.7.2 are installed. Python 3.11 and git are available. Windows, PowerShell.
- Check scripts without opening the editor: godot --headless --path . --quit  (shows parse errors)
- Import after adding files: godot --headless --path . --import
- Web export: godot --headless --path . --export-release "Web" build/web/index.html
- The editor may be open while you write files; the owner refocuses it to reload.

## Hard rules
- Display: 640x360 viewport, window 1280x720 (x2); 320x180 UI/art is shown at exactly 2x, stretch mode viewport, default texture filter Nearest, no mipmaps, snap 2D transforms to pixel. Renderer: Compatibility (web export).
- All game state lives in ONE autoload (GameState). The day script is DATA (data/*.json). Every event (storm, lander, shadow, harvest) is one function that the schedule and the Judge panel both call.
- No magic numbers in scenes: numbers live in data/config.json or one constants script, matching docs/02_RULEBOOK.md.
- All player-visible text lives in data/text.json (English). No hardcoded strings in scenes.
- Load animation frames by file name, never by folder order. Build SpriteFrames from assets/manifest.json in code.
- Everything must work in the web export: no threads, no native-only APIs. Browsers block audio until the first click (the title screen Start button covers this).
- Never put secrets in the repo. No API keys are needed by the game.
- Missing audio files must not crash the game (skip silently).

## Working style (usage is limited: Claude Pro, 5-hour windows)
- Work in small milestones. After each: run the headless check, git commit, then reply in 5 lines max: what works, what to test in the editor, what is next.
- Prefer scripts and headless checks over looking at screenshots. Look at at most a few images per session.
- Do not re-read large files. Use /clear between milestones and /compact when the context grows.
- Ask the owner only when blocked; otherwise choose a sensible default and log it in docs/DECISIONS_LOG.md (one line each).
- Keep replies short.
