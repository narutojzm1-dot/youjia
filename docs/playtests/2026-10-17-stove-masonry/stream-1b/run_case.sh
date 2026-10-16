#!/usr/bin/env bash
# Agent-ID: GROK-BUILD — #749 启动帧核对：把 godot_preview 复制到 /tmp 临时副本，只加 override.cfg + delta_log.gd，
# 用与 README 相同的 Movie Maker 参数录前 N 帧。仓库内 godot_preview/ 不改。
# 用法：run_case.sh <name> <frames> [override 段落行...]；EXTRA_ARGS 追加到 -- 之后（如 --toggle-sequence）
set -euo pipefail
NAME=$1; N=$2; shift 2
HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/../godot_preview"
WORK=/tmp/startup749/$NAME
GODOT=${GODOT:-/home/box/bin/godot}
rm -rf "$WORK"; mkdir -p "$WORK/frames"
cp -r "$SRC" "$WORK/proj"
cp "$HERE/delta_log.gd" "$WORK/proj/delta_log.gd"
{
  echo '[autoload]'
  echo 'DeltaLog="*res://delta_log.gd"'
  for line in "$@"; do echo "$line"; done
} > "$WORK/proj/override.cfg"
xvfb-run -a -s "-screen 0 1800x1000x24" "$GODOT" --path "$WORK/proj" \
  --resolution 1672x941 --write-movie "$WORK/frames/f.png" --fixed-fps 30 --quit-after "$N" -- --hide-ui ${EXTRA_ARGS:-} \
  > "$WORK/log.txt" 2>&1
echo "done $NAME -> $WORK"
