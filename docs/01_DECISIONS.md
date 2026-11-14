# 01 Decisions, clarifications and open items

This file overrides docs 02-05 where they disagree. Newer decisions are marked (late).

## Design decisions
1. **Habitat (late):** no interior room and no interior props (bed, kitchen counter, gym machine, life support panel are NOT generated). The player interacts from outside. One E press at the habitat door opens a small **Habitat menu** overlay with three choices: Eat (ration or radish meal), Sleep, Gym. Wherever the timeline says "kitchen" or "bed", it means this menu. Drinking happens at the water recycler (E). Life support is set with the sliders at the solar field.
2. **Radishes replace potatoes** (7 game days to harvest, info card says about 4x sped up).
3. **Audio (late):** ambience only, NO music. Three loops: suit_breath (outside and missions), hab_hum (near the habitat), recycler_hum (near the recycler when life support is medium or high). **All ambience cuts to full silence while a storm warning or storm is active** so only the alarm is heard; it returns after the storm. Sound list is in docs/05.
4. **Judge mode (late):** a visible "Judge mode" button on the title screen opens a debug panel; it is for judges, not a playable feature. Contents:
   - Day picker 1-32: loads the expected end-of-day stock for that day (the "good player" values).
   - Buttons: trigger small / medium / large storm, start shadow, land cargo, start mission, refill all, speed x4.
   - Presets (default list, owner can change): "Storm during a mission" (day 8), "Shadow day" (day 11), "Big storm" (day 24).
   - A clear "JUDGE MODE" label stays on screen while active. Runs started this way earn no stars.
5. **Language:** English only. All text in data/text.json so a translation could be added later (Arabic toggle is NOT in scope).
6. **Scenes (16):** Full screens: title, character select, story intro (3 pages in one scene), outpost map, mission (one scene reused for rock/soil, ice dig and the finale stone), forecast board, ending success, ending failed, credits. Overlays: HUD, slider panel, info card, storm warning/countdown, ice-dig bar, Judge panel, Habitat menu. Mission types are one scene with a type parameter.
7. **Controls:** keyboard only (arrows or WASD to move, E to interact, hold E for timed actions). No touch.
8. **Art:** finished, see docs/04. Font: Godot default font for now (owner may swap in a free pixel font later).

## Scope rules (time is short)
- Build order favors what appears in the 30-second video: outpost, power sliders, a storm during a mission with the real flare shown, the shadow days, the ending with stars.
- If time runs short, cut in this order: credits background, Priority 3 sounds, Judge presets, interact/dig animations, forecast board polish. Never cut: storms with real data, shelter, power sliders, endings.

## Real data (must be visible in the game)
- DONKI moved on 30 Sep 2026: use `https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR?startDate=2024-05-03&endDate=2024-05-09`. No API key. (The challenge page still describes the old api.nasa.gov address; the new host is correct. Credits line: "DONKI archive downloaded from the CCMC host.")
- Write `tools/fetch_donki.py` (standard library only), download once, pick **5 M-class flares on different days** in 3-9 May 2024, confirm the **X5.8 flare of 11 May 2024** (query that date) and the **X9.0 flare of 3 Oct 2024**. Save the chosen events with flrID, classType, peak time, sourceLocation, activeRegionNum to `data/donki_events.json`. The game reads only this file (no live calls).
- The **X28 flare of 4 Nov 2003** is not in DONKI: hand-enter it (source: NOAA / ESA), described as "the brightest X-ray flare ever measured".
- Each storm banner shows: "Similar to a real event: <class> flare, <date> (NASA DONKI)". The first storm also shows the info card that the countdown stands for incoming particles, not the flash of light.
- If the download fails (network), write placeholder entries marked TODO and tell the owner in one line.

## Clarifications of the timeline (decided, do not re-ask)
- **Warning lengths are real seconds; 1 game hour = 10 s.** A warning of 90 s before a 14:00 storm starts at 05:00. If the start time falls before 06:00 (day 15: storm 12:00, warning 03:00), the countdown is already running when the day begins.
- **Storms during missions:** the timeline does not say when the warning appears. Default: when the mission timer is about 35% elapsed, so a fast player can finish. Keep it in config.
- **Day 4 storm time:** the glance table says 18:00 but the day text and storm table say 20:00 (warning 17:00). Use 20:00.
- **Research per mission:** each mission day is worth 10% / 15% / 20% for science low / medium / high. Use the AVERAGE of the daily values over the mission day and the 3 days before it (so low,low,medium,medium = 12.5%). This reproduces the script's 12.5% on days 12 and 28. Lock the value when the mission ends.
- **Water per day:** used = 2.5 L drinking + 1.0 L radish watering (if watered). Net loss = used x (1 - recycler return), return 0% / 90% / 98% for life support low / medium / high.
- **Power per game hour:** panel output = sum of 4 groups x 2.5 kW x (1 - dust) in sunlight, 0 in shadow. Base draw = sum of the four sliders. Surplus charges the spare pack (on the charger); deficit drains the base pack. 1% of a pack = 1.2 kWh. Gym costs 2 kWh once per session.
- **Expected stocks** in the day script are for a good player and are TARGETS for the simulation test (within about 0.3 L, 1 meal, 2% research).
- Packs show only as % and "hours left at these settings". Never show kWh on screen (only in info cards).

## Open items (do not block on these)
- Story text (3 intro screens, 2 endings) and the ~25 info cards: draft them yourself in kid-friendly English (about 25 words per card, from the hints in docs/03 and the finished cards in docs/05). The owner will edit data/text.json.
- Sound files: the owner generates them (jsfxr). Wire by file name. Optional fallback in docs/05.
- Local organizer confirmation that AI art is fine (owner handles it).
- Hackathon rules, as reported by the organizer and a judge (not seen in writing): AI use allowed if disclosed; research before the event is fine; code, art and sound are made during the event.
