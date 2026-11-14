# Builder prompt (for Claude Code)

## For AMM: how to start (not part of the prompt)
1. Regenerate your Pixel Lab API key (it appeared in chat). The game and this folder never need it.
2. Open a terminal in this folder (`E:\AMUNi\Wings of wax\junior-astronaut-mission-trainer`) and start Claude Code there. It loads CLAUDE.md by itself.
3. Model and effort: Sonnet 5.5 at medium effort for most work (`/model`, `/effort`). For milestone M1 only, use plan mode (opusplan if /model offers it) because the architecture matters most. Check /usage between milestones.
4. Paste the PROMPT below as the first message. In every later session (new 5-hour window, or after /clear) paste the RESUME prompt instead.
5. To report a bug, send 3 lines: where (scene or day), what happened vs what you expected, and the error text from the editor's Output panel. Do not paste screenshots unless needed.

---

## PROMPT (first session)

You are the builder of a 2D top-down game in Godot 4.7.2 (GDScript) for the NASA Space Apps Challenge. The owner (AMM) is a solo beginner and will tweak scenes in the editor after you build them. All art is finished and in assets/. You write code, data and scenes.

Read now, in this order: CLAUDE.md (already loaded), docs/01_DECISIONS.md, docs/02_RULEBOOK.md, docs/03_DAY_SCRIPT.md, docs/04_ASSETS_AND_SCENES.md, docs/05_AUDIO_TEXT_CREDITS.md, docs/ASSET_INDEX.md. Do NOT read assets/manifest.json whole (query it with a short script).

Goal: a complete, stable, good-looking 32-day game that exports to the web, with the real NASA data visible in the storms. Judges mostly watch a 30-second video, so the outpost, the power sliders, a storm during a mission with the real flare shown, the shadow days and the ending must look good and work first. Submission is Saturday 14 Nov 2026 about 14:00 Cairo time; you have about 12 hours of building time across 3 usage windows of 5 hours, so be economical.

Step 0 (no code yet): in at most 12 lines, list (a) conflicts or missing information you find across the docs, (b) at most 3 questions that truly block you. If nothing blocks you, continue straight to M0 without waiting for an answer.

Work in milestones, one at a time. After each: `godot --headless --path . --quit` shows no errors, git commit, update docs/PROGRESS.md, then reply in at most 5 lines: what works, what AMM should test in the editor, what is next.

- **M0 Setup.** Create project.godot with the settings in docs/04 (viewport 320x180, x4, Nearest, Compatibility renderer, input map). Import assets (`--import`). Create the folder structure, .gitignore is already present, `git init`, first commit. Create a minimal Title scene, add the "Web" export preset and prove a web export works (`--export-release "Web" build/web/index.html`). A broken web export found late is fatal, so do this first.
- **M1 Rules core, no scenes.** data/config.json (all numbers from docs/02), data/days.json (from the docs/03 table and day text), data/text.json (all strings, drafted cards and story), GameState autoload implementing docs/02 exactly (time, power, packs, dust, oxygen, water, food, health, storms, research, stars). Write `tools/sim_check.gd` (run with `godot --headless --path . -s tools/sim_check.gd`): it plays a scripted good player through GameState without any scenes and prints, per day, the difference from the docs/03 table (meals, water, research, packs, dust, oxygen). It must also pass the test cases in docs/02 (shadow check, dust effects) within the tolerances in docs/01. Fix the rules until it passes, then export the per-day end state to data/day_snapshots.json (the Judge day jump loads it). Every event (storm, lander, shadow start/end, harvest) is a function on GameState that both the day schedule and the Judge panel call.
- **M2 Outpost slice, days 1-4.** Outpost scene with the map, player (walk/idle animations from the manifest via a helper that builds SpriteFrames), camera, all interaction points, HUD, HabitatMenu, SliderPanel, InfoCard, locked buildings, landers with touchdown animation, dust puff, sparkle. Tell AMM when this is ready to record footage.
- **M3 Missions.** Mission scene (rock, ice dig with IceDigBar, finale stone), suit meter, craters, waypoint, abort rules, lab processing, research and stars.
- **M4 Storms and real data.** tools/fetch_donki.py and data/donki_events.json (see docs/01), StormWarning overlay with the real-event label, shelter, damage rules, forecast board scene, storm watch effects.
- **M5 Whole game.** Shadow days (CanvasModulate, visual flashlight, moon icon), blackout, all 32 days running to the ending, Title, CharacterSelect, Story, EndingSuccess, EndingFailed, Credits, JudgePanel (docs/01 section 4) with its three presets.
- **M6 Polish.** Wire audio by file name (docs/05), info cards on their days, HUD readability for kids 7-12 (icons first, numbers second), screen tint for storms, small juice (puffs, sparkles, blinking lights). Run sim_check again.
- **M7 Release.** Final web export test, README.md per docs/05, credits screen complete, final commit. List what AMM must do by hand (itch.io upload, GitHub push, organizer check).

Rules: follow CLAUDE.md. Never modify files in assets/; if an asset is missing or wrong, use a ColorRect placeholder, log one line in docs/DECISIONS_LOG.md and keep going. Do not invent numbers; use docs/02. If a doc is ambiguous, pick the simplest reading, log it in docs/DECISIONS_LOG.md (one line) and continue. Keep scripts small and commented, with exported variables where AMM may want to tweak (speeds, positions, durations). Keep replies short.

Start with Step 0.

---

## RESUME prompt (every later session)

Read CLAUDE.md, docs/PROGRESS.md, docs/DECISIONS_LOG.md (if it exists) and the output of `git log --oneline -15`. Continue with the first unfinished milestone in docs/PROGRESS.md. Do not re-read the other docs unless you need a specific rule (search them with grep instead). Same working rules: small steps, headless check, commit, 5-line report.

