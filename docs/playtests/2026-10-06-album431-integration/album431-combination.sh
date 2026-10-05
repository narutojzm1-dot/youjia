#!/usr/bin/env bash
set -euo pipefail
cd /dev/shm/youjia-album431
export GODOT=/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64
source tools/lib/verified_godot.sh
state=$(mktemp -d /dev/shm/album431-state.XXXXXX)
trap 'rm -rf "$state"' EXIT
for suite in album_short_landscape album_layout photo_moment_save photo_home interaction_photo photo_arrival_fit photo_arrival_combo holiday_start_once save_feedback; do
 export XDG_DATA_HOME="$state/$suite/data" XDG_CONFIG_HOME="$state/$suite/config" XDG_CACHE_HOME="$state/$suite/cache" YOUJIA_TEST_ISOLATED_DATA="$state/$suite/data"
 mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
 run_verified_godot "$state/$suite.log" --headless --path . --script "test/${suite}_suite.gd"
done
node test/loading_shell_test.cjs
