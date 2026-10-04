#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib/verified_godot.sh
sandbox="$(mktemp -d /tmp/youjia-write-gate.XXXXXX)"
# Retain this isolated fixture and log for diagnosis; never load game autoloads.
mkdir -p "$sandbox/scripts/persistence" "$sandbox/test"
printf 'config_version=5\n[application]\nconfig/name="SaveWriteGateTest"\n' > "$sandbox/project.godot"
cp scripts/persistence/save_write_gate.gd "$sandbox/scripts/persistence/"
cp test/save_write_gate_suite.gd "$sandbox/test/"
run_verified_godot "$sandbox/result.log" --headless --path "$sandbox" --script test/save_write_gate_suite.gd
grep -qx 'SAVE WRITE GATE PASS 199' "$sandbox/result.log"
printf 'Isolated evidence: %s\n' "$sandbox"
