#!/usr/bin/env bash
# 画卷漫步隔离原型（#199）：把 test/exploration_scroll_prototype 装配成临时独立最小项目再运行。
# 用法：
#   bash tools/run_exploration_scroll_prototype.sh test                 # 严格门禁跑隔离测试
#   bash tools/run_exploration_scroll_prototype.sh run                  # 本机窗口试玩
#   bash tools/run_exploration_scroll_prototype.sh export               # 导出 Web 到临时目录 web/
#   bash tools/run_exploration_scroll_prototype.sh movie OUT.avi WxH    # 按脚本演示录制视频
# 临时目录默认 ${TMPDIR:-/tmp}/youjia-scroll-prototype，可用 PROTOTYPE_DIR 覆盖。
# 原型不进主项目：这里不写仓库内任何文件，主项目导出也继续按 test/* 排除。
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mode=${1:-test}
work=${PROTOTYPE_DIR:-${TMPDIR:-/tmp}/youjia-scroll-prototype}
source "$root/tools/lib/verified_godot.sh"

rm -rf "$work"
mkdir -p "$work/test" "$work/assets/template/fonts"
cp -R "$root/test/exploration_scroll_prototype" "$work/test/"
cp "$work/test/exploration_scroll_prototype/prototype_project.godot" "$work/project.godot"
cp "$work/test/exploration_scroll_prototype/prototype_export_presets.cfg" "$work/export_presets.cfg"
# 只借用主项目已有的中文字体与其许可证，让占位标注能显示中文
cp "$root/assets/template/fonts/NotoSansSC-VF.subset.woff2" "$root/assets/template/fonts/NotoSansSC-OFL.txt" "$work/assets/template/fonts/"

run_verified_godot "$work/import.log" --headless --path "$work" --editor --import --quit > /dev/null

case "$mode" in
  test)
    run_verified_godot "$work/suite.log" --headless --path "$work" --script res://test/exploration_scroll_prototype/scroll_prototype_suite.gd
    grep -Eq '^EXPLORATION SCROLL PROTOTYPE PASS [0-9]+$' "$work/suite.log"
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
    # 录像尺寸取项目视口尺寸，所以按目标分辨率改临时项目配置，而不是只改窗口
    sed -i -e "s/^window\/size\/viewport_width=.*/window\/size\/viewport_width=${resolution%x*}/" \
      -e "s/^window\/size\/viewport_height=.*/window\/size\/viewport_height=${resolution#*x}/" "$work/project.godot"
    "${GODOT:-godot}" --path "$work" --write-movie "$out" --fixed-fps 30 --resolution "$resolution" \
      res://test/exploration_scroll_prototype/scroll_demo.tscn
    ;;
  *)
    echo "unknown mode: $mode" >&2
    exit 2
    ;;
esac
