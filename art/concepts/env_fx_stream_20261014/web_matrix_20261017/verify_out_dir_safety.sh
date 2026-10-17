#!/usr/bin/env bash
# #749 隔离候选：输出目录安全回归（回应 PR #804 审查 6231502792）。仍只是候选工具测试。
# 全部在 mktemp 隔离夹具里跑：复制两个入口 + safe_out_dir.sh 到夹具树，godot/chrome 用桩，
# 不碰真实工程、个人目录或仓库文件。验证：
#   - 已有目录（放 sentinel）作参数：只在其中新建独占子目录，sentinel 与原有内容不变，从不删除；
#   - 缺 Godot / 缺 Chrome：在创建任何目录之前拒绝（退出 20），父目录内容不变；
#   - 空参数 21、符号链接父目录 22、不存在的父目录 23（且不被创建）、多参数 26；
#   - 上级路径（../）按规范化路径落到真实父目录内的新子目录；无参数时落到 $TMPDIR 下新子目录；
#   - 新子目录可正常写入（桩 godot 在其中写 export 产物后才按计划失败）。
# 用法：bash verify_out_dir_safety.sh   全部通过打印 PASS=<n> FAIL=0 并退出 0。
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CAND="$(dirname "$HERE")"
FIX="$(mktemp -d)"
trap 'rm -rf -- "$FIX"' EXIT   # 只删本脚本 mktemp 的夹具
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "ok   $*"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $*"; }

# 夹具树：fixture/cand/{safe_out_dir.sh,web_export_check.sh,web_probe_server.py,godot_preview/,web_matrix_20261017/run_web_matrix.sh}
T="$FIX/cand"; mkdir -p "$T/godot_preview" "$T/web_matrix_20261017" "$FIX/bin" "$FIX/tmp" "$FIX/work"
cp "$CAND/safe_out_dir.sh" "$CAND/web_export_check.sh" "$CAND/web_probe_server.py" "$T/"
cp "$HERE/run_web_matrix.sh" "$T/web_matrix_20261017/"
# 桩 godot：--import 成功；--export-release 在目标处写一个文件证明目录可用，然后失败（让入口在浏览器前停下）。
cat >"$FIX/bin/godot" <<'G'
#!/usr/bin/env bash
for a in "$@"; do case "$a" in --version) echo "stub-godot"; exit 0;; esac; done
prev=""; for a in "$@"; do
  if [ "$prev" = "Web crop demo 749" ]; then echo stub >"$a.stub_export"; echo "stub export stop" >&2; exit 7; fi
  prev="$a"; done
exit 0
G
printf '#!/usr/bin/env bash\necho stub-chrome; exit 9\n' >"$FIX/bin/google-chrome"
chmod +x "$FIX/bin/godot" "$FIX/bin/google-chrome"
export PATH="$FIX/bin:$PATH"

snap() { (cd "$1" && find . -mindepth 1 -maxdepth 1 -printf '%P\n' | LC_ALL=C sort); }
mk_parent() { local d="$FIX/work/$1"; mkdir -p "$d/old_round"; echo "sentinel-$1" >"$d/SENTINEL.txt"; echo x >"$d/old_round/keep.bin"; echo "$d"; }
intact() { [ "$(cat "$1/SENTINEL.txt" 2>/dev/null)" = "sentinel-$2" ] && [ -f "$1/old_round/keep.bin" ]; }

