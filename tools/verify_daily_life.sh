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
  local mode="$1"
  shift
  # Each standalone suite starts a separate player profile, including migration
  # sidecars. A prior suite's fault fixture is not a real next-player save.
  case_number=$((case_number + 1))
  export XDG_DATA_HOME="$state/case-$case_number/data" XDG_CONFIG_HOME="$state/case-$case_number/config" XDG_CACHE_HOME="$state/case-$case_number/cache"
  export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
  case "$mode" in
    import) run_verified_godot "$state/run.log" --headless --path . --editor --import --quit ;;
    suite) run_verified_godot_suite "$state/run.log" "$1" --headless --path . ;;
    *) echo "Unknown Godot verification mode: $mode" >&2; return 1 ;;
  esac
}
run_godot import
run_godot suite test/test_suite.tscn
run_godot suite test/hint_paper_width_suite.gd
run_godot suite test/locomotion_suite.tscn
run_godot suite test/road_freedom_suite.gd
for suite in weather_transition holiday_start_once animal_home photo_home grass_state grass_action explicit_target ui_interaction physical_yard keyboard_ground scrapbook_encounter photo_moment_render photo_moment_save save_data_codec yard_snapshot fishing_active_hud save_recovery boundary_feedback mixed_input_photo leading_clearance portable_accept shipped_correctness interaction_photo scene_hotspot authored_sequence goose_mount quiet_stay quiet_sky_look camera400_handoff camera400_backdrop still_catch still_target_pulse still_grass_glow still_object_feedback interaction_pose cow_glance sheep_attention duck_feed_attention goose_feed_attention fish_carry_consistency notice_paper photo_species_frame web_hidpi save_candidate exploration_core fish_miss_feedback save_coordinator native_save_host save_writer_guidance exploration_cleanup_contract exploration_cleanup_preservation save_feedback day_label_layout exploration_slice title_card hint_paper_fit confirm_panel_fit title_short_landscape licenses_dialog_fit motion_preference photo_arrival_fit photo_arrival_combo photo_arrival_mat photo_arrival_shutter_paper album_short_landscape title_licenses_link_contrast soft_button_focus_contrast soft_button_disabled volume_slider_style volume_slider_input paper_tooltip_style paper_tooltip_interaction; do
  run_godot suite "test/${suite}_suite.gd"
done
run_godot suite test/album_layout_suite.gd
run_godot suite test/photo_caption_fit_suite.gd
run_godot suite test/save_status_paper_suite.gd
run_godot suite test/pause_notice_suite.gd
run_godot suite test/audio_button_input_suite.gd
run_godot suite test/ambience_output_ceiling_suite.gd
run_godot suite test/modal_touch_input_suite.gd
run_godot suite test/yard_inventory_suite.gd
run_godot suite test/yard_decor_suite.gd
run_godot suite test/yard_decor_persistence_suite.gd
run_godot suite test/yard_decor_integration_suite.gd
run_godot suite test/yard_decor_button_states_suite.gd
run_godot suite test/yard_decor_panel_hug_suite.gd
run_godot suite test/yard_decor_nudge_limit_suite.gd
run_godot suite test/yard_ground_food_ledger_suite.gd
run_godot suite test/yard_ground_food_runtime_suite.gd
run_godot suite test/cow_ground_graze_suite.gd
run_godot suite test/animal_companion_suite.gd
run_godot suite test/animal_hidden_find_suite.gd
run_godot suite test/world_residents_suite.gd
run_godot suite test/beibei_integration_suite.gd
run_godot suite test/pond_residents_suite.gd
run_godot suite test/pond_integration_suite.gd
run_godot suite test/chick_millet_model_suite.gd
run_godot suite test/chick_millet_integration_suite.gd
run_godot suite test/pond_story_sequence_suite.gd
run_godot suite test/pond_story_integration_suite.gd
run_godot suite test/yard_basket_integration_suite.gd
run_godot suite test/yard_basket_button_states_suite.gd
run_godot suite test/paper_scrollbar_suite.gd
run_godot suite test/exploration_button_states_suite.gd
run_godot suite test/still_boundary_feedback_suite.gd
run_godot suite test/pause_panel_fit_suite.gd
run_godot suite test/ui_viewports.gd
run_godot suite test/web_save_bridge/decoder_suite.gd
run_godot suite test/web_save_bridge/legacy_suite.gd
run_godot suite test/title_copy_balance_suite.gd
run_godot suite test/touch_hint_mode_suite.gd
node test/loading_shell_test.cjs

node test/motion_preference_test.cjs

run_godot suite test/album_caption_fit_suite.gd

run_godot suite test/photo_arrival_shutter_fit_suite.gd

run_godot suite test/exploration_basket_label_fit_suite.gd

run_godot suite test/yard_basket_panel_fit_suite.gd

run_godot suite test/confirm_panel_narrow_suite.gd

run_godot suite test/find_reveal_name_slip_suite.gd
