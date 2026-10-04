#!/usr/bin/env bash
# #150 R2/R3 真实浏览器验收驱动（#239）。
# 不传 CANDIDATE_DIR 时只跑驱动自检，R2/R3 各场景报 BLOCKED（退出码 2）。
# CANDIDATE_DIR 指向 R1 候选的隔离测试 Web 导出（含 YoujiaRecoveryProbe/Fixture），CANDIDATE_SHA 为其完整 SHA。
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PYTHON=${PYTHON:-python3}
OUT=${OUT:-$(mktemp -d /tmp/youjia-recovery-web.XXXXXX)}
args=(--out "$OUT")
if [[ -n "${CANDIDATE_DIR:-}" ]]; then
	: "${CANDIDATE_SHA:?CANDIDATE_DIR 需要配套完整 CANDIDATE_SHA}"
	args+=(--candidate "$CANDIDATE_DIR" --candidate-sha "$CANDIDATE_SHA")
fi
"$PYTHON" "$ROOT/test/save_recovery_web/driver.py" "${args[@]}"
