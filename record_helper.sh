#!/usr/bin/env bash
# Opens one benchmark windowed, for screen recording. No movie writer: physics is identical
# either way (fixed 60 Hz dt), and recording the screen is far faster than rendering frames.
#
#   ./record_helper.sh 2d Rapier2D pyramid
#   ./record_helper.sh 3d "Jolt Physics" smash
#   ./record_helper.sh 2d Rapier2D all     # every case back to back, 5s each
#   ./record_helper.sh 2d Box2D            # no case: opens the menu, pick cases by hand
#
# SECS sets how long each case runs in play-all mode, default 5 (wall-clock seconds, so
# every engine's clip is the same length even when it steps far slower).
#
# RES overrides the window size, default 1920x1080.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd "$HERE"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
DIM="${1:?dim: 2d or 3d}"; ENGINE="${2:?engine name}"; CASE="${3:-}"
SECS="${SECS:-5}"
RES="${RES:-1920x1080}"
PROJECT="bench$DIM"
printf '[physics]\n\n%s/physics_engine="%s"\n' "$DIM" "$ENGINE" > "$PROJECT/override.cfg"

# Godot silently falls back to its own server when the engine name is not registered — no
# error, no warning, and the recording is then of the wrong engine entirely. Check the name
# against the setting's property hint before spending a take on it.
cat > "$PROJECT/_engines.gd" <<'EOF'
extends Node
func _ready() -> void:
	var want := "physics/%s/physics_engine" % OS.get_environment("BENCH_DIM")
	for p in ProjectSettings.get_property_list():
		if String(p.name) == want:
			print("ENGINES|" + p.hint_string)
	get_tree().quit()
EOF
cat > "$PROJECT/_engines.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://_engines.gd" id="1"]
[node name="P" type="Node"]
script = ExtResource("1")
EOF
REGISTERED="$(BENCH_DIM="$DIM" "$GODOT" --headless --path "$PROJECT" _engines.tscn 2>/dev/null \
    | grep '^ENGINES|' | head -1 | cut -d'|' -f2 | tr -d '\r')"
rm -f "$PROJECT/_engines.gd" "$PROJECT/_engines.gd.uid" "$PROJECT/_engines.tscn"
if [[ ",${REGISTERED}," != *",${ENGINE},"* ]]; then
    echo "error: '$ENGINE' is not a registered $DIM engine." >&2
    echo "       registered: ${REGISTERED//,/, }" >&2
    rm -f "$PROJECT/override.cfg"
    exit 1
fi

echo "$ENGINE / ${CASE:-menu} @ $RES  — Cmd+Shift+5 to record, Esc for menu"
if [[ "$CASE" == "all" ]]; then
    "$GODOT" --path "$PROJECT" --resolution "$RES" -- --play-all --record-seconds="$SECS"
elif [[ -n "$CASE" ]]; then
    "$GODOT" --path "$PROJECT" --resolution "$RES" -- --case="$CASE"
else
    "$GODOT" --path "$PROJECT" --resolution "$RES"
fi
rm -f "$PROJECT/override.cfg"
