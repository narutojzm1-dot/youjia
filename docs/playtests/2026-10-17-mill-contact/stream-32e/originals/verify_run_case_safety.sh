#!/usr/bin/env bash
# Agent-ID: GROK-BUILD — run_case.sh 清理安全验证（回应 CODEX-LEAD review on a6361372）。
# 不跑 Godot、不录帧：xvfb-run / Godot 用记录替身；删除阶段用 rm 记录替身（返回 97，实际不删）核对“是否到达删除”。
# 每项核对：精确退出码 + stderr 的 "REJECT <code>" 原因码 + rm/xvfb 替身调用次数 + 哨兵文件仍在。
# 本脚本自身的临时目录与 /tmp/startup749 下的测试 case 名均为本次唯一名称，结束后只清理本次创建的条目。
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RC="$HERE/run_case.sh"
ROOT=/tmp/startup749
RM=/bin/rm
PASS=0
FAIL=0

T=$(mktemp -d /tmp/verify_run_case.XXXXXXXX)
STUB="$T/stub"; mkdir "$STUB"
RMLOG="$T/rm.log"; XVLOG="$T/xvfb.log"
cat > "$STUB/rm" <<STUBEOF
#!/usr/bin/env bash
echo "\$*" >> "$RMLOG"
exit 97
STUBEOF
cat > "$T/xvfb-run" <<STUBEOF
#!/usr/bin/env bash
echo "\$*" >> "$XVLOG"
exit 0
STUBEOF
printf '#!/bin/sh\nexit 0\n' > "$T/godot"
chmod +x "$STUB/rm" "$T/xvfb-run" "$T/godot"

UNIQ="vrc_$(date +%s)_$$_${RANDOM}"
CREATED=()   # case dirs/links under ROOT created by this run
# uname_new VAR suffix：在当前 shell 设置唯一 case 名并登记（不能放在 $(...) 子 shell 里，否则登记丢失）
uname_new() { local n="${UNIQ}_$2"; [[ ! -e "$ROOT/$n" && ! -L "$ROOT/$n" ]] || { echo "name collision: $n" >&2; exit 2; }; CREATED+=("$ROOT/$n"); printf -v "$1" '%s' "$n"; }

lines() { [[ -f "$1" ]] && wc -l < "$1" | tr -d ' ' || echo 0; }

# run <label> <expect_rc> <expect_rm_calls> <expect_xvfb_calls> [--real-rm] [--rc PATH] [--xvfb PATH] [--godot PATH] -- args...
run() {
  local label=$1 erc=$2 erm=$3 exv=$4; shift 4
  local path="$STUB:$PATH" rc_script=$RC xv="$T/xvfb-run" gd="$T/godot"
  while [[ $1 != -- ]]; do
    case $1 in
      --real-rm) path=$PATH; shift ;;
      --rc) rc_script=$2; shift 2 ;;
      --xvfb) xv=$2; shift 2 ;;
      --godot) gd=$2; shift 2 ;;
    esac
  done
  shift
  : > "$RMLOG"; : > "$XVLOG"
  local err rc
  set +e
  err=$(PATH="$path" XVFB_RUN="$xv" GODOT="$gd" "$rc_script" "$@" 2>&1 >/dev/null)
  rc=$?
  set -e
  local nrm nxv ok=1 why=""
  nrm=$(lines "$RMLOG"); nxv=$(lines "$XVLOG")
  [[ $rc -eq $erc ]] || { ok=0; why+=" rc=$rc(want $erc)"; }
  if (( erc >= 20 && erc <= 33 )); then
    grep -q "^REJECT $erc " <<<"$err" || { ok=0; why+=" missing 'REJECT $erc'"; }
  fi
  [[ $nrm -eq $erm ]] || { ok=0; why+=" rm_calls=$nrm(want $erm)"; }
  [[ $nxv -eq $exv ]] || { ok=0; why+=" xvfb_calls=$nxv(want $exv)"; }
  if [[ $ok -eq 1 ]]; then echo "PASS $label (exit $rc, rm=$nrm, xvfb=$nxv)"; PASS=$((PASS+1));
  else echo "FAIL $label:$why :: $(head -c 300 <<<"$err")"; FAIL=$((FAIL+1)); fi
}
check() { if eval "$2"; then echo "PASS $1"; PASS=$((PASS+1)); else echo "FAIL $1"; FAIL=$((FAIL+1)); fi; }

