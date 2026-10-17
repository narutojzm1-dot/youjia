#!/usr/bin/env bash
# Agent-ID: GROK-BUILD — 无损拒绝验证：坏名称、越界、符号链接。不跑 Godot、不录帧。
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RC="$HERE/run_case.sh"
ROOT=/tmp/startup749
PASS=0
FAIL=0

expect_fail() {
  local label=$1; shift
  local out rc
  set +e
  out=$("$RC" "$@" 2>&1)
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "PASS reject: $label (exit $rc)"
    PASS=$((PASS+1))
  else
    echo "FAIL expected reject: $label — got exit 0: $out" >&2
    FAIL=$((FAIL+1))
  fi
}

# Bad / empty / path-like names
expect_fail "empty name" "" 10
expect_fail "dot name" "." 10
expect_fail "dotdot name" ".." 10
expect_fail "path with slash" "A/B" 10
expect_fail "absolute-looking" "/tmp" 10
expect_fail "dotfile" ".hidden" 10
expect_fail "space in name" "A B" 10
expect_fail "semicolon" "A;rm" 10

# Bad frame counts
expect_fail "zero frames" "safe_name" 0
expect_fail "negative frames" "safe_name" -1
expect_fail "non-integer frames" "safe_name" "12x"
expect_fail "empty frames" "safe_name" ""

# Symlink under fixed root: create controlled fixture, expect refuse, then clean
mkdir -p "$ROOT"
SAFE_LINK_TARGET=$(mktemp -d /tmp/startup749_safety_target.XXXXXX)
ln -sfn "$SAFE_LINK_TARGET" "$ROOT/symlink_case"
expect_fail "symlink work dir" "symlink_case" 10
# Cleanup fixture only if still our symlink
if [[ -L "$ROOT/symlink_case" ]]; then
  rm -f "$ROOT/symlink_case"
fi
rmdir "$SAFE_LINK_TARGET" 2>/dev/null || true

# Nested path via crafted existing dir should still be rejected by name rules above;
# extra: if someone pre-creates ROOT/evil as symlink to /, name "evil" with existing symlink is refused
NEST=$(mktemp -d /tmp/startup749_nest.XXXXXX)
ln -sfn "$NEST" "$ROOT/nestlink"
expect_fail "preexisting symlink nestlink" "nestlink" 5
[[ -L "$ROOT/nestlink" ]] && rm -f "$ROOT/nestlink"
rmdir "$NEST" 2>/dev/null || true

echo "verify_run_case_safety: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
