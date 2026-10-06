import datetime
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys

repo = pathlib.Path('/dev/shm/youjia-volume466')
evidence = pathlib.Path('/dev/shm/volume466-evidence/export-v1')
export = pathlib.Path('/dev/shm/volume466-web-v1')
evidence.mkdir(exist_ok=False)
export.mkdir(exist_ok=False)
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
sha = lambda b: hashlib.sha256(b).hexdigest()
source = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
tree = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD^{tree}'], text=True).strip()
engine = '/tmp/youjia-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
state = evidence / 'profile'
env = os.environ.copy()
env.update({'XDG_DATA_HOME': str(state / 'data'), 'XDG_CONFIG_HOME': str(state / 'config'), 'XDG_CACHE_HOME': str(state / 'cache'), 'YOUJIA_TEST_ISOLATED_DATA': str(state / 'data')})
for key in ['XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME']:
    pathlib.Path(env[key]).mkdir(parents=True, exist_ok=True)
template_link = state / 'data/godot/export_templates'
template_link.parent.mkdir(parents=True, exist_ok=True)
template_link.symlink_to('/home/agent/.local/share/godot/export_templates', target_is_directory=True)
command = [engine, '--headless', '--path', str(repo), '--export-release', 'Web', str(export / 'index.html')]
result = {'source': source, 'tree': tree, 'command': command, 'started': now(), 'runner_sha256': sha(pathlib.Path(__file__).read_bytes()), 'template_directory': str(template_link.resolve()), 'no_previous_frozen_export_mutated': True}
log = evidence / 'export.log'
with log.open('wb') as stream:
    try:
        run = subprocess.run(command, env=env, cwd=repo, stdout=stream, stderr=subprocess.STDOUT, timeout=300)
        code = run.returncode
    except subprocess.TimeoutExpired:
        code = 124
result.update({'ended': now(), 'direct_exit': code, 'log_bytes': log.stat().st_size, 'log_sha256': sha(log.read_bytes())})
scan = subprocess.run(['grep', '-En', r'^(SCRIPT ERROR|ERROR:)|(^|[[:space:]])FAIL([[:space:]:]|$)', str(log)], capture_output=True, text=True)
result.update({'strict_error_scan_exit': scan.returncode, 'strict_error_lines': scan.stdout.splitlines()})
result['required_files'] = {name: {'exists': (export / name).is_file(), 'bytes': (export / name).stat().st_size if (export / name).is_file() else 0} for name in ['index.html', 'index.js', 'index.pck', 'index.wasm']}
ok = code == 0 and scan.returncode == 1 and all(row['bytes'] > 0 for row in result['required_files'].values())
result['strict_export_verified'] = ok
(evidence / 'process-result.json').write_text(json.dumps(result, indent=2) + '\n')
(evidence / 'strict-export.exit').write_text('0\n' if ok else '1\n')
if not ok:
    (evidence / 'outer.exit').write_text('1\n')
    print(log.read_text(errors='replace')[-12000:])
    sys.exit(1)
original_export = {path.name: {'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes())} for path in sorted(export.iterdir()) if path.is_file()}
(evidence / 'original-export-files.json').write_text(json.dumps(original_export, indent=2) + '\n')
shutil.copytree(repo / 'web/save', export / 'web/save')
shutil.copyfile(repo / 'site/open-source-licenses.html', export / 'open-source-licenses.html')
files = {str(path.relative_to(export)): {'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes())} for path in sorted(export.rglob('*')) if path.is_file()}
manifest = {'schema': 'youjia.candidate/v1', 'source': source, 'sourceCommit': source, 'sourceTree': tree, 'entry': 'index', 'candidateOnly': True, 'engine': '4.7.2.stable.official.ed1daf0bf', 'files': files, 'storageModules': {'entry': 'web/save', 'sha256': {path.name: sha(path.read_bytes()) for path in sorted((export / 'web/save').glob('*.mjs'))}}}
(export / 'game-release.json').write_text(json.dumps(manifest, indent=2) + '\n')
(evidence / 'candidate-preview-release.json').write_bytes((export / 'game-release.json').read_bytes())
(evidence / 'freeze.json').write_text(json.dumps({'frozen_at': now(), 'source': source, 'manifest_sha256': sha((export / 'game-release.json').read_bytes()), 'html': files['index.html'], 'pck': files['index.pck'], 'expected_modules': len(manifest['storageModules']['sha256']), 'scope': 'Local candidate actual export plus exact tracked storage modules/license; not a GitHub Pages release'}, indent=2) + '\n')
(evidence / 'outer.exit').write_text('0\n')
print('STRICT_EXPORT_PASS', json.dumps({'source': source, 'pck': files['index.pck'], 'html': files['index.html'], 'export': str(export)}), flush=True)
