#!/usr/bin/env bash
# 画卷漫步隔离原型（#199）：把 test/exploration_scroll_prototype 装配成临时独立最小项目再运行。
# 用法：
#   bash tools/run_exploration_scroll_prototype.sh test                 # 严格门禁跑隔离测试
#   bash tools/run_exploration_scroll_prototype.sh run                  # 本机窗口试玩
#   bash tools/run_exploration_scroll_prototype.sh export               # 导出 Web 到临时目录 web/
#   bash tools/run_exploration_scroll_prototype.sh movie OUT.avi WxH    # 按脚本演示录制视频
# 默认每次新建独立临时目录（并行运行互不干扰）；PROTOTYPE_DIR 可指定目录，但只接受空目录或本脚本建过的目录。
# 原型不进主项目：这里不写仓库内任何文件，主项目导出也继续按 test/* 排除。
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mode=${1:-test}
marker=.youjia-scroll-prototype-workdir
## 隔离测试的最少检查数：防止检查被误删后门禁仍然通过
min_checks=154
source "$root/tools/lib/verified_godot.sh"

if [[ -n "${PROTOTYPE_DIR:-}" ]]; then
  mkdir -p "$PROTOTYPE_DIR"
  work=$(cd "$PROTOTYPE_DIR" && pwd)
  case "$root/" in
    "$work"/*) echo "PROTOTYPE_DIR must not contain the repository: $work" >&2; exit 2 ;;
  esac
  case "$work/" in
    "$root"/*) echo "PROTOTYPE_DIR must be outside the repository: $work" >&2; exit 2 ;;
  esac
  if [[ -n "$(ls -A "$work")" && ! -f "$work/$marker" ]]; then
    echo "PROTOTYPE_DIR is not empty and was not created by this script: $work" >&2
    exit 2
  fi
  find "$work" -mindepth 1 -delete
else
  work=$(mktemp -d "${TMPDIR:-/tmp}/youjia-scroll-prototype.XXXXXX")
fi
touch "$work/$marker"
echo "prototype project: $work" >&2

mkdir -p "$work/test" "$work/assets/template/fonts"
cp -R "$root/test/exploration_scroll_prototype" "$work/test/"
cp "$work/test/exploration_scroll_prototype/prototype_project.godot" "$work/project.godot"
cp "$work/test/exploration_scroll_prototype/prototype_export_presets.cfg" "$work/export_presets.cfg"
# 只借用主项目已有的中文字体与其许可证；字体未从资源锁恢复时原型退回引擎默认字体
for font in NotoSansSC-VF.subset.woff2 NotoSansSC-OFL.txt; do
  if [[ -f "$root/assets/template/fonts/$font" ]]; then
    cp "$root/assets/template/fonts/$font" "$work/assets/template/fonts/"
  else
    echo "font not found, falling back to the default font: $font" >&2
  fi
done

run_verified_godot "$work/import.log" --headless --path "$work" --editor --import --quit > /dev/null

case "$mode" in
  test)
    run_verified_godot "$work/suite.log" --headless --path "$work" --script res://test/exploration_scroll_prototype/scroll_prototype_suite.gd
    count=$(sed -nE 's/^EXPLORATION SCROLL PROTOTYPE PASS ([0-9]+)$/\1/p' "$work/suite.log")
    if [[ -z "$count" || "$count" -lt "$min_checks" ]]; then
      echo "expected at least $min_checks passing checks, got '${count:-none}'" >&2
      exit 1
    fi
    ;;
  run)
    "${GODOT:-godot}" --path "$work"
    ;;
  export)
    mkdir -p "$work/web"
    run_verified_godot "$work/export.log" --headless --path "$work" --export-release Web "$work/web/index.html" > /dev/null
    test -s "$work/web/index.pck"
    echo "$work/web/index.html"
    ;;
  movie)
    out=${2:?movie needs an output .avi path}
    resolution=${3:-1280x720}
    if [[ ! "$resolution" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
      echo "resolution must look like 1280x720: $resolution" >&2
      exit 2
    fi
    # 录像尺寸取项目视口尺寸，所以按目标分辨率改临时项目配置，而不是只改窗口
    sed -i -e "s/^window\/size\/viewport_width=.*/window\/size\/viewport_width=${resolution%x*}/" \
      -e "s/^window\/size\/viewport_height=.*/window\/size\/viewport_height=${resolution#*x}/" "$work/project.godot"
    run_verified_godot "$work/movie.log" --path "$work" --write-movie "$out" --fixed-fps 30 --resolution "$resolution" \
      res://test/exploration_scroll_prototype/scroll_demo.tscn > /dev/null
    test -s "$out"
    ;;
  *)
    echo "unknown mode: $mode" >&2
    exit 2
    ;;
esac
