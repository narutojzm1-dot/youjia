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
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="$HERE/godot_preview"
rm -rf "$OUT" && mkdir -p "$OUT"
# 导出身份：每次导出前写进工程（.gitignore 已忽略），随本次 PCK 打包；探针从包内读回，不从页面地址反射。
BUILD_ID="$(openssl rand -hex 16)"
printf '%s\n' "$BUILD_ID" >"$PROJ/build_id.txt"
trap 'rm -f "$PROJ/build_id.txt"' EXIT
"$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$PROJ" --export-release "Web crop demo 749" "$OUT/index.html"
rm -f "$PROJ/build_id.txt"
ls -l "$OUT"/index.pck "$OUT"/index.wasm
echo "build_id=$BUILD_ID"

# 服务器自己 bind(0) 并持有该 socket，把实际端口写进 PORT_FILE；不先探端口再移交，不杀别人的监听。
SERVER_ID="$(openssl rand -hex 16)"
PORT_FILE="$OUT/server.port"
SERVER_LOG="$OUT/server.log"
python3 "$HERE/web_probe_server.py" --directory "$OUT" --port-file "$PORT_FILE" --server-id "$SERVER_ID" >"$SERVER_LOG" 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true; rm -f "$PROJ/build_id.txt"' EXIT
server_alive() { kill -0 "$SERVER" 2>/dev/null; }
PORT=""
for _ in $(seq 1 50); do
  [ -s "$PORT_FILE" ] && { PORT="$(cat "$PORT_FILE")"; break; }
  server_alive || { echo "probe server exited before binding (see $SERVER_LOG)"; cat "$SERVER_LOG"; exit 1; }
  sleep 0.1
done
[ -n "$PORT" ] || { echo "probe server did not report a port (see $SERVER_LOG)"; exit 1; }
# 健康检查：必须是本轮服务器（回 SERVER_ID）且子进程仍活着，才算就绪。
READY=0
for _ in $(seq 1 25); do
  GOT="$(curl -s --max-time 2 "http://127.0.0.1:$PORT/__probe_server_id" || true)"
  if [ "$GOT" = "$SERVER_ID" ] && server_alive; then READY=1; break; fi
  server_alive || { echo "probe server died (see $SERVER_LOG)"; cat "$SERVER_LOG"; exit 1; }
  sleep 0.2
done
[ "$READY" = 1 ] || { echo "port $PORT is not answered by this run's server (see $SERVER_LOG)"; exit 1; }
echo "server pid=$SERVER port=$PORT (self-bound)"

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
# 身份：探针回报的是本次 PCK 里打包的 build_id，必须等于本轮导出前写入的值；旧导出没有它或值不同。
case "$LINE" in *"\"build_id\":\"$BUILD_ID\""*) ;; *) echo "build_id mismatch or missing (expected $BUILD_ID): page did not load this run's export"; exit 1 ;; esac
server_alive || { echo "probe server died during the browser run (see $SERVER_LOG)"; exit 1; }
case "$LINE" in *'"ok":true'*) exit 0 ;; *) exit 1 ;; esac
