#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${OUT:?set OUT to disposable build folder}
GODOT=${GODOT:?set GODOT}
mkdir -p "$OUT/web"
cp "$ROOT/test/save_lifecycle_web/main.gd" "$OUT/main.gd"
cp "$ROOT/test/save_recovery_r1/source_snapshot.gd" "$OUT/source_snapshot.gd"
cat > "$OUT/project.godot" <<'CFG'
config_version=5
[application]
config/name="Lifecycle verification"
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
cp "$ROOT"/test/save_recovery_r1/*.mjs "$OUT/web/"
python3 - "$ROOT" "$OUT" <<'PY'
from pathlib import Path
import sys
root,out=map(Path,sys.argv[1:]);f=out/'web/index.html';s=f.read_text()
head="<script>window.YoujiaSaveRuntimeReady=new Promise((resolve,reject)=>{window.resolveSaveRuntime=resolve;window.rejectSaveRuntime=reject;});</script>\n"+(root/'test/save_recovery_r1/head.html').read_text()
s=s.replace('</head>',head+'\n</head>')
needle='}).then(() => {\n\t\t\tsetStatusMode'
assert needle in s
s=s.replace(needle,'}).then(() => {\n            window.runtimeComplete=true;window.resolveSaveRuntime();\n\t\t\tsetStatusMode')
assert '}, displayFailureNotice);' in s
s=s.replace('}, displayFailureNotice);','}, error=>{window.rejectSaveRuntime(error);displayFailureNotice(error);});')
f.write_text(s)
PY
