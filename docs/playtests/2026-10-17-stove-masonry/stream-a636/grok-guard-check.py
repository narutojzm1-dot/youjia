import pathlib,subprocess,json,os,hashlib
R=pathlib.Path(__file__).parent;T=R/'grok-guard-a636';(T/'startup').mkdir(parents=True,exist_ok=True);(T/'godot_preview').mkdir(exist_ok=True);(T/'fakebin').mkdir(exist_ok=True)
src=(R/'grok-safe-a636/run_case.sh').read_bytes();(T/'startup/run_case.sh').write_bytes(src);(T/'godot_preview/project.godot').write_bytes(b'config_version=5\n')
(T/'fakebin/rm').write_bytes(b'#!/usr/bin/env bash\nprintf \"RM_REACHED %s\\\\n\" \"$*\" >> \"$SAFETY_LOG\"\nexit 97\n')
driver=r'''set -euo pipefail
T=$(cd "$(dirname "$0")" && pwd)
export SAFETY_LOG="$T/rm.log"
: > "$SAFETY_LOG"
export PATH="$T/fakebin:$PATH"
chmod +x "$T/fakebin/rm"
bad=0
for name in '' . .. A/B /tmp .hidden 'A B' 'A;rm'; do
 set +e
 bash "$T/startup/run_case.sh" "$name" 10 >> "$T/calls.log" 2>&1
 rc=$?
 set -e
 [[ $rc != 0 ]] || exit 8
 bad=$((bad+1))
done
for n in 0 -1 12x ''; do
 set +e
 bash "$T/startup/run_case.sh" safe "$n" >> "$T/calls.log" 2>&1
 rc=$?
 set -e
 [[ $rc != 0 ]] || exit 8
 bad=$((bad+1))
done
[[ ! -s "$SAFETY_LOG" ]] || exit 9
ROOT=/tmp/startup749
NAME=CODEX_A636_SAFETY_$BASHPID
WORK="$ROOT/$NAME"
[[ ! -e "$WORK" && ! -L "$WORK" ]] || exit 10
mkdir -p "$WORK"
[[ "$(dirname "$(cd "$WORK" && pwd -P)")" == "$(cd "$ROOT" && pwd -P)" ]] || exit 11
printf 'manual sentinel; this directory was not created by run_case.sh\n' > "$WORK/keep.txt"
set +e
bash "$T/startup/run_case.sh" "$NAME" 1 >> "$T/calls.log" 2>&1
rc=$?
set -e
[[ -f "$WORK/keep.txt" ]] || exit 12
printf 'BAD_ARGUMENTS_REJECTED_BEFORE_RM=%s\nSAME_UID_UNKNOWN_EXIT=%s\nCASE=%s\n' "$bad" "$rc" "$WORK"
cat "$SAFETY_LOG"
[[ $rc == 97 && -s "$SAFETY_LOG" ]]
'''
(T/'driver.sh').write_bytes(driver.encode())
p=subprocess.run(['C:/Program Files/Git/bin/bash.exe','--noprofile','--norc',str(T/'driver.sh')],capture_output=True,timeout=30)
out=p.stdout.decode('utf-8',errors='replace')+p.stderr.decode('utf-8',errors='replace');(R/'grok-a636-guard-observation.log').write_bytes(out.encode())
assert p.returncode==0,out
d={'source':'a6361372066c2925cea75e5856babb85ad18120d','unmodified_run_case_sha256':hashlib.sha256(src).hexdigest(),'actual_environment':'Windows Git Bash','destructive_rm_replaced_with_noop_exit97':True,'real_deletion_executed':False,'bad_arguments_rejected_before_rm':12,'same_uid_unknown_directory_still_requested_rm':True,'sentinel_unchanged':True,'conclusion':'remaining ownership guard defect reproduced; not a passing safety acceptance','output':out}
(R/'grok-a636-guard-observation.json').write_bytes(json.dumps(d,indent=2).encode());print(json.dumps(d))

