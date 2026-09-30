#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
# Isolate saves/settings from the player's album and work in restricted CI too.
STATE="$(mktemp -d)"
trap 'rm -rf "$STATE"' EXIT
export XDG_DATA_HOME="$STATE/data" XDG_CACHE_HOME="$STATE/cache" XDG_CONFIG_HOME="$STATE/config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
run_check() {
  local log="$STATE/check.log"
  "$GODOT_BIN" "$@" 2>&1 | tee "$log"
  # Godot can emit a GDScript runtime error and still exit 0 if a test node
  # later calls quit(0). Such a run is never a pass.
  if grep -Eq '^(SCRIPT ERROR:|SHADER ERROR:|ERROR:)' "$log"; then
    echo "Godot reported an engine/script error; refusing a false-green result." >&2
    return 1
  fi
}
run_check --headless --path "$ROOT" --editor --import --quit
run_check --headless --path "$ROOT" res://test/test_suite.tscn
run_check --headless --path "$ROOT" res://test/locomotion_suite.tscn
node "$ROOT/test/loading_shell_test.cjs"

run_check --headless --path "$ROOT" --script res://test/ui_interaction_suite.gd

run_check --headless --path "$ROOT" --script res://test/ui_viewports.gd
