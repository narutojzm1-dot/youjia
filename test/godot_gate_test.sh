#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d /tmp/youjia-gate-contract.XXXXXX)"
trap 'rm -rf "$fixture"' EXIT
cat > "$fixture/godot" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_ARGS"
printf '%s' "${MOCK_OUTPUT:-}"
exit "${MOCK_EXIT:-0}"
MOCK
chmod +x "$fixture/godot"
checks=0
run_case() {
  local name="$1" expected="$2" code="$3" output="$4" fault="$5" mode="$6" entry="$7"
  rm -f "$fixture/continued" "$fixture/args" "$fixture/run.log"
  if GODOT="$fixture/godot" MOCK_ARGS="$fixture/args" MOCK_EXIT="$code" MOCK_OUTPUT="$output" GATE_FAULT="$fault" \
    bash -euo pipefail -c '
      source "$1/tools/lib/verified_godot.sh"
      case "$GATE_FAULT" in
        tee) tee() { cat >/dev/null; return 74; } ;;
        missing-log) tee() { cat >/dev/null; } ;;
        completion-read) grep() { if [[ "$1" == -Ex ]]; then return 2; fi; command grep "$@"; } ;;
      esac
      if [[ "$3" == import ]]; then
        run_verified_godot "$2/run.log" --headless --path . --editor --import --quit
      else
        run_verified_godot_suite "$2/run.log" "$4" --headless --path .
      fi
      # The wrapper must not disable the caller shell error options.
      [[ "$-" == *e* && "$-" == *u* && "$(set -o | grep pipefail)" == *on ]]
      touch "$2/continued"
    ' gate-test "$repo" "$fixture" "$mode" "$entry" >"$fixture/output.log" 2>&1; then
    actual=pass
  else
    actual=block
  fi
  [[ "$actual" == "$expected" ]] || {
    cat "$fixture/output.log"
    echo "gate mismatch ($name): expected=$expected actual=$actual" >&2
    exit 1
  }
  if [[ "$expected" == block ]]; then
    [[ ! -e "$fixture/continued" ]] || { echo "failure continued ($name)" >&2; exit 1; }
  else
    [[ -e "$fixture/continued" ]] || exit 1
  fi
  checks=$((checks+1))
  printf 'gate contract: %s %s\n' "$name" "$actual"
}
entry=test/still_catch_suite.gd
complete='STILL CATCH PASS 14'
run_case suite-complete pass 0 "$complete" none suite "$entry"
# Actual command entry is appended by the wrapper, not supplied separately
# from the completion identity. Both script and scene forms are exercised.
printf '%s\n' --headless --path . --script "res://$entry" > "$fixture/expected-args"
cmp "$fixture/expected-args" "$fixture/args"
run_case scene-complete pass 0 '[locomotion-tests] PASS: 153 checks' none suite res://test/locomotion_suite.tscn
printf '%s\n' --headless --path . res://test/locomotion_suite.tscn > "$fixture/expected-args"
cmp "$fixture/expected-args" "$fixture/args"
run_case empty-zero-exit block 0 '' none suite "$entry"
run_case unrelated-pass block 0 'PASS: simulated suite' none suite "$entry"
run_case different-suite block 0 'QUIET STAY PASS 14' none suite "$entry"
run_case zero-checks block 0 'STILL CATCH PASS 0' none suite "$entry"
run_case prefixed-marker block 0 'debug: STILL CATCH PASS 14' none suite "$entry"
run_case suffixed-marker block 0 'STILL CATCH PASS 14 incomplete' none suite "$entry"
run_case truncated-marker block 0 'STILL CATCH PASS' none suite "$entry"
run_case individual-assertion-pass block 0 '[viewport] PASS first viewport' none suite test/ui_viewports.gd
run_case empty-failure-summary pass 0 '[viewport] checks=128 failures=[]' none suite test/ui_viewports.gd
run_case nonempty-failure-summary block 0 '[viewport] checks=128 failures=["missing viewport"]' none suite test/ui_viewports.gd
# These suites previously only printed an empty failures array. Require a
# positive count from their existing check() calls, not a standalone PASS.
for counted in 'test/explicit_target_suite.gd|explicit-target-tests' 'test/ui_interaction_suite.gd|ui-interaction-tests' 'test/ui_viewports.gd|viewport'; do
  counted_entry="${counted%%|*}"; counted_label="${counted#*|}"
  run_case "$counted_label-zero-checks" block 0 "[$counted_label] checks=0 failures=[]" none suite "$counted_entry"
  run_case "$counted_label-positive-checks" pass 0 "[$counted_label] checks=31 failures=[]" none suite "$counted_entry"
  run_case "$counted_label-old-counterless-summary" block 0 "[$counted_label] failures=[]" none suite "$counted_entry"
