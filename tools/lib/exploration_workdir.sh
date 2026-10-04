#!/usr/bin/env bash
# 探索隔离原型运行脚本共用：准备临时独立最小项目的工作目录。
# 用法：work=$(prepare_exploration_workdir <仓库根> <标记文件名> <临时目录前缀> [指定目录])
# 指定目录先只做路径解析和校验，全部通过后才创建或清空；默认新建 mktemp 目录。
# 默认目录不自动删除，便于查看 import.log / suite.log；清理：rm -rf "${TMPDIR:-/tmp}"/<前缀>.*

prepare_exploration_workdir() {
  local root marker prefix requested work
  root=$(cd "$1" && pwd -P)
  marker=$2
  prefix=$3
  requested=${4:-}
  if [[ -z "$requested" ]]; then
    work=$(mktemp -d "${TMPDIR:-/tmp}/$prefix.XXXXXX")
    work=$(cd "$work" && pwd -P)
    touch "$work/$marker"
    printf '%s\n' "$work"
    return 0
  fi
  if [[ "$requested" != /* ]]; then
    echo "PROTOTYPE_DIR must be an absolute path: $requested" >&2
    return 2
  fi
  ## 不创建任何东西地解析真实路径（含符号链接），再和仓库真实路径比较
  work=$(realpath -m -- "$requested")
  if [[ "$work" == "/" ]]; then
    echo "PROTOTYPE_DIR must not be the filesystem root" >&2
    return 2
  fi
  case "$root/" in
    "$work"/*) echo "PROTOTYPE_DIR must not contain the repository: $work" >&2; return 2 ;;
  esac
  case "$work/" in
    "$root"/*) echo "PROTOTYPE_DIR must be outside the repository: $work" >&2; return 2 ;;
  esac
  if [[ -e "$work" && ! -d "$work" ]]; then
    echo "PROTOTYPE_DIR exists and is not a directory: $work" >&2
    return 2
  fi
  if [[ -d "$work" && -n "$(ls -A "$work")" && ! -f "$work/$marker" ]]; then
    echo "PROTOTYPE_DIR is not empty and was not created by this script: $work" >&2
    return 2
  fi
  mkdir -p "$work"
  find "$work" -mindepth 1 -delete
  touch "$work/$marker"
  printf '%s\n' "$work"
}
