#!/usr/bin/env bash
set -euo pipefail
cd /dev/shm/youjia-title436
source tools/lib/verified_godot.sh
export GODOT=/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64
suite_id=0
run_case() {
 suite_id=$((suite_id+1))
 export XDG_DATA_HOME="/dev/shm/title436-state-final/$suite_id/data" XDG_CONFIG_HOME="/dev/shm/title436-state/$suite_id/config" XDG_CACHE_HOME="/dev/shm/title436-state/$suite_id/cache"
 export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
 mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
 run_verified_godot /tmp/title436-integration/current.log "$@"
}
run_case --headless --path . --editor --import --quit
for suite in title_licenses_link_contrast title_card title_short_landscape licenses_dialog_fit ui_interaction album_short_landscape holiday_start_once exploration_cleanup_preservation; do
 run_case --headless --path . --script "test/${suite}_suite.gd"
done
node test/loading_shell_test.cjs
