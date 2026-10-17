import pathlib,subprocess,json,hashlib
R=pathlib.Path(__file__).parent;T=R/'grok-safe-lab';(T/'startup').mkdir(parents=True,exist_ok=True);(T/'godot_preview').mkdir(exist_ok=True);(T/'fakebin').mkdir(exist_ok=True)
src=(R/'grok-32e/run_case.sh').read_bytes();(T/'startup/run_case.sh').write_bytes(src)
(T/'startup/delta_log.gd').write_bytes(b'extends Node\n')
(T/'godot_preview/project.godot').write_bytes(b'config_version=5\n')
(T/'fakebin/rm').write_bytes(b'#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$RMLOG"\nexit 97\n')
(T/'fakebin/xvfb').write_bytes(b'#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$XVLOG"\nexit 0\n')
(T/'fakebin/godot').write_bytes(b'#!/usr/bin/env bash\nexit 0\n')
driver=r'''set -euo pipefail
T=$(cd "$(dirname "$0")" && pwd)
export RMLOG="$T/rm.log" XVLOG="$T/xvfb.log"
export PATH="$T/fakebin:$PATH" GODOT="$T/fakebin/godot" XVFB_RUN="$T/fakebin/xvfb"
chmod +x "$T/fakebin/"*
ROOT=/tmp/startup749
PREFIX=CODEX_32E_${BASHPID}_${RANDOM}
mkdir -p "$ROOT"
ROOT_REAL=$(cd "$ROOT" && pwd -P)
echo "FIXED_ROOT_WINDOWS=$(cygpath -aw "$ROOT_REAL")"
checks=0
call() {
 local expected=$1;shift
 : > "$RMLOG";: > "$XVLOG"
 set +e
 bash "$T/startup/run_case.sh" "$@" > "$T/last.out" 2>&1
 rc=$?
 set -e
 [[ $rc == "$expected" ]] || { cat "$T/last.out"; exit 81; }
 if (( expected>=20 && expected<=33 ));then grep -q "^REJECT $expected " "$T/last.out"; [[ ! -s "$RMLOG" && ! -s "$XVLOG" ]];fi
 checks=$((checks+1))
 echo "PASS expected=$expected args=$*"
}
for name in '' . .. A/B /tmp .hidden 'A B' 'A;rm';do call 21 "$name" 10;done
for n in 0 -1 12x '';do call 22 "${PREFIX}_bad" "$n";done
UNK="$ROOT/${PREFIX}_unknown";[[ ! -e "$UNK" && ! -L "$UNK" ]];mkdir "$UNK";echo keep > "$UNK/keep.txt"
call 31 "${PREFIX}_unknown" 3
[[ $(cat "$UNK/keep.txt") == keep ]]
OWN="$ROOT/${PREFIX}_own";[[ ! -e "$OWN" && ! -L "$OWN" ]]
call 0 "${PREFIX}_own" 3
[[ -f "$OWN/.run_case_owner" && -f "$OWN/proj/override.cfg" && -s "$XVLOG" && ! -s "$RMLOG" ]]
[[ $(sed -n 's/^dev_ino=//p' "$OWN/.run_case_owner") == $(stat -c %d:%i "$OWN") ]]
echo keep > "$OWN/keep.txt"
call 97 "${PREFIX}_own" 3
[[ $(cat "$RMLOG") == "-rf -- $ROOT_REAL/${PREFIX}_own" && $(cat "$OWN/keep.txt") == keep && ! -s "$XVLOG" ]]
COPY="$ROOT/${PREFIX}_copy";[[ ! -e "$COPY" && ! -L "$COPY" ]];mkdir "$COPY";echo keep > "$COPY/keep.txt"
sed "s/^name=.*/name=${PREFIX}_copy/" "$OWN/.run_case_owner" > "$COPY/.run_case_owner"
call 33 "${PREFIX}_copy" 3
[[ $(cat "$COPY/keep.txt") == keep ]]
FILE="$ROOT/${PREFIX}_file";[[ ! -e "$FILE" && ! -L "$FILE" ]];echo keep > "$FILE"
call 28 "${PREFIX}_file" 3
echo "CHECKS=$checks REAL_DELETE=0 SENTINELS_INTACT=1"
echo "OWN=$OWN UNKNOWN=$UNK"
'''
(T/'driver.sh').write_bytes(driver.encode())
p=subprocess.run(['C:/Program Files/Git/bin/bash.exe','--noprofile','--norc',str(T/'driver.sh')],capture_output=True,timeout=45)
log=p.stdout.decode('utf8',errors='replace')+p.stderr.decode('utf8',errors='replace');(R/'grok-safe-check.log').write_text(log,encoding='utf8')
d={'source':'32e1b966bc39d1b5f20fcd476b1e847fc7e302b7','run_case_sha256':hashlib.sha256(src).hexdigest(),'environment':'Windows Git Bash','exit_code':p.returncode,'real_delete':False,'recording':'xvfb/Godot stubs; not original Linux recording chain','original_run_case_unmodified':True,'log':log}
(R/'grok-safe-check.json').write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps(d,ensure_ascii=False));assert p.returncode==0
