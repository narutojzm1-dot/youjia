"""Stamp the PCK's own identity before export; never obtain it from latest.json."""
import json
import subprocess
import re
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
notes = json.loads((root / "config/release_notes.json").read_text(encoding="utf-8"))
version, label = notes["version"], notes["label"]
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    raise ValueError("Invalid player version")
# Keep the loading screen and pause menu on the same player-facing version.
shell_path = root / "web/loading.html"
shell = shell_path.read_text(encoding="utf-8")
shell = re.sub(r"const playerVersion = [^;]+;", "const playerVersion = " + json.dumps(version) + ";", shell)
shell = re.sub(r"const playerVersionLabel = [^;]+;", "const playerVersionLabel = " + json.dumps(version + " · " + label, ensure_ascii=False) + ";", shell)
shell_path.write_text(shell, encoding="utf-8")
sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
(root / "config/build_identity.json").write_text(json.dumps({
    "sourceCommit": sha,
    "builtAt": datetime.now(timezone.utc).isoformat(),
}) + "\n", encoding="utf-8")
print("Bundled build identity:", sha)
