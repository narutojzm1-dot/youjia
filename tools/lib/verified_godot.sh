#!/usr/bin/env bash
# Run in a subshell so callers retain their shell options and pipeline state.
run_verified_godot() (
  local log_file="$1"
  shift
  set +e
  timeout 300 "${GODOT:-godot}" "$@" 2>&1 | tee "$log_file"
  local statuses=("${PIPESTATUS[@]}")
  if (( statuses[0] != 0 || statuses[1] != 0 )); then
    printf '[daily-check] Godot/timeout exit=%s; tee exit=%s\n' "${statuses[0]}" "${statuses[1]}" >&2
    exit 1
  fi
  grep -Eq '^(SCRIPT ERROR|ERROR:)|(^|[[:space:]])FAIL([[:space:]:]|$)' "$log_file"
  local scan_status=$?
  if (( scan_status == 0 )); then
    echo '[daily-check] Godot reported an error or failed assertion' >&2
    exit 1
  fi
  if (( scan_status != 1 )); then
    echo '[daily-check] Cannot inspect Godot verification log' >&2
    exit 1
  fi
  exit 0
)
