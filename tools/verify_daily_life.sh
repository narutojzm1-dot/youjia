#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
state="$(mktemp -d /tmp/youjia-daily-check.XXXXXX)"
trap 'rm -rf "$state"' EXIT
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
run_godot() {
  timeout 300 "${GODOT:-godot}" "$@" 2>&1 | tee "$state/run.log"
  if grep -Eq '^(SCRIPT ERROR|ERROR:)' "$state/run.log"; then
    echo "[daily-check] Godot reported an error" >&2
    exit 1
  fi
}
run_godot --headless --path . --editor --import --quit
run_godot --headless --path . res://test/test_suite.tscn
run_godot --headless --path . res://test/locomotion_suite.tscn
for suite in animal_home photo_home grass_state explicit_target ui_interaction physical_yard keyboard_ground photo_moment_render photo_moment_save boundary_feedback mixed_input_photo leading_clearance portable_accept shipped_correctness interaction_photo scene_hotspot authored_sequence; do
  run_godot --headless --path . --script "test/${suite}_suite.gd"
done
run_godot --headless --path . --script test/ui_viewports.gd
node test/loading_shell_test.cjs