mkdir -p "$ROOT"

# --- 参数类拒绝（均须在删除与录制之前） ---
run "usage: one arg" 20 0 0 -- only_one
run "empty name" 21 0 0 -- "" 10
run "dot name" 21 0 0 -- "." 10
run "dotdot name" 21 0 0 -- ".." 10
run "path with slash" 21 0 0 -- "A/B" 10
run "absolute path" 21 0 0 -- "/tmp" 10
run "dotfile" 21 0 0 -- ".hidden" 10
run "space in name" 21 0 0 -- "A B" 10
run "semicolon" 21 0 0 -- "A;rm" 10
run "zero frames" 22 0 0 -- "${UNIQ}_x" 0
run "negative frames" 22 0 0 -- "${UNIQ}_x" -1
run "non-integer frames" 22 0 0 -- "${UNIQ}_x" 12x
run "empty frames" 22 0 0 -- "${UNIQ}_x" ""

# --- 依赖预检（任何删除前） ---
mkdir -p "$T/nosrc/startup_check"; cp "$RC" "$T/nosrc/startup_check/run_case.sh"
run "missing godot_preview" 23 0 0 --rc "$T/nosrc/startup_check/run_case.sh" -- "${UNIQ}_x" 5
run "missing xvfb-run" 24 0 0 --xvfb "$T/no_such_xvfb" -- "${UNIQ}_x" 5
run "missing godot" 25 0 0 --godot "$T/no_such_godot" -- "${UNIQ}_x" 5
printf 'x' > "$T/godot_noexec"
run "non-executable godot" 25 0 0 --godot "$T/godot_noexec" -- "${UNIQ}_x" 5
check "param/precheck rejects created no case dir" "[[ ! -e $ROOT/${UNIQ}_x ]]"

# --- 符号链接 / 非目录 ---
uname_new N_SYM sym; mkdir "$T/symtarget"; echo keep > "$T/symtarget/keep.txt"
ln -s "$T/symtarget" "$ROOT/$N_SYM"
run "symlink work dir" 27 0 0 -- "$N_SYM" 5
check "symlink target sentinel intact" "[[ -f $T/symtarget/keep.txt ]]"
uname_new N_FILE file; echo keep > "$ROOT/$N_FILE"
run "work path is a regular file" 28 0 0 -- "$N_FILE" 5
check "regular file intact" "[[ \$(cat $ROOT/$N_FILE) == keep ]]"

# --- 同 UID 未知目录（无标记）必须拒绝 ---
uname_new N_UNK unknown; mkdir "$ROOT/$N_UNK"; echo keep > "$ROOT/$N_UNK/keep.txt"
run "unknown same-UID dir without marker" 31 0 0 -- "$N_UNK" 5
check "unknown dir sentinel intact" "[[ -f $ROOT/$N_UNK/keep.txt ]]"

# --- 正例 1：新建有效自有目录（真实 mkdir/cp，替身录制） ---
uname_new N_OWN own
run "create fresh own workdir" 0 0 1 -- "$N_OWN" 5
check "own workdir has marker with matching dev:inode" \
  "[[ -f $ROOT/$N_OWN/.run_case_owner && \$(sed -n 's/^dev_ino=//p' $ROOT/$N_OWN/.run_case_owner) == \$(stat -c %d:%i $ROOT/$N_OWN) ]]"
check "own workdir has proj copy and override.cfg" "[[ -f $ROOT/$N_OWN/proj/project.godot && -f $ROOT/$N_OWN/proj/override.cfg ]]"

