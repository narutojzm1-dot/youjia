#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
: "${OUT:?isolated output required}" "${GODOT:?Godot 4.7.2 binary required}" "${HOST_SOURCE:?production web/save directory required}"
mkdir -p "$OUT/project/scripts/persistence" "$OUT/web/save"
cp "$root/scripts/persistence/web_save_host.gd" "$root/scripts/persistence/web_save_reply.gd" "$root/scripts/persistence/web_save_legacy_reply.gd" "$OUT/project/scripts/persistence/"
cp "$root/test/web_save_bridge/main.gd" "$OUT/project/main.gd"
cp "$HOST_SOURCE/"*.mjs "$OUT/web/save/"
cat > "$OUT/project/project.godot" <<'PROJECT'
config_version=5
[application]
config/name="悠长的假期"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
[rendering]
renderer/rendering_method="gl_compatibility"
PROJECT
cat > "$OUT/project/main.tscn" <<'SCENE'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://main.gd" id="1"]
[node name="GodotHostBridgeFixture" type="Node"]
script=ExtResource("1")
SCENE
cat > "$OUT/project/export_presets.cfg" <<'PRESET'
[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
[preset.0.options]
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=false
PRESET
"$GODOT" --headless --path "$OUT/project" --editor --import --quit
"$GODOT" --headless --path "$OUT/project" --export-release Web "$OUT/web/index.html"
python - "$OUT/web/index.html" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]);s=p.read_text();needle='const engine = new Engine(GODOT_CONFIG);';assert needle in s
s=s.replace(needle,"GODOT_CONFIG.persistentPaths=[];\n"+needle)
s=s.replace('<head>','<head><link rel="icon" href="data:,">')
s=s.replace('<script>', '<script type="module">',1)
s=s.replace('const GODOT_CONFIG =', '''import {installSaveHost} from './save/bridge.mjs';
let resolveRuntime,rejectRuntime;
const ready=new Promise((resolve,reject)=>{resolveRuntime=resolve;rejectRuntime=reject});ready.catch(()=>{});
const legacy=new URLSearchParams(location.search).has('legacy');
installSaveHost({runtimeReady:ready,captureLegacy:async()=>window.fixtureReadError?{primary:{status:'read_error',reason:'fixture_unavailable'},backup:{status:'absent'}}:legacy?{primary:{status:'present',base64:btoa('{"version":5,"old":true}')},backup:{status:'absent'}}:{primary:{status:'absent'},backup:{status:'absent'}}});
const GODOT_CONFIG =''')
# Actual engine startup resolution, not an already-resolved fake runtime.
s=s.replace("engine.startGame({", "engine.startGame({")
s=s.replace("}).then(() => {", "}).then(() => { resolveRuntime();",1)
s=s.replace("}).catch(displayFailureNotice);", "}).catch(error=>{rejectRuntime(error);displayFailureNotice(error)});")
s=s.replace("}, displayFailureNotice);", "}, error=>{rejectRuntime(error);displayFailureNotice(error)});")
p.write_text(s)
PY
