"""Stamp a local, already exported candidate. No network or publication."""
import datetime, hashlib, json, os, pathlib, re, subprocess, sys

root, output, expected = map(str, sys.argv[1:])
root, output = pathlib.Path(root), pathlib.Path(output)
assert re.fullmatch(r"[a-f0-9]{40}", expected)
assert subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"]).decode().strip() == expected
entry = "game-" + expected[:7]
module_entry = "save-" + expected[:7]
html = (output / "index.html").read_text()
assert '"executable":"index"' in html, "Expected fresh unmodified Godot export"
for path in output.glob("index.*"):
    if path.name == "index.html" or not path.is_file():
        continue
    target = path.with_name(entry + path.name[len("index"):])
    assert not target.exists(), target
    os.link(path, target)
html = html.replace('"executable":"index"', '"executable":"' + entry + '"')
html = html.replace('"index.pck":', '"' + entry + '.pck":')
html = html.replace('"index.wasm":', '"' + entry + '.wasm":')
html = html.replace("script.src = 'index.js'", "script.src = '" + entry + ".js'")
html = html.replace("./web/save/", "./" + module_entry + "/")
html = html.replace("<html", '<html data-build="' + entry + '"', 1)
assert "script.src = '" + entry + ".js'" in html
(output / "index.html").write_text(html)
modules = output / module_entry
modules.mkdir(exist_ok=False)
module_hashes = {}
for path in sorted((root / "web/save").glob("*.mjs")):
    raw = path.read_bytes()
    (modules / path.name).write_bytes(raw)
    module_hashes[path.name] = hashlib.sha256(raw).hexdigest()
manifest = {
    "schema": "youjia.release/v1",
    "scope": "local candidate only; not a public Pages release",
    "sourceCommit": expected,
    "engine": "4.7.2.stable.official.ed1daf0bf",
    "entry": entry,
    "createdAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "storageModules": {"entry": module_entry, "sha256": module_hashes},
}
(output / "game-release.json").write_text(json.dumps(manifest, indent=2) + "\n")
pck = (output / (entry + ".pck")).read_bytes()
record = {"source": expected, "entry": entry, "pck_bytes": len(pck),
          "pck_sha256": hashlib.sha256(pck).hexdigest(), "output": str(output)}
pathlib.Path("/workspace/motion-candidate-release.json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record))
