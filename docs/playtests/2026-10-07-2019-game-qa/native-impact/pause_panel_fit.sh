#!/usr/bin/env bash
set -euo pipefail
cd /d/games/youjia-test/source
export GODOT=/d/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe
source tools/lib/verified_godot.sh
_run_verified_godot /d/games/youjia-test/qa/native/2026-10-07-2019-impact/pause_panel_fit.log "PASS: pause_panel_fit [0-9]+ checks" --headless --path . --script res://test/pause_panel_fit_suite.gd
