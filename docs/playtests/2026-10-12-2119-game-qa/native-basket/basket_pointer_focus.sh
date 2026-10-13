#!/usr/bin/env bash
set -euo pipefail
cd /d/games/youjia-test/qa-checkout-c874
export GODOT=/d/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe
source tools/lib/verified_godot.sh
run_verified_godot_suite /d/games/youjia-test/qa/native/2026-10-12-2119-basket/basket_pointer_focus.log test/basket_pointer_focus_suite.gd --headless --path .
