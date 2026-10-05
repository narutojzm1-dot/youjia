#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
out="${1:?output directory required}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
: "${GODOT:?Godot 4.7.2 binary required}"
"$GODOT" --headless --path "$root/idbfs_godot_fixture" --editor --import --quit
"$GODOT" --headless --path "$root/idbfs_godot_fixture" --export-release Web "$out/index.html"
python - "$out/index.html" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1]);s=p.read_text();needle='const engine = new Engine(GODOT_CONFIG);'
assert needle in s
s=s.replace(needle,"if (new URLSearchParams(location.search).has('no-persist')) GODOT_CONFIG.persistentPaths=[];\n"+needle)
s=s.replace('<head>','<head><link rel="icon" href="data:,">')
p.write_text(s)
PY
