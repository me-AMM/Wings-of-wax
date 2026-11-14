# 03 Day script (32 days)

Stocks are END-OF-DAY values for a good player (medium sliders in daylight, low-ish sliders in shadow, no missed chores). They are test targets and the data behind the Judge mode day jump. Times are game clock (days start 06:00). Shadow plan used for the numbers: life support low, food lights medium, science low, storm watch low (4 kW, 192 kWh over 48 h); life support high for the 2 days after each shadow refills oxygen.

## Run at a glance
| Day | Sky | Lander and mission | Storm | Main jobs | Meals left | Water (L) | Research |
|---|---|---|---|---|---|---|---|
| 1 | Sun | | | Tutorial: walk, eat, drink, sleep | 4 | 19.7 | 0% |
| 2 | Sun | | | Plant radishes, water, gym | 3 | 19.3 | 0% |
| 3 | Sun | | | Clean panels, sliders, packs | 2 | 19.0 | 0% |
| 4 | Sun | Lander 1, Mission 1 (rock) | Small #1, 20:00 | Cargo, mission, lab, shelter | 5 | 21.6 | 15% |
| 5 | Sun | | | Clean dust, gym | 4 | 21.3 | 15% |
| 6 | Sun | | | Quiet day, forecast board | 3 | 20.9 | 15% |
| 7 | Sun | | | Gym, check packs | 2 | 20.6 | 15% |
| 8 | Sun | Lander 2, Mission 2 (ice) | Medium, during mission | Eat first, mission, shelter | 5 | 23.2 | 15% |
| 9 | Sun | | | Harvest 1, lab, clean, shadow warning | 8 | 22.9 | 30% |
| 10 | Sun | | Small #2, 14:00 | Charge both packs, shelter | 7 | 22.5 | 30% |
| 11 | Shadow | | | Lower sliders, swap pack | 6 | 19.0 | 30% |
| 12 | Shadow | Lander 3, Mission 3 (rock, dark) | | Swap pack, mission, lab | 7 | 18.5 | 42.5% |
| 13 | Sun | | | Clean, life support high | 6 | 18.4 | 42.5% |
| 14 | Sun | | Small #3, 20:00 | Gym, swap pack | 5 | 18.4 | 42.5% |
| 15 | Sun | | Small #4, 12:00 | Chores before noon, shelter | 4 | 18.0 | 42.5% |
| 16 | Sun | Lander 4, Mission 4 (ice) | | Harvest 2, mission, lab | 9 | 20.7 | 57.5% |
| 17 | Sun | | | Clean, quiet day | 8 | 20.3 | 57.5% |
| 18 | Sun | | | Gym, quiet day | 7 | 20.0 | 57.5% |
| 19 | Sun | | | Quiet day | 6 | 19.6 | 57.5% |
| 20 | Sun | Lander 5, Mission 5 (rock) | Small #5, during mission | Eat first, mission, shelter | 6 | 19.3 | 57.5% |
| 21 | Sun | | | Lab, clean | 5 | 18.9 | 72.5% |
| 22 | Sun | | | Charge both packs, gym | 4 | 18.6 | 72.5% |
| 23 | Sun | | | Harvest 3, watch high | 7 | 18.2 | 72.5% |
| 24 | Sun | Lander 6, Mission 6 (ice) | Large, during mission | Eat first, mission, shelter | 7 | 17.9 | 72.5% |
| 25 | Shadow | | | Lab, lower sliders, swap pack | 6 | 14.4 | 87.5% |
| 26 | Shadow | | | Swap pack, gym | 5 | 10.9 | 87.5% |
| 27 | Sun | | | Clean, life support high | 4 | 10.8 | 87.5% |
| 28 | Sun | Lander 7 (last), Mission 7 (rock) | | Cargo, mission, lab | 4 | 10.7 | 100% |
| 29 | Sun | | | Clean, gym | 3 | 10.4 | 100% |
| 30 | Sun | | | Harvest 4 | 6 | 10.0 | 100% |
| 31 | Sun | | | Finale prep, packs full | 5 | 9.7 | 100% |
| 32 | Sun | Crew lander, Finale (rare stone) | Finale X28, during mission | Stone, shelter, extraction | 4 | 9.3 | 100% |

## Storms and real events
Eight storms, each labeled "similar to a real event on [date]". Source: NASA CCMC DONKI unless noted. Data goes in data/donki_events.json (see docs/01).

