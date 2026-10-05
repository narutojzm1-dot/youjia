#!/usr/bin/env bash
set -euo pipefail
cd /tmp/youjia-soft444
export GODOT=/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64
export XDG_DATA_HOME=/tmp/soft444-state/data XDG_CONFIG_HOME=/tmp/soft444-state/config XDG_CACHE_HOME=/tmp/soft444-state/cache
export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
source tools/lib/verified_godot.sh
GODOT="$GODOT" bash tools/verify_daily_life.sh > /tmp/soft444-evidence/daily.log 2>&1
printf 'daily complete\n'
python3 test/web_bundle_retention_test.py > /tmp/soft444-evidence/web-retention.log 2>&1
python3 test/publish_storage_modules_test.py > /tmp/soft444-evidence/storage-publish.log 2>&1
mkdir -p /tmp/soft444-web
XDG_DATA_HOME=/tmp/262-export-state/data run_verified_godot /tmp/soft444-evidence/export.log --headless --path . --export-release Web /tmp/soft444-web/index.html > /tmp/soft444-evidence/export-console.log 2>&1
printf 'export complete\n'
