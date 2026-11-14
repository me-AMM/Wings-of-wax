# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
class_name UIStyle
extends RefCounted
# One style sheet for the whole UI. Colours come from assets/palette.png. Use these instead of hard-coded colours.
const PANEL_DARK := Color("0B0D1A")      # panel / backing background
const PANEL_BORDER := Color("3D4560")    # panel border, inactive
const TEXT_LIGHT := Color("E4E8F2")      # body text
const ACCENT := Color("FFD23F")          # titles, goals, highlights
const DANGER := Color("E5484D")          # low values, storms, damage
const GOOD := Color("5FC96B")            # done, healthy, spare power
const INFO := Color("9BE8FF")            # data sources, spare pack, water
const JUDGE := Color("F06FA8")           # judge mode only
# text sizes (real pixels at the 640x360 base): small, body, title
const SMALL := 12
const BODY := 16
const TITLE := 24
# spacing (4 px grid)
const PAD := 8
const GAP := 4
const RADIUS := 2
# motion
const PANEL_FADE := 0.12
const PANEL_SLIDE := 2.0
const SCENE_FADE := 0.2
