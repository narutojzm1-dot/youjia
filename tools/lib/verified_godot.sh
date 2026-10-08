#!/usr/bin/env bash
# Import/export and other tooling only have a process/log contract. Daily tests
# must use run_verified_godot_suite so exit 0 alone cannot mean suite completion.
run_verified_godot() {
  local log_file="$1"
  shift
  _run_verified_godot "$log_file" '' "$@"
}

# Bind the expected completion line to the actual Godot entry we execute. Keep
# common engine options (e.g. --path) in "$@"; append the registered entry here.
run_verified_godot_suite() {
  local log_file="$1" entry="${2#res://}"
  shift 2
  local map_file pattern
  map_file="$(dirname "${BASH_SOURCE[0]}")/godot_suite_completions.tsv"
  if ! pattern="$(awk -F '\t' -v entry="$entry" '
    /^#/ || /^$/ { next }
    NF != 2 { invalid = 1 }
    $1 == entry { count++; pattern = $2 }
    END {
      if (invalid || count != 1 || pattern == "") exit 1
      print pattern
    }
  ' "$map_file")"; then
    printf '[daily-check] No unique completion contract for %s\n' "$entry" >&2
    return 1
  fi
  case "$entry" in
    *.gd) _run_verified_godot "$log_file" "$pattern" "$@" --script "res://$entry" ;;
    *.tscn) _run_verified_godot "$log_file" "$pattern" "$@" "res://$entry" ;;
    *) printf '[daily-check] Unsupported suite entry: %s\n' "$entry" >&2; return 1 ;;
  esac
}

# Run in a subshell so callers retain their shell options and pipeline state.
_run_verified_godot() (
  local log_file="$1" completion_pattern="$2"
  shift 2
  set +e
  timeout 300 "${GODOT:-godot}" "$@" 2>&1 | tee "$log_file"
  local statuses=("${PIPESTATUS[@]}")
  if (( statuses[0] != 0 || statuses[1] != 0 )); then
    printf '[daily-check] Godot/timeout exit=%s; tee exit=%s\n' "${statuses[0]}" "${statuses[1]}" >&2
    exit 1
  fi
  # Do not use grep -q: inspect the whole log, including failures after a PASS.
  grep -E '^(SCRIPT ERROR|ERROR:)|(^|[[:space:]])FAIL([[:space:]:]|$)' "$log_file" > /dev/null
  local scan_status=$?
  if (( scan_status == 0 )); then
    echo '[daily-check] Godot reported an error or failed assertion' >&2
    exit 1
  fi
  if (( scan_status != 1 )); then
    echo '[daily-check] Cannot inspect Godot verification log' >&2
    exit 1
  fi
  if [[ -n "$completion_pattern" ]]; then
    grep -Ex -- "$completion_pattern" "$log_file" > /dev/null
    local completion_status=$?
    if (( completion_status == 1 )); then
      echo '[daily-check] Missing successful suite completion line' >&2
      exit 1
    fi
    if (( completion_status != 0 )); then
      echo '[daily-check] Cannot inspect suite completion line' >&2
      exit 1
    fi
  fi
  exit 0
)
