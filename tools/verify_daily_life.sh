#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
state="$(mktemp -d /tmp/youjia-daily-check.XXXXXX)"
trap 'rm -rf "$state"' EXIT
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
source tools/lib/verified_godot.sh
bash test/godot_gate_test.sh
run_godot() {
  run_verified_godot "$state/run.log" "$@"
}
run_godot --headless --path . --editor --import --quit
run_godot --headless --path . res://test/test_suite.tscn
run_godot --headless --path . res://test/locomotion_suite.tscn
for suite in animal_home photo_home grass_state grass_action explicit_target ui_interaction physical_yard keyboard_ground scrapbook_encounter photo_moment_render photo_moment_save save_data_codec save_recovery boundary_feedback mixed_input_photo leading_clearance portable_accept shipped_correctness interaction_photo scene_hotspot authored_sequence goose_mount quiet_stay quiet_sky_look still_catch still_target_pulse still_grass_glow still_object_feedback interaction_pose cow_glance; do
  run_godot --headless --path . --script "test/${suite}_suite.gd"
done
run_godot --headless --path . --script test/still_boundary_feedback_suite.gd
run_godot --headless --path . --script test/ui_viewports.gd
node test/loading_shell_test.cjs
