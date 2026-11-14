#!/bin/sh
# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# Records every clip with Godot Movie Maker (1280x720, 30 fps, game audio) into docs/video/clips/*.avi
G="${GODOT:-E:/AMUNi/Wings of wax/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
mkdir -p docs/video/clips
for c in ${@:-title story chores_eat chores_sliders chores_panel chores_pack chores_harvest mission_rock mission_ice mission_storm finale extraction x_shadow x_sun x_log x_lander}; do
  echo "== $c"
  "$G" --path . --write-movie "docs/video/clips/$c.avi" --fixed-fps 30 --quit-after 1200 res://tools/record_clips.tscn -- clip=$c 2>&1 | grep -E "SCRIPT ERROR|ERROR:" | grep -v "resources still" | head -3
done
