#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d /tmp/youjia-gate-contract.XXXXXX)"
trap 'rm -rf "$fixture"' EXIT
mkdir "$fixture/bin"
cat > "$fixture/bin/timeout" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "${MOCK_OUTPUT:-}"
exit "${MOCK_EXIT:-0}"
MOCK
chmod +x "$fixture/bin/timeout"
checks=0
run_case() {
  local expected="$1" code="$2" output="$3" tee_fails="$4"
  rm -f "$fixture/continued"
  if PATH="$fixture/bin:$PATH" MOCK_EXIT="$code" MOCK_OUTPUT="$output" TEE_FAILS="$tee_fails" \
    bash -euo pipefail -c '
      source "$1/tools/lib/verified_godot.sh"
      if [[ "$TEE_FAILS" == yes ]]; then tee() { cat >/dev/null; return 74; }; fi
      run_verified_godot "$2/run.log" --headless
      touch "$2/continued"
    ' gate-test "$repo" "$fixture" >"$fixture/output.log" 2>&1; then
    actual=pass
  else
    actual=block
  fi
  [[ "$actual" == "$expected" ]] || { cat "$fixture/output.log"; echo "gate mismatch: expected=$expected actual=$actual" >&2; exit 1; }
  if [[ "$expected" == block ]]; then
    [[ ! -e "$fixture/continued" ]] || { echo 'failure continued to next step' >&2; exit 1; }
  else
    [[ -e "$fixture/continued" ]] || exit 1
  fi
  checks=$((checks+1))
}
run_case pass 0 'PASS: simulated suite' no
run_case block 1 'PASS: simulated suite' no
run_case block 124 '' no
run_case block 127 'command not found' no
run_case block 139 '' no
run_case block 0 'SCRIPT ERROR: simulated exception' no
run_case block 0 'ERROR: simulated import failure' no
run_case block 0 'AUDIT FAIL simulated assertion' no
run_case block 0 'FAIL: simulated assertion' no
run_case block 0 'PASS: simulated suite' yes
# Log scanning errors must block too, even when the pipeline itself succeeds.
if bash -euo pipefail -c 'source "$1/tools/lib/verified_godot.sh"; timeout() { echo PASS; }; tee() { cat >/dev/null; }; run_verified_godot "$2/missing/log"' test "$repo" "$fixture" >"$fixture/scan.log" 2>&1; then
  echo 'unreadable log was accepted' >&2; exit 1
fi
checks=$((checks+1))
echo "GODOT GATE CONTRACT PASS $checks"
