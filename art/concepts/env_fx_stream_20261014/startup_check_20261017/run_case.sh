#!/usr/bin/env bash
# Agent-ID: GROK-BUILD — #749 启动帧核对：把 godot_preview 复制到 /tmp 临时副本，只加 override.cfg + delta_log.gd，
# 用与 README 相同的 Movie Maker 参数录前 N 帧。仓库内 godot_preview/ 不改。
# 用法：run_case.sh <name> <frames> [override 段落行...]；EXTRA_ARGS 追加到 -- 之后（如 --toggle-sequence）
# 安全：NAME 必须是合法非空直接子目录名；N 为正整数；删除前确认 WORK 解析后仍在固定根下；拒绝符号链接与未知目录。
set -euo pipefail

ROOT=/tmp/startup749

die() { echo "run_case.sh: $*" >&2; exit 1; }

[[ $# -ge 2 ]] || die "usage: run_case.sh <name> <frames> [override lines...]"

NAME=$1
N=$2
shift 2

# Case name: non-empty, no path separators, no leading '.', only [A-Za-z0-9_-]
[[ -n "$NAME" ]] || die "empty case name"
[[ "$NAME" != .* ]] || die "case name must not start with '.'"
[[ "$NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid case name (only A-Za-z0-9_- allowed): $NAME"

# Frame count: positive integer
[[ "$N" =~ ^[1-9][0-9]*$ ]] || die "frames must be a positive integer: $N"

HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/../godot_preview"
[[ -d "$SRC" ]] || die "missing godot_preview at $SRC"

mkdir -p "$ROOT"
# Resolve fixed root (must exist as a real directory, not a symlink)
ROOT_REAL=$(cd "$ROOT" && pwd -P)
[[ -d "$ROOT_REAL" ]] || die "fixed root missing: $ROOT_REAL"
[[ ! -L "$ROOT" ]] || die "fixed root must not be a symlink: $ROOT"

WORK_CAND="$ROOT_REAL/$NAME"

# If WORK already exists: must be a real directory owned by us, under ROOT_REAL, not a symlink
if [[ -e "$WORK_CAND" || -L "$WORK_CAND" ]]; then
  [[ ! -L "$WORK_CAND" ]] || die "refuse symlink work dir: $WORK_CAND"
  [[ -d "$WORK_CAND" ]] || die "work path exists and is not a directory: $WORK_CAND"
  WORK_REAL=$(cd "$WORK_CAND" && pwd -P)
  case "$WORK_REAL" in
    "$ROOT_REAL"|"$ROOT_REAL"/*) ;;
    *) die "resolved work path escapes fixed root: $WORK_REAL (root=$ROOT_REAL)" ;;
  esac
  # Must be a direct child of ROOT_REAL (no nested escape via .. resolution)
  parent=$(dirname "$WORK_REAL")
  [[ "$parent" == "$ROOT_REAL" ]] || die "work dir is not a direct child of fixed root: $WORK_REAL"
  # Refuse deleting unknown/non-owned dirs
  owner=$(stat -c '%u' "$WORK_REAL")
  me=$(id -u)
  [[ "$owner" == "$me" ]] || die "refuse deleting non-owned directory (uid=$owner, me=$me): $WORK_REAL"
  rm -rf -- "$WORK_REAL"
fi

mkdir -p "$WORK_CAND/frames"
WORK=$(cd "$WORK_CAND" && pwd -P)
case "$WORK" in
  "$ROOT_REAL"|"$ROOT_REAL"/*) ;;
  *) die "new work path escapes fixed root: $WORK" ;;
esac
parent=$(dirname "$WORK")
[[ "$parent" == "$ROOT_REAL" ]] || die "new work dir is not a direct child of fixed root: $WORK"

cp -r "$SRC" "$WORK/proj"
cp "$HERE/delta_log.gd" "$WORK/proj/delta_log.gd"
{
  echo '[autoload]'
  echo 'DeltaLog="*res://delta_log.gd"'
  for line in "$@"; do echo "$line"; done
} > "$WORK/proj/override.cfg"

GODOT=${GODOT:-/home/box/bin/godot}
xvfb-run -a -s "-screen 0 1800x1000x24" "$GODOT" --path "$WORK/proj" \
  --resolution 1672x941 --write-movie "$WORK/frames/f.png" --fixed-fps 30 --quit-after "$N" -- --hide-ui ${EXTRA_ARGS:-} \
  > "$WORK/log.txt" 2>&1
echo "done $NAME -> $WORK"
