#!/usr/bin/env bash
# #749 溪流裁切隔离 demo：Web 导出 + 浏览器内逐像素/暂停/减少动态实测。仍只是候选，不导出主游戏。
# 需要：Godot 4.7.2 编辑器，官方同版 web_nothreads_release.zip 已装到
#   ~/.local/share/godot/export_templates/4.7.2.stable/（取自 Godot_v4.7.2-stable_export_templates.tpz）
# 用法（仓库根）：GODOT=godot CHROME=google-chrome bash art/concepts/env_fx_stream_20261014/web_export_check.sh [OUT_DIR]
# 结果在控制台一行 WEBPROBE {...}；ok=true 才算这一项通过。帧时只代表当前浏览器/渲染后端。
set -euo pipefail
GODOT="${GODOT:-godot}"
CHROME="${CHROME:-google-chrome}"
OUT="${1:-/tmp/web749}"
PORT="${PORT:-8749}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="$HERE/godot_preview"
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$PROJ" --export-release "Web crop demo 749" "$OUT/index.html"
ls -l "$OUT"/index.pck "$OUT"/index.wasm
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$OUT" >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true' EXIT
sleep 1
PROFILE="$(mktemp -d)"
# headless=new 的 --window-size 含约 87 px 浏览器边框；1028 高才得到 1672×941 画布（probe 会核对，尺寸不对即 ok=false）。
LOG="$OUT/chrome_probe.log"
# 探针跑完不关浏览器，靠 timeout 收尾，所以不看 timeout 的退出码，只看日志里的 WEBPROBE 行。
timeout "${PROBE_TIMEOUT:-100}" "$CHROME" --headless=new --no-first-run --no-default-browser-check \
  --user-data-dir="$PROFILE" --window-size=1672,1028 --force-device-scale-factor=1 \
  ${CHROME_GL_FLAGS:---use-angle=swiftshader --enable-unsafe-swiftshader} \
  --enable-logging=stderr --v=0 "http://127.0.0.1:$PORT/index.html?probe=1" >"$LOG" 2>&1 || true
LINE="$(grep -o 'WEBPROBE {.*}' "$LOG" || true)"
[ -n "$LINE" ] || { echo "no WEBPROBE line (see $LOG)"; exit 1; }
echo "$LINE"
case "$LINE" in *'"ok":true'*) exit 0 ;; *) exit 1 ;; esac
