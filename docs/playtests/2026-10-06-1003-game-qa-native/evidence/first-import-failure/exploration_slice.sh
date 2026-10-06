#!/usr/bin/env bash
set -euo pipefail
cd /d/games/youjia-test/source
export GODOT=/d/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe
source tools/lib/verified_godot.sh
run_verified_godot_suite /d/games/youjia-test/qa/native/2026-10-06-1005/exploration_slice.log test/exploration_slice_suite.gd --headless --path .