done
run_case licenses-zero-checks-with-pass block 0 $'licenses_dialog_fit_suite checks=0 failures=0\nPASS licenses_dialog_fit_suite' none suite test/licenses_dialog_fit_suite.gd
run_case licenses-nonzero-failures-with-pass block 0 $'licenses_dialog_fit_suite checks=16 failures=1\nPASS licenses_dialog_fit_suite' none suite test/licenses_dialog_fit_suite.gd
run_case licenses-positive-completion pass 0 $'licenses_dialog_fit_suite checks=16 failures=0\nPASS licenses_dialog_fit_suite' none suite test/licenses_dialog_fit_suite.gd
run_case zero-failure-count pass 0 'HOLIDAY_START_ONCE checks=34 failures=0' none suite test/holiday_start_once_suite.gd
run_case nonzero-failure-count block 0 'HOLIDAY_START_ONCE checks=34 failures=1' none suite test/holiday_start_once_suite.gd
run_case matching-completion-counts pass 0 'EXPLORATION SLICE PASS 206/206 failures=[]' none suite test/exploration_slice_suite.gd
run_case incomplete-completion-counts block 0 'EXPLORATION SLICE PASS 205/206 failures=[]' none suite test/exploration_slice_suite.gd
for status in 1 124 127 139; do
  run_case "nonzero-$status-after-completion" block "$status" "$complete" none suite "$entry"
