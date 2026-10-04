#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
: "${GODOT:?set GODOT to verified engine}"
: "${GODOT_WEB_TEMPLATE:?set GODOT_WEB_TEMPLATE to matching nonthreaded release template}"
PYTHON=${PYTHON:-python3}
OUT=$(mktemp -d /tmp/youjia-save-gate-web.XXXXXX)
cp "$ROOT/test/save_gate_web/main.gd" "$OUT/main.gd"
cp "$ROOT/scripts/persistence/save_write_gate.gd" "$OUT/gate.gd"
mkdir "$OUT/web"
"$PYTHON" - "$ROOT" "$OUT" "$GODOT_WEB_TEMPLATE" <<'PY'
import pathlib,sys,json
root,out,template=map(pathlib.Path,sys.argv[1:])
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Isolated Gate test"\nrun/main_scene="res://main.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
(out/'main.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://main.gd" id="1"]\n[node name="Test" type="Node"]\nscript=ExtResource("1")\n')
head='<script>'+(root/'test/save_gate_web/bridge.js').read_text()+'</script>'
(out/'export_presets.cfg').write_text('[preset.0]\nname="Web"\nplatform="Web"\nrunnable=true\nexport_filter="all_resources"\ninclude_filter=""\nexclude_filter="web/*,result.json"\n[preset.0.options]\nvariant/thread_support=false\ncustom_template/release='+json.dumps(str(template.resolve()))+'\nhtml/head_include='+json.dumps(head)+'\n')
PY
source "$ROOT/tools/lib/verified_godot.sh"
run_verified_godot "$OUT/import.log" --headless --path "$OUT" --editor --import
run_verified_godot "$OUT/export.log" --headless --path "$OUT" --export-release Web "$OUT/web/index.html"
"$PYTHON" "$ROOT/test/save_gate_web/run.py" "$OUT"
echo "Evidence: $OUT"