| Day | Storm | When | Real event |
|---|---|---|---|
| 4 | Small #1 | 20:00, after mission 1 | M-class flare, 3-9 May 2024 (pick flrID) |
| 8 | Medium | during mission 2 | X5.8, 11 May 2024 (Gannon storm period; confirm class) |
| 10 | Small #2 | 14:00 | M-class, 3-9 May 2024 (pick flrID) |
| 14 | Small #3 | 20:00 | M-class, 3-9 May 2024 (pick flrID) |
| 15 | Small #4 | 12:00 | M-class, 3-9 May 2024 (pick flrID) |
| 20 | Small #5 | during mission 5 | M-class, 3-9 May 2024 (pick flrID) |
| 24 | Large | during mission 6 | X9.0, 3 Oct 2024 (verified) |
| 32 | Finale | during final mission | X28, 4 Nov 2003 (NOAA / ESA, hand-entered; later estimated up to X45) |

Small storms after the first get no info card, only the "similar to" label.

## Before day 1: start screens
Title (with Judge mode button) -> character select (name + astronaut A or B, portraits) -> 3 story screens: you arrived on an Artemis lander; your crew is working away from the outpost; you keep the outpost running and collect samples until they return in 32 days. Then day 1.

## Day by day
Format: game / player does / new / info cards (title: hint) / end-of-day extras.

