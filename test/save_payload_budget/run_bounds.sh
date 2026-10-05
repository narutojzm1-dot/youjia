#!/usr/bin/env bash
# #294 bound measurements: escape/double-wrap amplification, dense album, archive model.
# Large candidates are measured offline with a replica of the Host formulas; the
# replica is first checked byte-for-byte against the real pinned Host on small
# samples. Disposable /tmp XDG and Chromium profile only. Exit 1 on any failed check.
#   HOST_SHA  R1 Host commit (default PR251 head); OUT results JSON; KEEP=1 keeps samples
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HOST_SHA=${HOST_SHA:-6e47c3acaea7ab7ecee0e09a1e3634dd8c4fb62e}
OUT=${OUT:-$ROOT/test/save_payload_budget/bounds-evidence.json}
STATE=$(mktemp -d /tmp/youjia-save-bounds.XXXXXX)
[[ "${KEEP:-0}" == 1 ]] || trap 'rm -rf "$STATE"' EXIT
git -C "$ROOT" cat-file -e "$HOST_SHA^{commit}" 2>/dev/null || git -C "$ROOT" fetch -q origin "$HOST_SHA"
[[ $(git -C "$ROOT" rev-parse "$HOST_SHA^{commit}") == "$HOST_SHA" ]] || { echo "HOST_SHA must be a full commit SHA" >&2; exit 2; }
mkdir -p "$STATE/host"
for f in store.mjs legacy_v5.mjs source_decode.mjs bridge.mjs head.html source_snapshot.gd; do
	git -C "$ROOT" show "$HOST_SHA:test/save_recovery_r1/$f" > "$STATE/host/$f"
done
export XDG_DATA_HOME="$STATE/data" XDG_CONFIG_HOME="$STATE/config" XDG_CACHE_HOME="$STATE/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
source "$ROOT/tools/lib/verified_godot.sh"
cd "$ROOT"
run_verified_godot "$STATE/import.log" --headless --path . --editor --import --quit
run_verified_godot "$STATE/generate.log" --headless --path . --script res://test/save_payload_budget/generate_bounds.gd \
	-- --out "$STATE/samples" --host-snapshot "$STATE/host/source_snapshot.gd"
"${PYTHON:-python3}" "$ROOT/test/save_payload_budget/bounds_model.py" --samples "$STATE/samples" --host "$STATE/host" \
	--host-sha "$HOST_SHA" --repo-head "$(git -C "$ROOT" rev-parse HEAD)" --out "$OUT"
