#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
state="$(mktemp -d /tmp/youjia-daily-check.XXXXXX)"
trap 'rm -rf "$state"' EXIT
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
run_godot() {
  # Godot --script 在 quit(0) 后偶发非零退出码；以日志中的 SCRIPT ERROR/ERROR: 为准，避免 pipefail 误杀后续套件。
  set +e
  timeout 300 "${GODOT:-godot}" "$@" 2>&1 | tee "$state/run.log"
  set -e
  if grep -Eq '^(SCRIPT ERROR|ERROR:)' "$state/run.log"; then
    echo "[daily-check] Godot reported an error" >&2
    exit 1
  fi
}
run_godot --headless --path . --editor --import --quit
run_godot --headless --path . res://test/test_suite.tscn
run_godot --headless --path . res://test/locomotion_suite.tscn
for suite in animal_home photo_home grass_state grass_action explicit_target ui_interaction physical_yard keyboard_ground scrapbook_encounter photo_moment_render photo_moment_save boundary_feedback mixed_input_photo leading_clearance portable_accept shipped_correctness interaction_photo scene_hotspot authored_sequence goose_mount quiet_stay quiet_sky_look still_catch still_target_pulse; do
  run_godot --headless --path . --script "test/${suite}_suite.gd"
done
run_godot --headless --path . --script test/ui_viewports.gd
node test/loading_shell_test.cjs