done
run_case silent-timeout block 124 '' none suite "$entry"
run_case script-error block 0 'SCRIPT ERROR: simulated exception' none suite "$entry"
run_case engine-error block 0 'ERROR: simulated import failure' none suite "$entry"
run_case audit-fail block 0 'AUDIT FAIL simulated assertion' none suite "$entry"
run_case assertion-fail block 0 'FAIL: simulated assertion' none suite "$entry"
run_case completion-then-fail block 0 "$complete"$'\nFAIL: late assertion' none suite "$entry"
run_case fail-then-completion block 0 $'FAIL: early assertion\n'"$complete" none suite "$entry"
run_case completion-then-error block 0 "$complete"$'\nSCRIPT ERROR: late exception' none suite "$entry"
run_case tee-failure block 0 "$complete" tee suite "$entry"
run_case missing-log block 0 "$complete" missing-log suite "$entry"
run_case completion-log-read-failure block 0 "$complete" completion-read suite "$entry"
run_case unregistered-suite block 0 "$complete" none suite test/not_registered_suite.gd
[[ ! -e "$fixture/args" ]] || { echo 'unregistered suite reached Godot' >&2; exit 1; }
# #400's new summary is tested through the actual wrapper, independently of
# native engine evidence. Existing contract requires a valid complete line,
# not uniqueness: two separate valid lines remain accepted for every suite.
camera_start=$checks
camera_entry=test/camera400_handoff_suite.gd
camera_complete='[camera400-handoff] PASS: 204 checks []'
run_case camera-positive-minimum pass 0 '[camera400-handoff] PASS: 1 checks []' none suite "$camera_entry"
run_case camera-positive-count pass 0 "$camera_complete" none suite "$camera_entry"
run_case camera-zero-count block 0 '[camera400-handoff] PASS: 0 checks []' none suite "$camera_entry"
run_case camera-nonempty-failures block 0 '[camera400-handoff] PASS: 204 checks ["residual offset"]' none suite "$camera_entry"
run_case camera-missing-marker block 0 '' none suite "$camera_entry"
run_case camera-wrong-suite block 0 '[goose-mount] PASS: 204 checks []' none suite "$camera_entry"
run_case camera-prefix block 0 "debug: $camera_complete" none suite "$camera_entry"
run_case camera-suffix block 0 "$camera_complete incomplete" none suite "$camera_entry"
run_case camera-concatenated-markers block 0 "$camera_complete$camera_complete" none suite "$camera_entry"
run_case camera-two-separate-valid-lines pass 0 "$camera_complete"$'\n'"$camera_complete" none suite "$camera_entry"
run_case camera-nonzero-exit block 9 "$camera_complete" none suite "$camera_entry"
run_case camera-late-error block 0 "$camera_complete"$'\nERROR: simulated late error' none suite "$camera_entry"
run_case camera-late-fail block 0 "$camera_complete"$'\nFAIL: simulated late assertion' none suite "$camera_entry"
run_case camera-truncated-summary block 0 '[camera400-handoff] PASS: 204 checks' none suite "$camera_entry"
echo "CAMERA400 COMPLETION CONTRACT PASS $((checks-camera_start))"
# The new entry must retain the shared positive-count/empty-failures contract.
bounds_entry=test/camera400_backdrop_suite.gd
run_case bounds-complete pass 0 '[camera400-backdrop] PASS: 1 checks []' none suite "$bounds_entry"
run_case bounds-zero block 0 '[camera400-backdrop] PASS: 0 checks []' none suite "$bounds_entry"
run_case bounds-failure-list block 0 '[camera400-backdrop] PASS: 1 checks ["exposed art"]' none suite "$bounds_entry"
run_case bounds-wrong-suite block 0 '[camera400-handoff] PASS: 1 checks []' none suite "$bounds_entry"
# Both tooltip suite formats use exact positive whole-line summaries. These
# fake processes cover wrapper behavior, not actual hover or native rendering.
tooltip_start=$checks
for tooltip_suite in paper_tooltip_style paper_tooltip_interaction; do
  tooltip_entry="test/${tooltip_suite}_suite.gd"
  tooltip_complete="PASS: $tooltip_suite 37 checks"
  run_case "$tooltip_suite-positive-minimum" pass 0 "PASS: $tooltip_suite 1 checks" none suite "$tooltip_entry"
  run_case "$tooltip_suite-positive-count" pass 0 "$tooltip_complete" none suite "$tooltip_entry"
  run_case "$tooltip_suite-zero-count" block 0 "PASS: $tooltip_suite 0 checks" none suite "$tooltip_entry"
  run_case "$tooltip_suite-missing" block 0 '' none suite "$tooltip_entry"
  run_case "$tooltip_suite-wrong-suite" block 0 'PASS: title_licenses_link_contrast 37 checks' none suite "$tooltip_entry"
  run_case "$tooltip_suite-prefix" block 0 "debug: $tooltip_complete" none suite "$tooltip_entry"
  run_case "$tooltip_suite-suffix" block 0 "$tooltip_complete pending" none suite "$tooltip_entry"
  run_case "$tooltip_suite-failure-count" block 0 "$tooltip_complete failures=1" none suite "$tooltip_entry"
  run_case "$tooltip_suite-nonzero-exit" block 7 "$tooltip_complete" none suite "$tooltip_entry"
  run_case "$tooltip_suite-late-error" block 0 "$tooltip_complete"$'\nERROR: simulated late error' none suite "$tooltip_entry"
  run_case "$tooltip_suite-late-fail" block 0 "$tooltip_complete"$'\nFAIL: simulated late assertion' none suite "$tooltip_entry"
  run_case "$tooltip_suite-log-read-failure" block 0 "$tooltip_complete" completion-read suite "$tooltip_entry"
  run_case "$tooltip_suite-concatenated-markers" block 0 "$tooltip_complete$tooltip_complete" none suite "$tooltip_entry"
  # Existing shared wrapper requires at least one valid line, not uniqueness.
  run_case "$tooltip_suite-two-valid-lines" pass 0 "$tooltip_complete"$'\n'"$tooltip_complete" none suite "$tooltip_entry"
