#!/usr/bin/env bash
set -euo pipefail
cd /tmp/youjia-photo447
export GODOT=/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64
export XDG_DATA_HOME=/dev/shm/photo447-state/data XDG_CONFIG_HOME=/dev/shm/photo447-state/config XDG_CACHE_HOME=/dev/shm/photo447-state/cache
export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
source tools/lib/verified_godot.sh
"$GODOT" --version > /dev/shm/photo447-evidence/godot-version.txt
run_verified_godot /dev/shm/photo447-evidence/import.log --headless --path . --editor --import --quit
run_verified_godot /dev/shm/photo447-evidence/specialized.log --headless --path . --script test/photo_arrival_mat_suite.gd
bash tools/verify_daily_life.sh > /dev/shm/photo447-evidence/daily.log 2>&1
python3 test/web_bundle_retention_test.py > /dev/shm/photo447-evidence/web-retention.log 2>&1
python3 test/publish_storage_modules_test.py > /dev/shm/photo447-evidence/storage-publish.log 2>&1
XDG_DATA_HOME=/tmp/262-export-state/data "$GODOT" --headless --path . --export-release Web /dev/shm/photo447-preview/index.html > /dev/shm/photo447-evidence/export.log 2>&1
for output in index.html index.js index.wasm index.pck; do test -s "/dev/shm/photo447-preview/$output"; done
