#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_SHA="${BASE_SHA:-13374001e3b26ac3b8796da1943b6477f95a412e}"
PATCH="$ROOT/tools/main_hold_hotbar.mount.patch"
OUT="$ROOT/scripts/main.gd"
TMP="$(mktemp)"
curl -fsSL "https://raw.githubusercontent.com/narutojzm1-dot/youjia/${BASE_SHA}/scripts/main.gd" -o "$TMP"
patch -o "$OUT" "$TMP" < "$PATCH"
rm -f "$TMP"
grep -q '_ensure_hold_hotbar' "$OUT"
echo "applied mount to $OUT ($(wc -c < "$OUT") bytes)"
