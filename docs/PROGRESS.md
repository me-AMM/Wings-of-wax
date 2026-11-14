# Progress (builder keeps this updated; read it at the start of every session)

- [x] M0 Setup (project.godot, import, git init, Web export proven)
- [x] M1 Rules core (data files, GameState, tools/sim_check.gd passes, day_snapshots.json)
- [x] M2 Outpost slice, days 1-4 (record footage point)
- [x] M3 Missions (rock, ice dig, finale, lab, research, stars)
- [x] M4 Storms and real data (donki_events.json, StormWarning, shelter, forecast board)
- [x] M5
- [x] M6 (audio wired + fallback sounds, day-4 cards via day script) Polish (audio wiring, info cards, HUD readability, juice)
- [x] M7 (web export done, README written; itch upload, GitHub push and organizer check are manual)

Last session note:

Session note: time plan from AMM (build stops 09:00): M2 45 min, M3/M4 45 min each, M5 by 08:30, M6 audio + day-4 cards only, M7 at 09:00.
sim_check (godot --headless --path . -s tools/sim_check.gd): all 32 days match docs/03, shadow and dust test cases pass.

Session note: M0-M7 built. Checks: sim_check, collision_check, ui_check pass. Web build in build/web, served on port 8060.
Embed on itch.io at 1280x720 (integer 2x scale).
