# 02 Rulebook: every number the code needs

All values are game-scaled. Put them in data/config.json. docs/01_DECISIONS.md overrides where it says so.

## Time
- 1 game day = 24 game hours = 4 real minutes, so 1 game hour = 10 real seconds.
- Each day starts at 06:00. Sleep skips 8 game hours, once per day, with a 150-second real cooldown. Awake time is about 16 game hours (160 s).
- The day rolls over after 24 game hours. No sleep that day = -10 Health instead of the sleep heal.
- A mission (about 90 s) uses about 9 game hours, so mission days leave about 7 hours for chores.
- The clock is Earth time, like on the ISS. There is NO daily sunset (the Sun circles low at the south pole).

## Power
- 4 panel groups x 2.5 kW = 10 kW in full sunlight. Each group loses output by its dust %.
- Shadow days (11-12 and 25-26, "crater-rim shadow"): panels make 0 kW.
- Sliders (set at the solar field console):

| Slider | Low | Medium | High | What it changes |
|---|---|---|---|---|
| Life support | 2 kW | 3 kW | 4 kW | Oxygen reserve and water recycling |
| Food lights | 0.5 kW | 1 kW | 1.5 kW | Radish growth and harvest size |
| Science & health | 0.5 kW | 1 kW | 2 kW | Research per mission and sleep heal |
| Storm watch | 0.5 kW | 1 kW | 1.5 kW | Warning length and forecasts |
| Total | 3.5 | 6 | 9 | |

- Starting sliders: life support, food and science medium; storm watch low (5.5 kW).
- Gym: 2 kWh per session (about 2% of a pack).

## Power packs
- 2 packs, each 120 kWh, shown only as % and "hours left at these settings". 1% = 1.2 kWh.
- One pack is plugged into the base; the other sits on the charger at the solar field (sprites charger_full / charger_empty).
- Each game hour: if panels make more than the base draws, the base runs on sunlight and the leftover charges the charger pack. If panels make less, the base pack covers the gap.
- Medium sliders in clean sunlight leave 4 kW spare: the charger pack gains about 80% per day.
- Swap = hold E for 2 s at the solar field; the packs trade places.
- Below 10% charge: warning light. Base pack at 0% with no sunlight = blackout: backup life support holds oxygen for 24 game hours, everything else shuts off, sleep is blocked. Swapping in any charged pack ends it.
- Shadow check (48 h on packs, 240 kWh total): all low = 168 kWh (fits, 60% left); life support medium + rest low = 216 kWh (fits, 20% left); all medium = 288 kWh (blackout about 8 h before sunrise). Use as a test case.

## Dust
- Start at 25% on every group (from your own landing).
- Every lander touchdown adds +25% to every group, max 75%.
- Cleaning: hold E for 2 s at a group; that group goes to 0%. Four groups is about 1 game hour of work.
- Effect at medium sliders: 25% dust still charges the spare pack (+30%/day); 50% drains the base pack (-20%/day); 75% drains fast (-70%/day). Use as test cases.

## Oxygen and water
- Habitat oxygen reserve: max 48 h, start 48 h. Life support low = -12 h per day, medium = holds, high = +12 h per day. At 0 h: -5 Health per game hour.
- Water tank: start 20 L, max 40 L. Drinking 2.5 L/day plus radish watering 1 L/day = 3.5 L used.
- Recycler returns: life support low = 0% (off), medium = 90%, high = 98%. Net loss per day: 3.5 L / 0.35 L / 0.07 L.
- Water drops: +3 L on days 4, 8, 12 and 16 only (with cargo landers 1-4).
- Water under 12 L: HUD warning ("Keep life support at medium or high after sunrise to recycle.").

## Food (radishes and rations)
- One meal per day: one ration or one radish meal. Both heal +10.
- Rations: start 5; landers bring 4, 4, 2, 2, 1, 1, 1 (days 4-28) = 20 total.
- Radish tray: water once a day (1 L). A day counts toward growth only if it was watered AND food lights were not low. After 7 growth days: harvest 4 meals (5 if food lights were high on at least 4 of the 7 days). Replant in the same visit.
- Planned harvests if nothing is missed: days 9, 16, 23, 30 = 16 meals. Rations + radishes = 36 meals for 32 days.
- Sprites: radish_empty, radish_sprout, radish_growing, radish_ready (+ radish_ready_sway animation).

## Health
- One bar, 0-100. Heals: meal +10, gym +5, sleep +5 / +10 / +15 (science & health low / medium / high).
- Damage (game rules, label them as such): no drink 2+ days in a row = -10 per day; no meal 3+ days in a row = -10 per day; no sleep = -10; out of suit oxygen = -30; oxygen reserve empty = -5 per game hour.
- Gym: 1 game hour, 2 kWh, 2-day cooldown. No gym for 7 days = max Health 90; 14 days = max 75. One session lifts the cap again.

## Storm watch and storms
- Damage is a % of CURRENT Health. Watch high also shows "storm expected tomorrow" on the HUD the day before.
- The forecast board in the lab is free to read; at watch medium or high it names the next storm and its day.
- Shelter: forced sleep until the day ends, counts as that day's sleep, the player can't leave. Undone chores are delayed, not lost.
- The countdown stands for incoming particles, not the flare's light (first info card says so).

| Storm | Warning at watch low | Warning at watch medium/high | Unsheltered damage | Sheltered |
|---|---|---|---|---|
| Small (M-class) | 30 s | 90 s | 30% now + 20% over time | none |
| Medium (X1-X5) | 60 s | 120 s | 50% now + 30% over time | none |
| Large (X9) | 90 s | 150 s | Mission failed | tiny (-5 Health) |
| Finale (X28, day 32) | 180 s | 180 s | Mission failed | tiny (-5 Health) |

## Missions
- Start at the landing pad (E). Separate screen. About 90 s. Suit meter 120 s (180 s on mission 1), displayed as "8 h".
- Craters slow the player and drain suit oxygen 1.25x. Abort keeps samples only if the waypoint was reached. Out of suit oxygen: -30 Health, samples lost, back at base.
- Types: rock and soil (missions 1, 3, 5, 7), ice dig (2, 4, 6), rare stone (finale, day 32).
- Ice dig: bar with a fixed green target zone and a moving marker (see assets/manifest.json, ui_layout.dig_bar).

## Research and stars
- Process samples only at the lab (E). Each mission adds 10% / 15% / 20% (see docs/01 for the averaging rule), locked when the mission ends.
- 7 regular missions x 15% = 105% at medium, capped at 100%. One failed mission at medium = 90%.
- Stars: 100% = 5, 80% = 4, 60% = 3, 40% = 2, 20% = 1, below 20% = none.
- Ending screen: "You achieved X% of the mission" plus stars, then credits. The finale stone is story-only.

## Landers
- A robot cargo lander touches down at 07:00 on days 4, 8, 12, 16, 20, 24, 28. It adds +25% dust and brings cargo (rations/water per above); cargo waits on the pad until collected (E). Use the cargo_lander_touchdown animation, then the static cargo_lander.
- Day 32: the crew lander (crew_lander) comes to take you home (extraction is a still scene).

## Start state (before day 1)
Health 100, 5 rations, 20 L water, oxygen reserve 48 h, both packs 100%, dust 25%, sliders as above. Pick a name and one of 2 astronauts (A blue accents, B pink accents).

## Day 1-3 unlocks
Day 1: only the habitat is open (other buildings show the lock icon, "opens on day 2/3"). Day 2: greenhouse, water recycler and gym (menu) open. Day 3: solar field opens. Day 4: landing pad, lab and shelter open.
