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
case_number=0
run_godot() {
  # Each standalone suite starts a separate player profile, including migration
  # sidecars. A prior suite's fault fixture is not a real next-player save.
  case_number=$((case_number + 1))
  export XDG_DATA_HOME="$state/case-$case_number/data" XDG_CONFIG_HOME="$state/case-$case_number/config" XDG_CACHE_HOME="$state/case-$case_number/cache"
  export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
  run_verified_godot "$state/run.log" "$@"
}
run_godot --headless --path . --editor --import --quit
run_godot --headless --path . res://test/test_suite.tscn
run_godot --headless --path . res://test/locomotion_suite.tscn
for suite in animal_home photo_home grass_state grass_action explicit_target ui_interaction physical_yard keyboard_ground scrapbook_encounter photo_moment_render photo_moment_save save_data_codec yard_snapshot fishing_active_hud save_recovery boundary_feedback mixed_input_photo leading_clearance portable_accept shipped_correctness interaction_photo scene_hotspot authored_sequence goose_mount quiet_stay quiet_sky_look still_catch still_target_pulse still_grass_glow still_object_feedback interaction_pose cow_glance duck_feed_attention goose_feed_attention fish_carry_consistency notice_paper photo_species_frame web_hidpi save_candidate exploration_core fish_miss_feedback save_coordinator native_save_host exploration_cleanup_contract save_feedback day_label_layout exploration_slice title_card hint_paper_fit confirm_panel_fit; do
  run_godot --headless --path . --script "test/${suite}_suite.gd"
done
run_godot --headless --path . --script test/album_layout_suite.gd
run_godot --headless --path . --script test/pause_notice_suite.gd
run_godot --headless --path . --script test/still_boundary_feedback_suite.gd
run_godot --headless --path . --script test/ui_viewports.gd
run_godot --headless --path . --script test/web_save_bridge/decoder_suite.gd
run_godot --headless --path . --script test/web_save_bridge/legacy_suite.gd
node test/loading_shell_test.cjs

