#!/usr/bin/env bash
# #150 R2/R3 真实浏览器验收驱动（#239）。
# 默认只跑驱动自检，R2/R3 各场景报 BLOCKED（退出码 2）。
# BUILD_FIXTURE=1：把 Godot 业务夹具与 SaveWriteGate（GATE_REF，默认 PR190 f096a4a）导出成隔离 Web 项目再跑矩阵；
#   HOST_DIR 指向 CODEX-LEAD 的 R1 Host 桥接/Probe 目录（其 head.html 注入页面，其余文件复制进站点根），HOST_SHA 为其完整 SHA。
#   未提供 HOST_DIR 时夹具只报 host bridge missing，场景保持 BLOCKED。
# CANDIDATE_DIR + CANDIDATE_SHA：直接对已导出的候选站点跑矩阵。
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PYTHON=${PYTHON:-python3}
OUT=${OUT:-$(mktemp -d /tmp/youjia-recovery-web.XXXXXX)}
args=(--out "$OUT")

if [[ "${BUILD_FIXTURE:-0}" == 1 ]]; then
	: "${GODOT:?BUILD_FIXTURE 需要 GODOT 指向已验证引擎}"
	: "${GODOT_WEB_TEMPLATE:?BUILD_FIXTURE 需要匹配的 nothreads release Web 模板}"
	GATE_REF=${GATE_REF:-f096a4a927c164c4bf70acc403a826a2074d2362}
	PROJ="$OUT/project"
	mkdir -p "$PROJ/web"
	git -C "$ROOT" show "$GATE_REF:scripts/persistence/save_write_gate.gd" > "$PROJ/gate.gd"
	cp "$ROOT/test/save_recovery_web/fixture/main.gd" "$PROJ/main.gd"
	printf '%s\n' "$GATE_REF" > "$PROJ/GATE_SOURCE.txt"
	"$PYTHON" - "$ROOT" "$PROJ" "$GODOT_WEB_TEMPLATE" "${HOST_DIR:-}" <<'PY'
import json, pathlib, sys
root, proj, template = map(pathlib.Path, sys.argv[1:4])
host = pathlib.Path(sys.argv[4]) if sys.argv[4] else None
(proj / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Isolated recovery fixture"\nrun/main_scene="res://main.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
(proj / 'main.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://main.gd" id="1"]\n[node name="Fixture" type="Node"]\nscript=ExtResource("1")\n')
head = '<script>' + (root / 'test/save_recovery_web/fixture/facade.js').read_text() + '</script>'
if host and (host / 'head.html').exists():
    head += (host / 'head.html').read_text()
(proj / 'export_presets.cfg').write_text('[preset.0]\nname="Web"\nplatform="Web"\nrunnable=true\nexport_filter="all_resources"\ninclude_filter=""\nexclude_filter="web/*,GATE_SOURCE.txt"\n[preset.0.options]\nvariant/thread_support=false\ncustom_template/release=' + json.dumps(str(template.resolve())) + '\nhtml/head_include=' + json.dumps(head) + '\n')
PY
	source "$ROOT/tools/lib/verified_godot.sh"
	run_verified_godot "$OUT/import.log" --headless --path "$PROJ" --editor --import
	run_verified_godot "$OUT/export.log" --headless --path "$PROJ" --export-release Web "$PROJ/web/index.html"
	if [[ -n "${HOST_DIR:-}" ]]; then
		: "${HOST_SHA:?HOST_DIR 需要配套完整 HOST_SHA}"
		find "$HOST_DIR" -mindepth 1 -maxdepth 1 ! -name head.html -exec cp -r {} "$PROJ/web/" \;
	fi
	CANDIDATE_DIR="$PROJ/web"
	CANDIDATE_SHA="fixture=$(git -C "$ROOT" rev-parse HEAD) gate=$GATE_REF host=${HOST_SHA:-none}"
fi

if [[ -n "${CANDIDATE_DIR:-}" ]]; then
	: "${CANDIDATE_SHA:?CANDIDATE_DIR 需要配套完整 CANDIDATE_SHA}"
	args+=(--candidate "$CANDIDATE_DIR" --candidate-sha "$CANDIDATE_SHA")
fi
"$PYTHON" "$ROOT/test/save_recovery_web/driver.py" "${args[@]}"