done
echo "TOOLTIP473 COMPLETION CONTRACT PASS $((checks-tooltip_start))"
# Imports legitimately have no test summary. Their independent process/log
# contract remains strict; the importer must not fabricate a suite PASS line.
run_case import-empty pass 0 '' none import ''
run_case import-with-no-suite pass 0 'Editor import finished' none import ''
run_case import-nonzero block 1 '' none import ''
run_case import-error block 0 'ERROR: import failure' none import ''
run_case import-tee-failure block 0 '' tee import ''
run_case import-missing-log block 0 '' missing-log import ''
# REQ-20261006-040: real wrapper + fake executables for both new formats.
volume466_before=$checks
for pair in 'test/volume_slider_style_suite.gd|style' 'test/volume_slider_input_suite.gd|input'; do
  volume466_entry="${pair%%|*}"
  volume466_label="${pair#*|}"
  if [[ "$volume466_label" == style ]]; then
    volume466_good='[volume-slider-style] PASS: 708 checks'
    volume466_min='[volume-slider-style] PASS: 1 checks'
    volume466_zero='[volume-slider-style] PASS: 0 checks'
    volume466_failed='[volume-slider-style] FAIL: 1 failures across 708 checks'
  else
    volume466_good='[volume-slider-input] checks=73 failures=[]'
    volume466_min='[volume-slider-input] checks=1 failures=[]'
    volume466_zero='[volume-slider-input] checks=0 failures=[]'
    volume466_failed='[volume-slider-input] checks=73 failures=["wrong gain"]'
  fi
  run_case "volume466-$volume466_label-min-positive" pass 0 "$volume466_min" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-positive" pass 0 "$volume466_good" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-zero" block 0 "$volume466_zero" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-missing" block 0 '' none suite "$volume466_entry"
  run_case "volume466-$volume466_label-failed" block 0 "$volume466_failed" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-wrong-suite" block 0 '[photo-arrival-mat] PASS: 550 checks' none suite "$volume466_entry"
  run_case "volume466-$volume466_label-prefix" block 0 "debug: $volume466_good" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-suffix" block 0 "$volume466_good incomplete" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-concatenated" block 0 "$volume466_good $volume466_good" none suite "$volume466_entry"
  # Existing helper promises at least one full valid line, not uniqueness.
  run_case "volume466-$volume466_label-two-valid-lines" pass 0 "$volume466_good"$'\n'"$volume466_good" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-nonzero-exit" block 1 "$volume466_good" none suite "$volume466_entry"
  run_case "volume466-$volume466_label-later-error" block 0 "$volume466_good"$'\nERROR: simulated late error' none suite "$volume466_entry"
  run_case "volume466-$volume466_label-later-fail" block 0 "$volume466_good"$'\nAUDIT FAIL simulated late assertion' none suite "$volume466_entry"
  run_case "volume466-$volume466_label-truncated" block 0 '[volume-slider-' none suite "$volume466_entry"
done
[[ $((checks-volume466_before)) == 28 ]]
echo 'VOLUME466 COMPLETION CONTRACT PASS 28'

echo "GODOT GATE CONTRACT PASS $checks"

