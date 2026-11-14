# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
"""Builds data/days.json from the docs/03 glance table plus the day text.
Run: python tools/build_days.py   (standard library only)
Edit the dicts below if the script changes; days.json is DATA that the game reads."""
import json, re, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
table = (root / "docs" / "03_DAY_SCRIPT.md").read_text(encoding="utf-8")

# expected end-of-day values from the table (test targets for sim_check)
expect = {}
for line in table.splitlines():
    m = re.match(r"\|\s*(\d+)\s*\|(.*)\|\s*$", line)
    if not m:
        continue
    cols = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cols) < 8:
        continue
    d = int(cols[0])
    expect[d] = {
        "meals": int(cols[5]),
        "water": float(cols[6]),
        "research": float(cols[7].replace("%", "")),
    }

shadow_days = [11, 12, 25, 26]
landers = {  # day: (rations, water)
    4: (4, 3), 8: (4, 3), 12: (2, 3), 16: (2, 3), 20: (1, 0), 24: (1, 0), 28: (1, 0)}
missions = {4: "rock", 8: "ice", 12: "rock", 16: "ice", 20: "rock", 24: "ice", 28: "rock", 32: "finale"}
# storms: day -> size, hit hour (game clock), in_mission, event id (see data/donki_events.json)
storms = {
    4: ("small", 20.0, False, "small1"),
    8: ("medium", 0, True, "medium1"),
    10: ("small", 14.0, False, "small2"),
    14: ("small", 20.0, False, "small3"),
    15: ("small", 12.0, False, "small4"),
    20: ("small", 0, True, "small5"),
    24: ("large", 0, True, "large1"),
    32: ("finale", 0, True, "finale"),
}
cards = {
    1: ["welcome", "breathing"], 2: ["radishes", "recycling", "exercise", "osdr_gym"],
    3: ["solar", "dust", "packs"], 4: ["cargo_landers", "moonwalks", "solar_storms", "shelter_card"],
    5: ["forecasts"], 6: ["moon_ice"], 7: ["spacesuits", "silent_moon"],
    8: ["ice_drink", "gannon"], 9: ["feeding_person", "csa_radish"], 10: ["shadows"],
    11: ["power_dark"], 12: ["radiation"], 14: ["busy_sun"], 15: ["radlab_storm"],
    17: ["muscles"], 18: ["space_food"], 19: ["getting_braver"], 21: ["biggest_storms"],
    23: ["why_forecasts_work"], 30: ["potatoes"],
}
# HUD notices shown at day start (keys in data/text.json "notices")
notices = {
    3: ["cargo_tomorrow"], 4: ["storm_watch_tip"], 7: ["eat_before_mission"], 9: ["shadow_11_12"],
    16: ["last_water"], 19: ["eat_before_mission"], 21: ["shadow_25_26"],
    23: ["storm_tomorrow"], 26: ["water_low_tip"], 32: ["final_mission"],
}
# forecast board messages (text keys), what the lab board says on that day
forecast = {6: "fc_medium_8", 19: "fc_small_20", 21: "fc_large_24", 31: "fc_finale"}

days = []
for d in range(1, 33):
    st = storms.get(d)
    days.append({
        "day": d,
        "sky": "shadow" if d in shadow_days else "sun",
        "lander": ({"rations": landers[d][0], "water": landers[d][1]} if d in landers else None),
        "crew_lander": d == 32,
        "mission": missions.get(d),
        "storm": ({"size": st[0], "at": st[1], "in_mission": st[2], "event": st[3]} if st else None),
        "cards": cards.get(d, []),
        "notices": notices.get(d, []),
        "forecast": forecast.get(d, ""),
        "expect": expect[d],
    })

(root / "data" / "days.json").write_text(json.dumps(days, indent=1), encoding="utf-8")
print("days.json written:", len(days), "days")
