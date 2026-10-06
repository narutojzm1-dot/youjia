from pathlib import Path
import datetime, hashlib, json, subprocess

repo = Path('/tmp/youjia-camera400-bounds')
out = Path('/dev/shm/camera400-bounds-web-v2')
evidence = Path('/tmp/camera400-bounds-evidence')
source = json.loads((evidence / 'prepared-source.json').read_text())
assert (evidence / 'full-v2/outer.exit').read_text().strip() == '0'
assert subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip() == source['source']
live = []
for line in subprocess.check_output(['ps', '-eo', 'pid,stat,comm,args'], text=True).splitlines()[1:]:
    pieces = line.split(None, 3)
    if len(pieces) == 4 and not pieces[1].startswith('Z') and ('Godot' in pieces[2] or pieces[2] in {'chromium', 'chrome', 'firefox'}):
        live.append(line)
assert not live, live
modules = sorted((repo / 'web/save').glob('*.mjs'))
assert len(modules) == 10
for src in [*modules, repo / 'site/open-source-licenses.html']:
    relative = 'web/save/' + src.name if src.suffix == '.mjs' else 'open-source-licenses.html'
    expected = subprocess.check_output(['git', '-C', str(repo), 'show', source['source'] + ':' + str(src.relative_to(repo))])
    assert src.read_bytes() == expected
    target = out / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    assert not target.exists(), target
    target.write_bytes(expected)
files = {str(p.relative_to(out)): {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file() and p.name != 'candidate-release.json'}
metadata = {
    'schema': 'youjia.candidate/v1', 'sourceCommit': source['source'], 'source': source['source'],
    'sourceTree': source['tree'], 'base': source['base'], 'engine': '4.7.2.stable.official.ed1daf0bf',
    'entry': 'index', 'candidateOnly': True, 'createdAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'files': files, 'storageModules': {'entry': 'web/save', 'sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((out / 'web/save').glob('*.mjs'))}},
}
payload = json.dumps(metadata, indent=2) + '\n'
(out / 'candidate-release.json').write_text(payload)
(evidence / 'candidate-release.json').write_text(payload)
print(json.dumps({'source': source['source'], 'tree': source['tree'], 'pck': files['index.pck'], 'moduleCount': len(modules), 'export': str(out), 'no_live_engine_browser': True}, indent=2))
