import datetime
import hashlib
import json
import os
import pathlib
import subprocess
import sys

repo = pathlib.Path('/dev/shm/youjia-volume466')
out = pathlib.Path('/dev/shm/volume466-evidence/full-v1')
out.mkdir(exist_ok=False)
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
sha = lambda b: hashlib.sha256(b).hexdigest()
source = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
tree = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD^{tree}'], text=True).strip()
env = os.environ.copy()
env.update({'GODOT': '/tmp/volume466-godot-recorder.py', 'VOLUME466_ENGINE_LEDGER': str(out / 'engine-processes.jsonl')})
rows = []
(out / 'source.json').write_text(json.dumps({'source': source, 'tree': tree, 'started': now(), 'runner_sha256': sha(pathlib.Path(__file__).read_bytes()), 'recorder_sha256': sha(pathlib.Path(env['GODOT']).read_bytes()), 'scope': 'Actual daily native gate plus retention/publisher fixture; no browser or production publication'}, indent=2) + '\n')
for name, command in [('daily', ['bash', 'tools/verify_daily_life.sh']), ('retention', ['python3', 'test/web_bundle_retention_test.py']), ('publish-helper', ['python3', 'test/publish_storage_modules_test.py'])]:
    row = {'name': name, 'command': command, 'started': now()}
    log = out / (name + '.log')
    print('START', name, flush=True)
    with log.open('wb') as stream:
        result = subprocess.run(command, cwd=repo, env=env, stdout=stream, stderr=subprocess.STDOUT)
    row.update({'ended': now(), 'direct_exit': result.returncode, 'log': log.name, 'log_bytes': log.stat().st_size, 'log_sha256': sha(log.read_bytes())})
    rows.append(row)
    (out / 'process-results.json').write_text(json.dumps(rows, indent=2) + '\n')
    print('END', name, 'actual', result.returncode, 'bytes', row['log_bytes'], flush=True)
    if result.returncode != 0:
        (out / 'outer.exit').write_text('1\n')
        print(log.read_text(errors='replace')[-12000:], flush=True)
        sys.exit(1)
(out / 'outer.exit').write_text('0\n')
print('ALL_FULL_PASS', flush=True)