for ENTRY in web_matrix_20261017/run_web_matrix.sh web_export_check.sh; do
  case "$ENTRY" in web_matrix*) PFX=webmatrix749;; *) PFX=web749;; esac
  tag="${ENTRY##*/}"
  run() { (cd "$FIX/work" && TMPDIR="$FIX/tmp" bash "$T/$ENTRY" "$@" >"$FIX/last.log" 2>&1); echo $?; }

  # 1 已有目录作父目录
  P="$(mk_parent "$tag-existing")"; before="$(snap "$P")"
  rc=$(GODOT=godot CHROME=google-chrome run "$P")
  after="$(snap "$P")"; new="$(comm -13 <(echo "$before") <(echo "$after"))"
  if [ "$rc" -ne 0 ] && intact "$P" "$tag-existing" && [ -z "$(comm -23 <(echo "$before") <(echo "$after"))" ] \
     && [ "$(echo "$new" | grep -c "^$PFX\.")" = 1 ] && [ "$(echo "$new" | wc -l)" = 1 ] \
     && { [ -f "$P/$new/site/index.html.stub_export" ] || [ -f "$P/$new/index.html.stub_export" ]; }; then
    ok "$tag existing parent: sentinel kept, nothing removed, one new $new, new dir writable (rc=$rc stub stop)"
  else bad "$tag existing parent rc=$rc new=[$new]"; cat "$FIX/last.log"; fi

  # 2 缺 Godot：创建前拒绝
  P="$(mk_parent "$tag-nogodot")"; before="$(snap "$P")"
  rc=$(GODOT="$FIX/bin/no-such-godot" CHROME=google-chrome run "$P")
  if [ "$rc" = 20 ] && [ "$(snap "$P")" = "$before" ] && intact "$P" "$tag-nogodot"; then ok "$tag missing godot: rc=20 before any create, parent unchanged"
  else bad "$tag missing godot rc=$rc"; cat "$FIX/last.log"; fi

  # 3 缺 Chrome：创建前拒绝
  P="$(mk_parent "$tag-nochrome")"; before="$(snap "$P")"
  rc=$(GODOT=godot CHROME="$FIX/bin/no-such-chrome" run "$P")
  if [ "$rc" = 20 ] && [ "$(snap "$P")" = "$before" ] && intact "$P" "$tag-nochrome"; then ok "$tag missing chrome: rc=20 before any create, parent unchanged"
  else bad "$tag missing chrome rc=$rc"; cat "$FIX/last.log"; fi

  # 4 空参数
  wb="$(snap "$FIX/work")"; tb="$(snap "$FIX/tmp")"
  rc=$(GODOT=godot CHROME=google-chrome run "")
  if [ "$rc" = 21 ] && [ "$(snap "$FIX/work")" = "$wb" ] && [ "$(snap "$FIX/tmp")" = "$tb" ]; then ok "$tag empty arg: rc=21, nothing created"
  else bad "$tag empty arg rc=$rc"; cat "$FIX/last.log"; fi

  # 5 符号链接父目录（链接与以 / 结尾两种写法）
  P="$(mk_parent "$tag-linktarget")"; L="$FIX/work/$tag-link"; ln -s "$P" "$L"; before="$(snap "$P")"
  rc1=$(GODOT=godot CHROME=google-chrome run "$L"); rc2=$(GODOT=godot CHROME=google-chrome run "$L/")
  if [ "$rc1" = 22 ] && [ "$rc2" = 22 ] && [ "$(snap "$P")" = "$before" ] && intact "$P" "$tag-linktarget"; then ok "$tag symlink parent: rc=22 (both forms), target unchanged"
  else bad "$tag symlink parent rc=$rc1/$rc2"; cat "$FIX/last.log"; fi

  # 6 不存在的父目录：拒绝且不创建
  rc=$(GODOT=godot CHROME=google-chrome run "$FIX/work/$tag-missing/sub")
  if [ "$rc" = 23 ] && [ ! -e "$FIX/work/$tag-missing" ]; then ok "$tag nonexistent parent: rc=23, not created"
  else bad "$tag nonexistent parent rc=$rc"; cat "$FIX/last.log"; fi

  # 7 上级路径 ../
  P="$(mk_parent "$tag-dotdot")"; mkdir -p "$FIX/work/sib"; before="$(snap "$P")"
  rc=$( (cd "$FIX/work/sib" && GODOT=godot CHROME=google-chrome TMPDIR="$FIX/tmp" bash "$T/$ENTRY" "../$tag-dotdot" >"$FIX/last.log" 2>&1); echo $?)
  new="$(comm -13 <(echo "$before") <(snap "$P"))"
  if intact "$P" "$tag-dotdot" && [ -z "$(comm -23 <(echo "$before") <(snap "$P"))" ] && [ "$(echo "$new" | grep -c "^$PFX\.")" = 1 ] \
     && grep -q "^out_dir=$(realpath "$P")/$PFX\." "$FIX/last.log"; then ok "$tag ../ parent: canonical new subdir $new, sentinel kept (rc=$rc stub stop)"
  else bad "$tag ../ parent rc=$rc new=[$new]"; cat "$FIX/last.log"; fi

  # 8 无参数：$TMPDIR 下新子目录
  tb="$(snap "$FIX/tmp")"
  rc=$(GODOT=godot CHROME=google-chrome run)
  new="$(comm -13 <(echo "$tb") <(snap "$FIX/tmp"))"
  if [ -z "$(comm -23 <(echo "$tb") <(snap "$FIX/tmp"))" ] && [ "$(echo "$new" | grep -c "^$PFX\.")" = 1 ]; then ok "$tag no arg: new $new under TMPDIR (rc=$rc stub stop)"
  else bad "$tag no arg rc=$rc new=[$new]"; cat "$FIX/last.log"; fi

  # 9 多参数
  P="$(mk_parent "$tag-twoargs")"; before="$(snap "$P")"
  rc=$(GODOT=godot CHROME=google-chrome run "$P" "$P")
  if [ "$rc" = 26 ] && [ "$(snap "$P")" = "$before" ]; then ok "$tag two args: rc=26, parent unchanged"
  else bad "$tag two args rc=$rc"; cat "$FIX/last.log"; fi

  # 10 连跑两次同一父目录：各自独立子目录，第一次的产物不被第二次删除
  P="$(mk_parent "$tag-twice")"
  GODOT=godot CHROME=google-chrome run "$P" >/dev/null; first="$(snap "$P" | grep "^$PFX\." )"
  GODOT=godot CHROME=google-chrome run "$P" >/dev/null; all="$(snap "$P" | grep -c "^$PFX\." )"
  if [ "$all" = 2 ] && [ -d "$P/$first" ] && [ -n "$(ls -A "$P/$first")" ] && intact "$P" "$tag-twice"; then ok "$tag repeat run: 2 separate run dirs, first run's files kept"
  else bad "$tag repeat run all=$all first=[$first]"; fi
done

# 静态：两个入口不再有对 OUT 的 rm -rf
if grep -nE 'rm -rf[^#]*\$\{?OUT' "$CAND/web_export_check.sh" "$HERE/run_web_matrix.sh"; then bad "static: rm -rf on OUT still present"
else ok "static: no rm -rf on OUT in either entry"; fi
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = 0 ]