- **Day 1 Arrival.** Only the habitat is open; other buildings show the lock. Player: eat a ration (Habitat menu), drink at the recycler, sleep (Habitat menu). New: movement, E, HUD, clock, sleep. Cards: "Welcome to the south pole" (Sun circles low, no daily night); "Breathing" (0.84 kg oxygen a day). End: 4 meals, 19.7 L, oxygen 48 h, Health 100.
- **Day 2 The greenhouse.** Greenhouse, water recycler and gym open. Player: eat, drink, plant and water radish tray (1/7), first gym session. New: radish growth, water use, gym and the Health cap. Cards: "Radishes" (27 days on the ISS, sped up about 4x); "Recycling" (ISS recycles 98% of water; your breath becomes tomorrow's water); "Exercise" (ISS crews train about 2 hours a day). End: 3 meals, 19.3 L, radish 1/7.
- **Day 3 The solar field.** Solar field opens; panels make 7.5 kW (25% landing dust). Player: eat, drink, water radish (2/7), clean all 4 groups (10 kW), try the sliders, try one pack swap. New: dust, sliders, kW budget vs 10 kW, packs in %. Cards: "Solar power" (NASA polar design: 10 kW from 36 m2 of panels on a 10 m mast); "Dust" (Apollo 11 liftoff dimmed a sensor by 17% at once); "Power packs" (a real 120 kWh pack would weigh about 800 kg). HUD notice: "Cargo lander arrives tomorrow at 07:00." End: 2 meals, 19.0 L, dust 0%.
- **Day 4 First mission, first storm.** 07:00 cargo lander 1: dust +25%, cargo 4 rations + 3 L water. Landing pad, lab, shelter open. Player: eat, drink, water radish (3/7), collect cargo, mission 1 (rock and soil, suit 180 s) around 08:00, back about 17:00, process samples (+15%). 17:00 small storm warning (30 s at watch low); 20:00 small storm #1; shelter = sleep for the night, unsheltered = 30% + 20% damage. Cards: "Cargo landers" (real outposts bring most supplies; robot landers help here); "Moonwalks" (longest 7 h 37 min, Apollo 17); "Solar storms" (flare classes M and X; the countdown is for the particles that come after the flash); "The shelter" (about 80 cm of moon soil stops storm particles). After the storm card: "Turn storm watch to medium for longer warnings." End: 5 meals, 21.6 L, research 15%, dust 25%.
- **Day 5 Clean-up.** Player: eat, drink, water radish (4/7), clean dust (10 kW), set storm watch to medium, gym. New: forecast board in the lab (free to read). Card: "Forecasts" (scientists watch the Sun to warn astronauts). End: 4 meals, 21.3 L.
- **Day 6 Quiet day.** Forecast board: "Medium storm expected on day 8." Player: eat, drink, water radish (5/7). Card: "Moon ice" (found in always-dark craters; LCROSS saw water mixed with other chemicals). End: 3 meals, 20.9 L.
- **Day 7 Getting ready.** Player: eat, drink, water radish (6/7), gym, check both packs. Card: "Spacesuits" (about 8 hours of oxygen plus a 30-minute backup). HUD tip: "Eat before tomorrow's mission; a storm may keep you inside." End: 2 meals, 20.6 L.
- **Day 8 Ice mission in a storm.** 07:00 lander 2: dust +25%, 4 rations + 3 L. Player: eat, drink, water radish (7/7), collect cargo, mission 2 (ice dig, suit 120 s). Mid-mission medium storm warning (120 s at watch medium, 60 s at low); a fast player can finish, otherwise abort after the waypoint and keep the ice; shelter for the rest of the day. Real event: X5.8, 11 May 2024. Cards: "Is moon ice drinkable?" (no; must be cleaned first, never done on the Moon); "The Gannon storm" (strongest geomagnetic storm since 2003). End: 5 meals, 23.2 L, samples waiting (15% locked).
- **Day 9 First harvest.** Player: harvest radishes (+4 meals), replant (2nd tray 1/7), eat, drink, process day-8 samples (research 30%), clean dust, gym. HUD: "Crater-rim shadow on days 11 and 12. Charge both packs." Card: "Feeding a person" (about 10 m2 of plants would feed one person; radishes are a fresh extra). End: 8 meals, 22.9 L, research 30%, dust 0%.
- **Day 10 Storm before the dark.** Small storm #2 at 14:00 (warning 05:00 at watch medium, 11:00 at low). Player: do everything in the morning, make sure both packs are 100% (swap if needed), then shelter. Card: "Shadows at the pole" (equator night about 14 days; on a tall mast at the pole shadows last only a few days). End: 7 meals, 22.5 L, both packs 100%.
- **Day 11 Shadow, day one.** Panels 0 kW. Dark filter and visual-only flashlight. Moon icon on HUD. Player: set the shadow plan (life support low, food medium, science low, watch low = 4 kW), eat, drink, water radish (3/7). Base pack falls about 80% (100% to 20%), oxygen reserve -12 h, water -3.5 L (recycler off). Choice shown on purpose: life support medium saves oxygen and water but leaves only 20% spare power; food lights low saves power but pauses the radishes 2 days. Card: "Power in the dark" (NASA plans a 40 kW fission reactor for future bases). End: 6 meals, 19.0 L, oxygen 36 h, base pack about 20%, spare pack 100%.
- **Day 12 Mission in the dark.** 06:00 swap packs. 07:00 lander 3 lands in the dark: dust +25%, 2 rations + 3 L. Player: eat, drink, water radish (4/7), collect cargo, mission 3 (rock, darker filter, suit 120 s), process samples (12.5%, research 42.5%). Card: "Radiation on the surface" (about 1.37 mSv a day, like an X-ray every day). End: 7 meals, 18.5 L, oxygen 24 h, both packs about 20%.
- **Day 13 Sunrise.** Panels return at 7.5 kW (25% dust). Player: clean first (10 kW), life support high and the rest medium (7 kW, 3 kW spare), eat, drink, water radish (5/7). Oxygen +12 h, spare pack +about 60%. End: 6 meals, 18.4 L, oxygen 36 h, spare pack about 80%.
- **Day 14 Recharge.** Small storm #3 at 20:00 (warning 11:00 at medium). Player: swap packs so the low one charges, gym, eat, drink, water radish (6/7), keep life support high, shelter in the evening. Card: "A busy Sun" (NASA counted 82 notable flares in one week of May 2024). End: 5 meals, 18.4 L, oxygen 48 h.
- **Day 15 Two storms in a row.** Small storm #4 at 12:00 (warning 03:00 at medium, so it is waiting when you wake; 09:00 at low). Player: life support back to medium, eat, drink, water radish (7/7) before noon, then shelter. Lesson: do daily chores first. End: 4 meals, 18.0 L.
- **Day 16 Second harvest.** 07:00 lander 4: dust +25%, 2 rations + last 3 L. Player: harvest (+4), replant (tray 3 at 1/7), eat, drink, collect cargo, mission 4 (ice dig), process samples (57.5%). HUD: "Last water delivery. From now on, the recycler is everything." End: 9 meals, 20.7 L, research 57.5%, dust 25%.
- **Day 17 Quiet.** Clean dust, eat, drink, water radish (2/7). Card: "Muscles on the Moon" (scientists don't know yet how 1/6 gravity affects bones over weeks; maybe you'll find out). End: 8 meals, 20.3 L, dust 0%.
- **Day 18 Quiet.** Gym, eat, drink, water radish (3/7). Card: "Space food" (a day of food is about 2,500-2,800 kcal, about 1.8 kg). End: 7 meals, 20.0 L.
- **Day 19 Quiet.** Forecast board: "Small storm expected on day 20." Eat, drink, water radish (4/7). Tip: "Eat before tomorrow's mission." Card: "Getting braver" (Apollo moonwalks grew from 2.5 h to about 7.5 h). End: 6 meals, 19.6 L.
- **Day 20 Storm on the walk.** 07:00 lander 5: dust +25%, 1 ration. Player: eat, drink, water radish (5/7), collect cargo, mission 5 (rock). Mid-mission small storm #5 warning (90 s at medium); finish fast or abort after the waypoint; shelter the rest of the day. End: 6 meals, 19.3 L, samples waiting (15% locked), dust 25%.
- **Day 21 Big storm forecast.** Process samples (research 72.5%), clean dust, eat, drink, water radish (6/7). Forecast board: "Large storm expected on day 24." HUD: "Shadow on days 25 and 26." Card: "The biggest storms" (largest geomagnetic storm was 1859; the August 1972 storm hit between Apollo 16 and 17 and could have been deadly on the Moon). End: 5 meals, 18.9 L, research 72.5%.
- **Day 22 Getting ready.** Charge both packs to 100% (swap once), gym, eat, drink, water radish (7/7). End: 4 meals, 18.6 L, both packs about 100%.
- **Day 23 Third harvest.** Harvest (+4), replant (tray 4 at 1/7), eat, drink, set storm watch to high. HUD: "Storm expected tomorrow." Card: "Why forecasts work" (storm clouds from the Sun usually take 2-3 days; the fastest took 14.6 hours). End: 7 meals, 18.2 L.
- **Day 24 The large storm.** 07:00 lander 6: dust +25%, 1 ration. Player: eat, drink, water radish (2/7), collect cargo, mission 6 (ice dig). Mid-mission large storm warning (150 s at watch medium or high, 90 s at low). Get back and shelter: -5 Health. Not sheltered: mission failed. Real event X9.0, 3 Oct 2024. End: 7 meals, 17.9 L, samples waiting (15% locked).
- **Day 25 Shadow again.** Panels 0 kW, dark filter. Process day-24 samples (research 87.5%), set the shadow plan (4 kW), eat, drink, water radish (3/7). Base pack 100% to about 20%, oxygen 48 h to 36 h, water -3.5 L. End: 6 meals, 14.4 L, oxygen 36 h.
- **Day 26 Shadow, day two.** Swap packs at 06:00, gym (2 kWh fits), eat, drink, water radish (4/7). HUD warning: water under 12 L, "Keep life support at medium or high after sunrise to recycle." End: 5 meals, 10.9 L, oxygen 24 h, both packs about 20%.
- **Day 27 Sunrise.** Clean dust (from day 24), life support high and the rest medium, eat, drink, water radish (5/7). End: 4 meals, 10.8 L, oxygen 36 h, spare pack about 80%.
- **Day 28 Last cargo.** 07:00 lander 7: dust +25%, 1 ration. Player: eat, drink, water radish (6/7), collect cargo, mission 7 (rock), process samples (12.5% because of the shadow days, research 100%). End: 4 meals, 10.7 L, oxygen 48 h, research 100%.
- **Day 29 Wrapping up.** Clean dust, life support back to medium, gym, eat, drink, water radish (7/7), swap so both packs fill. End: 3 meals, 10.4 L.
- **Day 30 Last harvest.** Harvest (+4), eat, drink. Replanting allowed but won't finish. Card: "Potatoes in space" (on Space Shuttle STS-73, potato cuttings grew tiny tubers in 16 days). End: 6 meals, 10.0 L.
- **Day 31 Before the finale.** Forecast board: "A huge flare is building. The crew lander comes tomorrow." Eat, drink, gym, top up Health, both packs full. End: 5 meals, 9.7 L, Health near max.
- **Day 32 The finale.** Eat, drink, then the final mission: find the rare stone. Fixed 180 s warning. Grab the stone and get to the shelter; not sheltered = mission failed. Real event X28, 4 Nov 2003 (brightest X-ray flare ever measured). After the storm the crew lander arrives; extraction is a still scene. Ending screen: "You achieved X% of the mission" plus stars, then credits. End: 4 meals, 9.3 L, research 100% (5 stars).

## Placement of the three new resource cards (texts in docs/05)
OSDR bone card on day 2 (with "Exercise"); CSA radish card on day 9 (first harvest); RadLab storm card on day 15.
