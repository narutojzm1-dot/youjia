#!/usr/bin/env bash
set -euo pipefail
cd /d/games/youjia-test/source
export GODOT=/d/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe
source tools/lib/verified_godot.sh
run_verified_godot_suite /d/games/youjia-test/qa/native/2026-10-10-2322/yard_basket_drop_place.log test/yard_basket_drop_place_suite.gd --headless --path .
