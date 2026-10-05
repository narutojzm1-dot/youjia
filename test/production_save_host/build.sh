#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${OUT:?set disposable build path}
GODOT=${GODOT:?set matching Godot binary}
CAPTURE_MODULE=${CAPTURE_MODULE:?set reviewed IDBFS reader path}
mkdir -p "$OUT/web/web/save"
cp "$ROOT/test/production_save_host/main.gd" "$OUT/main.gd"
cat > "$OUT/project.godot" <<'CFG'
config_version=5
[application]
config/name="Production Host verification"
run/main_scene="res://main.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
CFG
cat > "$OUT/main.tscn" <<'CFG'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://main.gd" id="1"]
[node name="Main" type="Node"]
script = ExtResource("1")
CFG
cat > "$OUT/export_presets.cfg" <<'CFG'
[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="web/index.html"
[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
html/canvas_resize_policy=2
CFG
"$GODOT" --headless --path "$OUT" --editor --import --quit > "$OUT/import.log" 2>&1
"$GODOT" --headless --path "$OUT" --export-release Web > "$OUT/export.log" 2>&1
if rg 'SCRIPT ERROR|ERROR:' "$OUT/import.log" "$OUT/export.log"; then exit 1; fi
cp "$ROOT"/web/save/*.mjs "$OUT/web/web/save/"
python3 - "$OUT" "$CAPTURE_MODULE" <<'PY'
from pathlib import Path
import sys
out=Path(sys.argv[1]);reader=Path(sys.argv[2]).read_text()
needle="import {FIXTURE_BUDGET, checkBudget} from './budgets.mjs';"
assert needle in reader
(out/'web/reader.mjs').write_text(reader.replace(needle,"import {PRODUCTION_BUDGET as FIXTURE_BUDGET, checkBudget} from './web/save/budgets.mjs';"))
f=out/'web/index.html';s=f.read_text()
head='''<script>
window.YoujiaSaveRuntimeReady=new Promise((resolve,reject)=>{window.resolveSaveRuntime=resolve;window.rejectSaveRuntime=reject;});window.YoujiaSaveRuntimeReady.catch(()=>{});
window.saveBridgeReady=Promise.all([import('./web/save/bridge.mjs'),import('./reader.mjs')]).then(([m,r])=>m.installSaveHost({runtimeReady:window.YoujiaSaveRuntimeReady,captureLegacy:r.captureIdbfsSource}));
</script>'''
s=s.replace('</head>',head+'\n</head>')
s=s.replace('engine.startGame({',"window.saveBridgeReady.then(()=>engine.startGame({persistentPaths:new URLSearchParams(location.search).has('seed')?['/userfs']:[],")
needle='}).then(() => {\n\t\t\tsetStatusMode';assert needle in s
s=s.replace(needle,'})).then(() => {\n window.runtimeComplete=true;window.resolveSaveRuntime();\n\t\t\tsetStatusMode')
assert '}, displayFailureNotice);' in s
s=s.replace('}, displayFailureNotice);','}, error=>{window.rejectSaveRuntime(error);displayFailureNotice(error);});')
f.write_text(s)
PY