# --- 标记伪造 / 不符 ---
uname_new N_SYMM markerlink; mkdir "$ROOT/$N_SYMM"; echo keep > "$ROOT/$N_SYMM/keep.txt"
ln -s "$ROOT/$N_OWN/.run_case_owner" "$ROOT/$N_SYMM/.run_case_owner"
run "marker is a symlink" 32 0 0 -- "$N_SYMM" 5
check "markerlink sentinel intact" "[[ -f $ROOT/$N_SYMM/keep.txt ]]"
uname_new N_DIRM markerdir; mkdir -p "$ROOT/$N_DIRM/.run_case_owner"; echo keep > "$ROOT/$N_DIRM/keep.txt"
run "marker is a directory" 32 0 0 -- "$N_DIRM" 5
uname_new N_COPY copied; mkdir "$ROOT/$N_COPY"; echo keep > "$ROOT/$N_COPY/keep.txt"
sed "s/^name=.*/name=$N_COPY/" "$ROOT/$N_OWN/.run_case_owner" > "$ROOT/$N_COPY/.run_case_owner"
run "copied marker (dev:inode mismatch)" 33 0 0 -- "$N_COPY" 5
check "copied-marker sentinel intact" "[[ -f $ROOT/$N_COPY/keep.txt ]]"
uname_new N_NAME wrongname; mkdir "$ROOT/$N_NAME"; echo keep > "$ROOT/$N_NAME/keep.txt"
{ echo 'startup749-run_case-workdir v1'; echo "name=someone_else"; echo "uid=$(id -u)"; echo "dev_ino=$(stat -c %d:%i "$ROOT/$N_NAME")"; } > "$ROOT/$N_NAME/.run_case_owner"
run "marker name mismatch" 33 0 0 -- "$N_NAME" 5
uname_new N_MAGIC badmagic; mkdir "$ROOT/$N_MAGIC"; echo keep > "$ROOT/$N_MAGIC/keep.txt"
{ echo 'something else'; echo "name=$N_MAGIC"; echo "uid=$(id -u)"; echo "dev_ino=$(stat -c %d:%i "$ROOT/$N_MAGIC")"; } > "$ROOT/$N_MAGIC/.run_case_owner"
run "marker magic mismatch" 33 0 0 -- "$N_MAGIC" 5
check "bad-magic sentinel intact" "[[ -f $ROOT/$N_MAGIC/keep.txt ]]"

# --- 正例 2：有效自有目录到达删除阶段，且只删该目录（rm 替身不删） ---
echo keep > "$ROOT/$N_OWN/keep.txt"
run "own workdir reaches delete (rm stub)" 97 1 0 -- "$N_OWN" 5
check "rm stub target is exactly own workdir" "[[ \$(cat $RMLOG) == \"-rf -- $ROOT/$N_OWN\" ]]"
check "own sentinel still there under rm stub" "[[ -f $ROOT/$N_OWN/keep.txt ]]"

# --- 正例 3：真实 rm 清理自有目录并重建（新标记） ---
OLD_TOKEN=$(sed -n 's/^token=//p' "$ROOT/$N_OWN/.run_case_owner")
run "own workdir real cleanup + recreate" 0 0 1 --real-rm -- "$N_OWN" 5
check "old sentinel removed after real cleanup" "[[ ! -e $ROOT/$N_OWN/keep.txt ]]"
check "new marker token differs" "[[ \$(sed -n 's/^token=//p' $ROOT/$N_OWN/.run_case_owner) != $OLD_TOKEN ]]"

# --- 只清理本次创建的条目 ---
for p in "${CREATED[@]}"; do
  if [[ -L "$p" || -f "$p" ]]; then $RM -f -- "$p"; elif [[ -d "$p" ]]; then $RM -rf -- "$p"; fi
done
$RM -rf -- "$T"

check "all entries created by this run were removed" "! ls -d $ROOT/${UNIQ}_* >/dev/null 2>&1"

echo "verify_run_case_safety: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
