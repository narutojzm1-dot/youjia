#!/usr/bin/env bash
set -euo pipefail
cd /d/games/youjia-test/source
export GODOT=/d/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe
source tools/lib/verified_godot.sh
run_verified_godot /d/games/youjia-test/qa/native/2026-10-08-1915/import.log --headless --path . --editor --import --quit