# New inventory entries must not accept zero work or failed assertions.
for basket_pair in 'yard_inventory|YARD_INVENTORY' 'yard_basket_integration|YARD_BASKET_INTEGRATION'; do
  basket_entry="test/${basket_pair%%|*}_suite.gd"
  basket_marker="${basket_pair#*|}"
  run_case "$basket_marker-valid" pass 0 "$basket_marker checks=1 failures=0" none suite "$basket_entry"
  run_case "$basket_marker-zero" block 0 "$basket_marker checks=0 failures=0" none suite "$basket_entry"
  run_case "$basket_marker-failed" block 0 "$basket_marker checks=1 failures=1" none suite "$basket_entry"
done
echo "BASKET GATE CONTRACT PASS 6"

for decor_pair in 'yard_decor|YARD_DECOR' 'yard_decor_persistence|YARD_DECOR_PERSISTENCE' 'yard_decor_integration|YARD_DECOR_INTEGRATION'; do
  decor_entry="test/${decor_pair%%|*}_suite.gd"
  decor_marker="${decor_pair#*|}"
  run_case "$decor_marker-valid" pass 0 "$decor_marker checks=1 failures=0" none suite "$decor_entry"
  run_case "$decor_marker-zero" block 0 "$decor_marker checks=0 failures=0" none suite "$decor_entry"
  run_case "$decor_marker-failed" block 0 "$decor_marker checks=1 failures=1" none suite "$decor_entry"
  run_case "$decor_marker-missing" block 0 '' none suite "$decor_entry"
done
echo 'DECOR GATE CONTRACT PASS 12'

# GROK UI bundle: exact whole-line positive summaries are required for every
# new daily entry. These fake executables only exercise the runner contract.
ui_before=$checks
while IFS='|' read -r ui_name ui_good ui_zero; do
  ui_entry="test/${ui_name}_suite.gd"
  run_case "ui-$ui_name-valid" pass 0 "$ui_good" none suite "$ui_entry"
  run_case "ui-$ui_name-zero" block 0 "$ui_zero" none suite "$ui_entry"
  run_case "ui-$ui_name-missing" block 0 '' none suite "$ui_entry"
  run_case "ui-$ui_name-late-error" block 0 "$ui_good"$'\nERROR: late assertion' none suite "$ui_entry"
  run_case "ui-$ui_name-prefix" block 0 "debug: $ui_good" none suite "$ui_entry"
  run_case "ui-$ui_name-suffix" block 0 "$ui_good failures=1" none suite "$ui_entry"
done <<'UI_COMPLETIONS'
touch_hint_mode|PASS: touch_hint_mode 1 checks|PASS: touch_hint_mode 0 checks
album_caption_fit|PASS album_caption_fit_suite: 1 checks|PASS album_caption_fit_suite: 0 checks
photo_arrival_shutter_fit|[photo-arrival-shutter-fit] PASS: 1 checks|[photo-arrival-shutter-fit] PASS: 0 checks
exploration_basket_label_fit|[exploration-basket-label-fit] PASS: 1 checks|[exploration-basket-label-fit] PASS: 0 checks
yard_basket_panel_fit|[yard-basket-panel-fit] PASS: 1 checks|[yard-basket-panel-fit] PASS: 0 checks
confirm_panel_narrow|[confirm-panel-narrow] PASS: 1 checks|[confirm-panel-narrow] PASS: 0 checks
find_reveal_name_slip|PASS find_reveal_name_slip_suite: 1 checks|PASS find_reveal_name_slip_suite: 0 checks
ambience_output_ceiling|AMBIENCE_CEILING checks=1 failures=0|AMBIENCE_CEILING checks=0 failures=0
road_freedom|ROAD_FREEDOM checks=1 failures=0|ROAD_FREEDOM checks=0 failures=0
yard_decor_button_states|[yard-decor-button-states] PASS: 1 checks|[yard-decor-button-states] PASS: 0 checks
UI_COMPLETIONS
echo "GROK UI COMPLETION CONTRACT PASS $((checks-ui_before))"
