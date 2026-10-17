#!/usr/bin/env bash
# #749 溪流裁切隔离 demo：隔离 Web 完整 10×5 缩放/子像素矩阵（回应 CODEX-LEAD #749 6229185731）。仍只是候选。
# 与 ../web_export_check.sh 同一条隔离路径：导出前写入 PCK 内 build_id、探针服务器自 bind(0) 自持端口并回 server_id、
# 页面读回真实画布。不同处：页面用 ?matrix=1（不走 ?probe=1 既有路径，也不改它），每帧无损 PNG 由页面算 SHA256 后
# 同步上传给本轮服务器（服务器复算 SHA，不一致拒收），最后由 web_matrix_verdict.py 逐 PNG 离线复核并给顶层结论。
# 用法（仓库根）：GODOT=godot CHROME=google-chrome bash art/concepts/env_fx_stream_20261014/web_matrix_20261017/run_web_matrix.sh [OUT_DIR]
set -euo pipefail
GODOT="${GODOT:-godot}"
CHROME="${CHROME:-google-chrome}"
OUT="${1:-/tmp/webmatrix749}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CAND="$(dirname "$HERE")"
PROJ="$CAND/godot_preview"
rm -rf "$OUT" && mkdir -p "$OUT/site" "$OUT/uploads"
BUILD_ID="$(openssl rand -hex 16)"
printf '%s\n' "$BUILD_ID" >"$PROJ/build_id.txt"
trap 'rm -f "$PROJ/build_id.txt"' EXIT
"$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$PROJ" --export-release "Web crop demo 749" "$OUT/site/index.html" >"$OUT/export.log" 2>&1
rm -f "$PROJ/build_id.txt"
PCK_SHA="$(sha256sum "$OUT/site/index.pck" | cut -d' ' -f1)"
WASM_SHA="$(sha256sum "$OUT/site/index.wasm" | cut -d' ' -f1)"
echo "build_id=$BUILD_ID"
echo "pck_sha256=$PCK_SHA bytes=$(stat -c %s "$OUT/site/index.pck")"
echo "wasm_sha256=$WASM_SHA"

SERVER_ID="$(openssl rand -hex 16)"
PORT_FILE="$OUT/server.port"
SERVER_LOG="$OUT/server.log"
python3 "$CAND/web_probe_server.py" --directory "$OUT/site" --port-file "$PORT_FILE" --server-id "$SERVER_ID" \
  --upload-dir "$OUT/uploads" --build-id "$BUILD_ID" >"$SERVER_LOG" 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true; rm -f "$PROJ/build_id.txt"' EXIT
server_alive() { kill -0 "$SERVER" 2>/dev/null; }
PORT=""
for _ in $(seq 1 50); do
  [ -s "$PORT_FILE" ] && { PORT="$(cat "$PORT_FILE")"; break; }
  server_alive || { echo "probe server exited before binding"; cat "$SERVER_LOG"; exit 1; }
  sleep 0.1
done
[ -n "$PORT" ] || { echo "probe server did not report a port"; exit 1; }
READY=0
for _ in $(seq 1 25); do
  GOT="$(curl -s --max-time 2 "http://127.0.0.1:$PORT/__probe_server_id" || true)"
  if [ "$GOT" = "$SERVER_ID" ] && server_alive; then READY=1; break; fi
  server_alive || { echo "probe server died"; cat "$SERVER_LOG"; exit 1; }
  sleep 0.2
done
[ "$READY" = 1 ] || { echo "port $PORT is not answered by this run's server"; exit 1; }
# 服务端也核一遍：实际被服务的 index.pck 字节 = 刚导出的那份。
SERVED_SHA="$(curl -s "http://127.0.0.1:$PORT/index.pck" | sha256sum | cut -d' ' -f1)"
[ "$SERVED_SHA" = "$PCK_SHA" ] || { echo "served index.pck sha $SERVED_SHA != exported $PCK_SHA"; exit 1; }
echo "server pid=$SERVER port=$PORT (self-bound) served_pck_sha256=$SERVED_SHA"
CHROME_VERSION="$("$CHROME" --version)"
echo "chrome=$CHROME_VERSION"

PROFILE="$(mktemp -d)"
LOG="$OUT/chrome_matrix.log"
# 跑完不关浏览器；脚本轮询 WEBMATRIX 摘要行出现即收尾，超时上限 MATRIX_TIMEOUT 秒。
"$CHROME" --headless=new --no-first-run --no-default-browser-check \
  --user-data-dir="$PROFILE" --window-size=1672,1028 --force-device-scale-factor=1 \
  ${CHROME_GL_FLAGS:---use-angle=swiftshader --enable-unsafe-swiftshader} \
  --enable-logging=stderr --v=0 "http://127.0.0.1:$PORT/index.html?matrix=1" >"$LOG" 2>&1 &
CPID=$!
T0=$(date +%s)
while :; do
  grep -q 'WEBMATRIX {' "$LOG" && break
  kill -0 "$CPID" 2>/dev/null || break
  [ $(( $(date +%s) - T0 )) -ge "${MATRIX_TIMEOUT:-1800}" ] && { echo "timeout"; break; }
  sleep 2
done
sleep 1
kill "$CPID" 2>/dev/null || true; wait "$CPID" 2>/dev/null || true
rm -rf "$PROFILE"
echo "browser wall time $(( $(date +%s) - T0 )) s"
grep -o 'WEBMATRIX {.*}' "$LOG" || echo "no WEBMATRIX line (see $LOG)"
server_alive || { echo "probe server died during the browser run"; exit 1; }
cat >"$OUT/run_identity.json" <<JSON
{"build_id": "$BUILD_ID", "pck_sha256": "$PCK_SHA", "pck_bytes": $(stat -c %s "$OUT/site/index.pck"),
 "served_pck_sha256": "$SERVED_SHA", "wasm_sha256": "$WASM_SHA", "server_id": "$SERVER_ID", "port": $PORT,
 "chrome_version": "$CHROME_VERSION", "chrome_gl_flags": "${CHROME_GL_FLAGS:---use-angle=swiftshader --enable-unsafe-swiftshader}",
 "godot": "$("$GODOT" --version)", "url": "http://127.0.0.1:$PORT/index.html?matrix=1"}
JSON
python3 "$HERE/web_matrix_verdict.py" --log "$LOG" --uploads "$OUT/uploads" --identity "$OUT/run_identity.json" \
  --out "$OUT/verdict.json"
