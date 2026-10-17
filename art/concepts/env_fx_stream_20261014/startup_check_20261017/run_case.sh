#!/usr/bin/env bash
# Agent-ID: GROK-BUILD — #749 启动帧核对：把 godot_preview 复制到 /tmp 临时副本，只加 override.cfg + delta_log.gd，
# 用与 README 相同的 Movie Maker 参数录前 N 帧。仓库内 godot_preview/ 不改。
# 用法：run_case.sh <name> <frames> [override 段落行...]；EXTRA_ARGS 追加到 -- 之后（如 --toggle-sequence）
#
# 安全（回应 CODEX-LEAD review on a6361372）：
# - NAME 合法非空直接子目录名；N 正整数；SRC / xvfb-run / Godot 在任何删除前预检。
# - 本脚本新建的工作目录写专属标记 .run_case_owner（魔数 + case 名 + uid + 目录 dev:inode + 随机 token）。
# - 已存在目录只有在标记为普通文件、非符号链接、属当前 uid、魔数/名称/uid/dev:inode 全部与该目录现状一致时才清理；
#   没有标记或标记不符的同 UID 未知目录一律拒绝，不删除。
# - 每种拒绝有固定退出码，并在 stderr 打印 "REJECT <code> <reason>"，供 verify_run_case_safety.sh 逐项核对。
#   20 用法  21 case 名  22 帧数  23 缺 godot_preview  24 缺 xvfb-run  25 缺/不可执行 Godot
#   26 固定根异常  27 工作路径是符号链接  28 工作路径不是目录  29 越出固定根/非直接子目录
#   30 非当前 uid  31 无专属标记  32 标记不是普通文件或是符号链接  33 标记内容与目录不符
set -euo pipefail

ROOT=/tmp/startup749
MARKER_NAME=.run_case_owner
MAGIC='startup749-run_case-workdir v1'

reject() { local code=$1; shift; echo "REJECT $code $*" >&2; echo "run_case.sh: $*" >&2; exit "$code"; }

[[ $# -ge 2 ]] || reject 20 "usage: run_case.sh <name> <frames> [override lines...]"

NAME=$1
N=$2
shift 2

[[ -n "$NAME" ]] || reject 21 "empty case name"
[[ "$NAME" != .* ]] || reject 21 "case name must not start with '.': $NAME"
[[ "$NAME" =~ ^[A-Za-z0-9_-]+$ ]] || reject 21 "invalid case name (only A-Za-z0-9_- allowed): $NAME"
[[ "$N" =~ ^[1-9][0-9]*$ ]] || reject 22 "frames must be a positive integer: $N"

HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/../godot_preview"
[[ -d "$SRC" && -f "$SRC/project.godot" ]] || reject 23 "missing godot_preview at $SRC"

XVFB=${XVFB_RUN:-xvfb-run}
command -v "$XVFB" >/dev/null 2>&1 || reject 24 "xvfb-run not found: $XVFB"
GODOT=${GODOT:-/home/box/bin/godot}
[[ -f "$GODOT" && -x "$GODOT" ]] || reject 25 "godot missing or not executable: $GODOT"

[[ ! -L "$ROOT" ]] || reject 26 "fixed root must not be a symlink: $ROOT"
mkdir -p "$ROOT"
[[ -d "$ROOT" && ! -L "$ROOT" ]] || reject 26 "fixed root is not a real directory: $ROOT"
ROOT_REAL=$(cd "$ROOT" && pwd -P)
[[ "$(stat -c '%u' "$ROOT_REAL")" == "$(id -u)" ]] || reject 26 "fixed root not owned by current uid: $ROOT_REAL"

ME=$(id -u)
WORK_CAND="$ROOT_REAL/$NAME"

dev_ino() { stat -c '%d:%i' "$1"; }

check_owned_workdir() {  # $1 = resolved dir; returns via reject on any mismatch
  local d=$1 m="$1/$MARKER_NAME"
  if [[ ! -e "$m" && ! -L "$m" ]]; then reject 31 "unknown directory (no $MARKER_NAME), refuse delete: $d"; fi
  [[ ! -L "$m" && -f "$m" ]] || reject 32 "marker is not a regular file: $m"
  [[ "$(stat -c '%u' "$m")" == "$ME" ]] || reject 32 "marker not owned by current uid: $m"
  local magic name uid di
  magic=$(sed -n '1p' "$m")
  name=$(sed -n 's/^name=//p' "$m")
  uid=$(sed -n 's/^uid=//p' "$m")
  di=$(sed -n 's/^dev_ino=//p' "$m")
  [[ "$magic" == "$MAGIC" ]] || reject 33 "marker magic mismatch: $m"
  [[ "$name" == "$NAME" ]] || reject 33 "marker name mismatch ($name != $NAME): $m"
  [[ "$uid" == "$ME" ]] || reject 33 "marker uid mismatch ($uid != $ME): $m"
  [[ "$di" == "$(dev_ino "$d")" ]] || reject 33 "marker dev:inode mismatch ($di != $(dev_ino "$d")): $m"
}

if [[ -e "$WORK_CAND" || -L "$WORK_CAND" ]]; then
  [[ ! -L "$WORK_CAND" ]] || reject 27 "refuse symlink work dir: $WORK_CAND"
  [[ -d "$WORK_CAND" ]] || reject 28 "work path exists and is not a directory: $WORK_CAND"
  WORK_REAL=$(cd "$WORK_CAND" && pwd -P)
  [[ "$(dirname "$WORK_REAL")" == "$ROOT_REAL" ]] || reject 29 "work dir is not a direct child of fixed root: $WORK_REAL"
  [[ "$(stat -c '%u' "$WORK_REAL")" == "$ME" ]] || reject 30 "refuse non-owned directory: $WORK_REAL"
  check_owned_workdir "$WORK_REAL"
  echo "run_case.sh: removing own previous workdir $WORK_REAL" >&2
  rm -rf -- "$WORK_REAL"
fi

mkdir "$WORK_CAND"   # no -p: must be freshly created by us
WORK=$(cd "$WORK_CAND" && pwd -P)
[[ "$(dirname "$WORK")" == "$ROOT_REAL" ]] || reject 29 "new work dir is not a direct child of fixed root: $WORK"
TOKEN=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
{
  echo "$MAGIC"
  echo "name=$NAME"
  echo "uid=$ME"
  echo "dev_ino=$(dev_ino "$WORK")"
  echo "token=$TOKEN"
  echo "created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$WORK/$MARKER_NAME"
mkdir "$WORK/frames"

cp -r "$SRC" "$WORK/proj"
cp "$HERE/delta_log.gd" "$WORK/proj/delta_log.gd"
{
  echo '[autoload]'
  echo 'DeltaLog="*res://delta_log.gd"'
  for line in "$@"; do echo "$line"; done
} > "$WORK/proj/override.cfg"

"$XVFB" -a -s "-screen 0 1800x1000x24" "$GODOT" --path "$WORK/proj" \
  --resolution 1672x941 --write-movie "$WORK/frames/f.png" --fixed-fps 30 --quit-after "$N" -- --hide-ui ${EXTRA_ARGS:-} \
  > "$WORK/log.txt" 2>&1
echo "done $NAME -> $WORK"
