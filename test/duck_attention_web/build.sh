#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${GODOT:?}" "${OUT:?}"
original=$(mktemp)
cp project.godot "$original"
trap 'cp "$original" project.godot; rm -f "$original" scripts/duck_attention_observer.gd scripts/duck_attention_observer.gd.uid' EXIT
cp test/duck_attention_web/observer.gd scripts/duck_attention_observer.gd
python3 - <<'PY'
from pathlib import Path
p=Path('project.godot');p.write_text(p.read_text().replace('[autoload]','[autoload]\nDuckAttentionReadback="*res://scripts/duck_attention_observer.gd"'))
PY
mkdir -p "$OUT/web/save"
"$GODOT" --headless --path . --editor --import --quit > "$OUT/import.log" 2>&1
"$GODOT" --headless --path . --export-release Web "$OUT/index.html" > "$OUT/export.log" 2>&1
cp web/save/*.mjs "$OUT/web/save/"
if rg '^(SCRIPT ERROR|ERROR:)' "$OUT/import.log" "$OUT/export.log"; then exit 1; fi
