# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
"""Downloads real solar flares from NASA CCMC DONKI and writes data/donki_events.json.
Standard library only. Run once:  python tools/fetch_donki.py
The game reads ONLY data/donki_events.json (no live calls). No API key needed.
If the download fails, placeholder entries marked TODO are written instead."""
import json, pathlib, urllib.request

root = pathlib.Path(__file__).resolve().parent.parent
BASE = "https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR"

def get(start, end):
    with urllib.request.urlopen(f"{BASE}?startDate={start}&endDate={end}", timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))

def entry(f, slot):
    return {"slot": slot, "flrID": f.get("flrID"), "classType": f.get("classType"),
            "peakTime": f.get("peakTime"), "sourceLocation": f.get("sourceLocation"),
            "activeRegionNum": f.get("activeRegionNum"), "source": "NASA CCMC DONKI", "todo": False}

def pick_class(flares, prefix, used_days, n):
    out = []
    for f in sorted(flares, key=lambda x: x.get("peakTime", "")):
        ct = f.get("classType") or ""
        day = (f.get("peakTime") or "")[:10]
        if ct.startswith(prefix) and day not in used_days and f.get("flrID"):
            out.append(f)
            used_days.add(day)
        if len(out) == n:
            break
    return out

slots_small = ["small1", "small2", "small3", "small4", "small5"]
events = {}
try:
    may = get("2024-05-03", "2024-05-09")
    chosen = pick_class(may, "M", set(), 5)
    for slot, f in zip(slots_small, chosen):
        events[slot] = entry(f, slot)
    may11 = get("2024-05-11", "2024-05-11")
    x58 = [f for f in may11 if (f.get("classType") or "").startswith("X5")]
    if x58:
        events["medium1"] = entry(x58[0], "medium1")
    oct3 = get("2024-10-03", "2024-10-03")
    x9 = [f for f in oct3 if (f.get("classType") or "").startswith("X9")]
    if x9:
        events["large1"] = entry(x9[0], "large1")
    print("downloaded: M-class picked", len(chosen), "| X5.8 found", "medium1" in events, "| X9.0 found", "large1" in events)
except Exception as e:
    print("DOWNLOAD FAILED:", e, "- writing placeholders marked TODO")

# placeholders for anything missing (kept clearly marked)
placeholders = {
    "small1": ("M5.0", "2024-05-05T00:00Z"), "small2": ("M5.0", "2024-05-06T00:00Z"),
    "small3": ("M5.0", "2024-05-07T00:00Z"), "small4": ("M5.0", "2024-05-08T00:00Z"),
    "small5": ("M5.0", "2024-05-09T00:00Z"), "medium1": ("X5.8", "2024-05-11T01:23Z"),
    "large1": ("X9.0", "2024-10-03T12:18Z")}
for slot, (cls, t) in placeholders.items():
    if slot not in events:
        events[slot] = {"slot": slot, "flrID": "TODO", "classType": cls, "peakTime": t, "sourceLocation": "TODO",
                        "activeRegionNum": None, "source": "NASA CCMC DONKI", "todo": True}
# the 2003 flare is not in DONKI: hand-entered
events["finale"] = {"slot": "finale", "flrID": "hand-entered", "classType": "X28", "peakTime": "2003-11-04T19:53Z",
                    "sourceLocation": "S19W83", "activeRegionNum": 486, "source": "NOAA / ESA",
                    "note": "the brightest X-ray flare ever measured (later estimated up to X45)", "todo": False}
(root / "data" / "donki_events.json").write_text(json.dumps(events, indent=1), encoding="utf-8")
for k, v in events.items():
    print(k, v["classType"], v["peakTime"], v["flrID"], "TODO" if v["todo"] else "")
