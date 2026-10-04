#!/usr/bin/env bash
# 回院适配隔离原型（#200）：把画卷原型、模拟小院、适配器和 #176 固定 SHA 的探索核心 + 假宿主
# 装配成临时独立最小项目再运行。
# 用法：
#   bash tools/run_exploration_return_adapter.sh test                 # 严格门禁跑隔离测试
#   bash tools/run_exploration_return_adapter.sh run                  # 本机窗口试玩
#   bash tools/run_exploration_return_adapter.sh export               # 导出 Web 到临时目录 web/
#   bash tools/run_exploration_return_adapter.sh movie OUT.avi WxH    # 按脚本演示录制视频
# 核心不复制进仓库：每次从 CORE_SHA 用 git show 取出，并把来源写进临时项目的 CORE_SOURCE.txt。
# 默认每次新建独立临时目录，运行后保留以便查看日志；清理：rm -rf "${TMPDIR:-/tmp}"/youjia-return-adapter.*
# PROTOTYPE_DIR 可指定绝对路径，但只接受空目录、不存在的目录或本脚本建过的目录。
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
mode=${1:-test}
marker=.youjia-return-adapter-workdir
## #176 探索核心草案的固定提交（分支 cursor/exp-core-draft-9e9c）；核心更新后要显式改这里并重新审核
core_sha=e2a6d70b186d40c09cfcf48c48292838993d7eb7
core_branch=cursor/exp-core-draft-9e9c
core_files=(
  scripts/exploration/exploration_contract.gd
  scripts/exploration/exploration_catalog.gd
  scripts/exploration/exploration_session.gd
  test/fixtures/exploration_fake_host.gd
  test/fixtures/exploration_fixture_routes.gd
)
## 隔离测试的最少检查数：防止检查被误删后门禁仍然通过
min_checks=150
source "$root/tools/lib/verified_godot.sh"
source "$root/tools/lib/exploration_workdir.sh"

case "$mode" in
  test|run|export) ;;
  movie)
    out=${2:?movie needs an output .avi path}
    resolution=${3:-1280x720}
    if [[ ! "$resolution" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
      echo "resolution must look like 1280x720: $resolution" >&2
      exit 2
    fi
    ;;
  *)
    echo "unknown mode: $mode" >&2
    exit 2
    ;;
esac

## 先找本地，再取分支，分支已不含该提交（例如被强推）时按 SHA 直接取；都取不到就明确报错
has_core() { git -C "$root" cat-file -e "$core_sha^{commit}" 2>/dev/null; }
if ! has_core; then
  git -C "$root" fetch --quiet origin "$core_branch" 2>/dev/null || true
fi
if ! has_core; then
  git -C "$root" fetch --quiet origin "$core_sha" 2>/dev/null || true
fi
if ! has_core; then
  echo "cannot find exploration core $core_sha (branch $core_branch); fetch it or update core_sha after review" >&2
  exit 2
fi

work=$(prepare_exploration_workdir "$root" "$marker" youjia-return-adapter "${PROTOTYPE_DIR:-}")
echo "prototype project: $work" >&2

mkdir -p "$work/test" "$work/assets/template/fonts"
cp -R "$root/test/exploration_scroll_prototype" "$root/test/exploration_return_adapter" "$work/test/"
cp "$work/test/exploration_return_adapter/adapter_project.godot" "$work/project.godot"
cp "$work/test/exploration_return_adapter/adapter_export_presets.cfg" "$work/export_presets.cfg"
for path in "${core_files[@]}"; do
  mkdir -p "$work/$(dirname "$path")"
  git -C "$root" show "$core_sha:$path" > "$work/$path"
done
{
  echo "exploration core source: $core_branch @ $core_sha"
  printf '%s\n' "${core_files[@]}"
} > "$work/CORE_SOURCE.txt"
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
    run_verified_godot "$work/suite.log" --headless --path "$work" --script res://test/exploration_return_adapter/return_adapter_suite.gd
    count=$(sed -nE 's/^EXPLORATION RETURN ADAPTER PASS ([0-9]+)$/\1/p' "$work/suite.log")
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
    # 录像尺寸取项目视口尺寸，所以按目标分辨率改临时项目配置，而不是只改窗口
    sed -i -e "s/^window\/size\/viewport_width=.*/window\/size\/viewport_width=${resolution%x*}/" \
      -e "s/^window\/size\/viewport_height=.*/window\/size\/viewport_height=${resolution#*x}/" "$work/project.godot"
    run_verified_godot "$work/movie.log" --path "$work" --write-movie "$out" --fixed-fps 30 --resolution "$resolution" \
      res://test/exploration_return_adapter/adapter_demo.tscn > /dev/null
    test -s "$out"
    ;;
esac
