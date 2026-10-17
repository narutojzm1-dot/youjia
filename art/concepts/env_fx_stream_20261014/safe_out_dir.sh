# shellcheck shell=bash
# #749 隔离候选工具共用：本轮独占输出目录（回应 PR #804 审查 6231502792）。仍只是候选工具，不是运行时代码。
# 被 web_export_check.sh、web_matrix_20261017/run_web_matrix.sh source。
# 原则：本工具永不删除任何已有目录或其内容。位置参数只当「父目录」，每轮在其中 mktemp 一个新的独占子目录；
# 不给参数时父目录为 ${TMPDIR:-/tmp}。依赖检查在创建任何目录之前完成。
# 退出码：20 缺依赖；21 空参数；22 父目录是符号链接；23 父目录不存在或不是目录；24 父目录不可写；26 参数多于一个。

require_cmds() {
  local c
  for c in "$@"; do
    command -v -- "$c" >/dev/null 2>&1 || { echo "refuse: missing dependency: $c (nothing created or deleted)" >&2; return 20; }
  done
}

# new_run_dir <前缀> [父目录]：在 stdout 打印新建的独占目录绝对路径。
new_run_dir() {
  local prefix="$1"; shift
  local parent real
  if [ "$#" -gt 1 ]; then
    echo "refuse: expected at most one OUTPUT_PARENT argument, got $#" >&2; return 26
  elif [ "$#" -eq 1 ]; then
    parent="$1"
    [ -n "$parent" ] || { echo "refuse: empty OUTPUT_PARENT argument" >&2; return 21; }
    if [ -L "$parent" ] || [ -L "${parent%/}" ]; then
      echo "refuse: OUTPUT_PARENT is a symlink: $parent" >&2; return 22
    fi
  else
    parent="${TMPDIR:-/tmp}"
  fi
  [ -d "$parent" ] || { echo "refuse: OUTPUT_PARENT does not exist or is not a directory: $parent (not created)" >&2; return 23; }
  [ -w "$parent" ] || { echo "refuse: OUTPUT_PARENT is not writable: $parent" >&2; return 24; }
  real="$(realpath -e -- "$parent")" || { echo "refuse: cannot resolve OUTPUT_PARENT: $parent" >&2; return 23; }
  mktemp -d -- "$real/$prefix.$(date +%Y%m%d-%H%M%S).XXXXXXXX"
}
