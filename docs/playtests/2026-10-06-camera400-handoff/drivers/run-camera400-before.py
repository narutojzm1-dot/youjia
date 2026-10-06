from pathlib import Path
import subprocess, os, json, datetime, hashlib, re

repo = Path('/tmp/youjia-camera400')
evidence = Path('/tmp/camera400-evidence')
state = Path('/tmp/camera400-state')
engine = '/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
assert os.environ.get('CAMERA400_ENGINE_WINDOW') == 'granted'
assert not state.exists()
assert not (evidence / 'process-results.json').exists()
source = json.loads((evidence / 'source.json').read_text())
head = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
assert head == source['test_source']
assert not subprocess.check_output(['git', '-C', str(repo), 'status', '--porcelain'], text=True).strip()
live = []
for line in subprocess.check_output(['ps', '-eo', 'pid,ppid,stat,comm,args'], text=True).splitlines()[1:]:
    fields = line.split(None, 4)
    if len(fields) == 5 and not fields[2].startswith('Z') and ('Godot' in fields[3] or fields[3] in {'chromium', 'chrome', 'firefox'}):
        live.append(line)
assert not live, live
preflight = {'at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'source': source, 'live_engine_browser': live, 'memory_bytes': int(Path('/sys/fs/cgroup/memory.current').read_text()), 'expected_before_fix': 'Actual failing regression assertions are expected; parse/import failure is not reproduction.'}
(evidence / 'preflight.json').write_text(json.dumps(preflight, indent=2) + '\n')
for directory in ['data', 'config', 'cache']:
    (state / directory).mkdir(parents=True)
env = {**os.environ, 'GODOT': engine, 'XDG_DATA_HOME': str(state/'data'), 'XDG_CONFIG_HOME': str(state/'config'), 'XDG_CACHE_HOME': str(state/'cache'), 'YOUJIA_TEST_ISOLATED_DATA': str(state/'data')}
results = []
def step(name, args):
    path = evidence / (name + '.log')
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    with path.open('xb') as stream:
        proc = subprocess.run(args, cwd=repo, env=env, stdout=stream, stderr=subprocess.STDOUT)
    result = {'step': name, 'args': args, 'started_at': started, 'ended_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'returncode': proc.returncode, 'log': str(path), 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    results.append(result)
    (evidence/'process-results.json').write_text(json.dumps(results, indent=2)+'\n')
    print(json.dumps(result), flush=True)
    return proc.returncode, path.read_text(errors='replace')
code, version = step('godot-version', [engine, '--version'])
assert code == 0 and version.strip() == '4.7.2.stable.official.ed1daf0bf'
code, imported = step('import', ['bash', '-c', 'source tools/lib/verified_godot.sh; run_verified_godot /tmp/camera400-evidence/import-engine.log --headless --path . --editor --import --quit'])
assert code == 0, 'Import must succeed before a diagnostic run can count.'
code, log = step('before-fix-suite', ['timeout', '180', engine, '--headless', '--path', '.', '--script', 'res://test/camera400_handoff_suite.gd'])
summary_lines = [line for line in log.splitlines() if line.startswith('[camera400-handoff] ')]
traces = [json.loads(line.removeprefix('CAMERA400_TRACE ')) for line in log.splitlines() if line.startswith('CAMERA400_TRACE ')]
record = {'source': source, 'actual_suite_exit': code, 'completion_lines': summary_lines, 'trace_count': len(traces), 'traces': traces, 'script_errors': [line for line in log.splitlines() if line.startswith('SCRIPT ERROR')], 'before_fix_only': True, 'production_edited': False, 'browser_started': False}
(evidence/'before-fix-result.json').write_text(json.dumps(record, indent=2)+'\n')
print(json.dumps({k:v for k,v in record.items() if k not in {'traces','source'}}, indent=2), flush=True)
# This runner preserves an expected red native result as exit 1, never PASS.
raise SystemExit(code)
