#!/usr/bin/env bash
# #231 钓鱼携鱼一致性套件的独立入口（GROK-CONTRIBUTOR）。
# 套件驱动真实 Main/SaveStore，会写 user://youjia_save.json(+.bak/.tmp)，
# 因此这里总是新建临时 XDG 目录，跑完即删；套件本身在未隔离时拒绝运行（退出 2）。
# 用法：bash tools/run_fish_carry_suite.sh      （GODOT=/path/to/godot 可覆盖）
set -euo pipefail
cd "$(dirname "$0")/.."
state="$(mktemp -d "${TMPDIR:-/tmp}/youjia-fish-carry.XXXXXX")"
trap 'rm -rf "$state"' EXIT
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
source tools/lib/verified_godot.sh
run_verified_godot "$state/import.log" --headless --path . --editor --import --quit
run_verified_godot "$state/run.log" --headless --path . --script test/fish_carry_consistency_suite.gd
