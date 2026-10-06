from pathlib import Path
import base64, hashlib, json, os, subprocess

repo = Path('/tmp/youjia-camera400-bounds')
ours = '197db8cdd59a7448de0d6dba3d555af8d25947d1'
base = '8ae57959ff95117047c4362704c298b583d651a7'
main = os.environ['CAMERA400_INTEGRATION_MAIN']
out = Path('/tmp/camera400-bounds-476-integration')
def git(*args, data=None):
    return subprocess.check_output(['git', '-C', str(repo), *args], input=data)
def read(ref, path):
    sha = git('rev-parse', ref + ':' + path).decode().strip()
    proc = subprocess.run(['git', '-C', str(repo), 'cat-file', 'blob', sha], capture_output=True)
    if proc.returncode == 0:
        return proc.stdout
    payload = json.loads(subprocess.check_output(['gh', 'api', 'repos/narutojzm1-dot/youjia/git/blobs/' + sha]))
    raw = base64.b64decode(payload['content'])
    assert git('hash-object', '-w', '--stdin', data=raw).decode().strip() == sha
    return raw
def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
assert git('rev-parse', 'HEAD').decode().strip() == ours
assert not git('status', '--porcelain').decode().strip()
assert git('merge-base', ours, main).decode().strip() == base
out.mkdir(exist_ok=False)
paths = git('diff', '--name-only', base, ours).decode().splitlines()
merged = {}
for path in paths:
    own = read(ours, path)
    if path in ('docs/requirements.md', 'docs/decisions.md'):
        prior = read(base, path)
        assert own.startswith(prior)
        merged[path] = read(main, path) + own[len(prior):]
    elif path == 'tools/verify_daily_life.sh':
        prior, upstream = read(base, path), read(main, path)
        assert own.replace(b'camera400_handoff camera400_backdrop still_catch', b'camera400_handoff still_catch') == prior
        assert upstream.count(b'camera400_handoff still_catch') == 1 and b'camera400_backdrop' not in upstream
        assert b'volume_slider_style volume_slider_input' in upstream
        merged[path] = upstream.replace(b'camera400_handoff still_catch', b'camera400_handoff camera400_backdrop still_catch')
    elif path == 'tools/lib/godot_suite_completions.tsv':
        prior, upstream = read(base, path), read(main, path)
        added = [line for line in own.splitlines(keepends=True) if line.startswith(b'test/camera400_backdrop_suite.gd\t')]
        assert len(added) == 1 and own.replace(added[0], b'') == prior and added[0] not in upstream
        assert upstream.count(b'test/volume_slider_style_suite.gd\t') == 1 and upstream.count(b'test/volume_slider_input_suite.gd\t') == 1
        anchor = next(line for line in upstream.splitlines(keepends=True) if line.startswith(b'test/camera400_handoff_suite.gd\t'))
        merged[path] = upstream.replace(anchor, anchor + added[0])
    elif path == 'test/godot_gate_test.sh':
        prior, upstream = read(base, path), read(main, path)
        start = own.index(b'# The new entry must retain the shared positive-count/empty-failures contract.\n')
        end = own.index(b'# Imports legitimately have no test summary.', start)
        added = own[start:end]
        assert own.replace(added, b'') == prior and b'bounds_entry=' not in upstream
        assert b"VOLUME466 COMPLETION CONTRACT PASS 28" in upstream
        anchor = b'# Imports legitimately have no test summary.'
        assert upstream.count(anchor) == 1
        merged[path] = upstream.replace(anchor, added + anchor)
    else:
        a = subprocess.run(['git', '-C', str(repo), 'rev-parse', base + ':' + path], capture_output=True, text=True)
        b = subprocess.run(['git', '-C', str(repo), 'rev-parse', main + ':' + path], capture_output=True, text=True)
        if a.returncode == 0:
            assert b.returncode == 0 and a.stdout == b.stdout, path
        else:
            assert b.returncode != 0, path
        merged[path] = own
selected = [p[1:] for p in (repo / '.git/info/sparse-checkout').read_text().splitlines() if p.startswith('/')]
upstream_non_docs = git('diff', '--name-only', base, main, '--', ':(exclude)docs/**', ':(exclude)art/**').decode().splitlines()
selected = sorted(set(selected + upstream_non_docs + paths))
git('read-tree', main)
for path, raw in merged.items():
    sha = git('hash-object', '-w', '--stdin', data=raw).decode().strip()
    mode = git('ls-tree', ours, '--', path).decode().split()[0]
    git('update-index', '--add', '--cacheinfo', mode, sha, path)
tree = git('write-tree', '--missing-ok').decode().strip()
head = git('commit-tree', tree, '-p', ours, '-p', main, data=b'Integrate backdrop bounds with reviewed slider and Cloud evidence main\n').decode().strip()
git('update-ref', 'HEAD', head, ours)
all_paths = set(git('ls-tree', '-r', '--name-only', head).decode().splitlines())
git('update-index', '--skip-worktree', '-z', '--stdin', data=b''.join(p.encode() + b'\0' for p in sorted(all_paths)))
for path in selected:
    if path not in all_paths:
        continue
    target = repo / path
    expected = git('rev-parse', head + ':' + path).decode().strip()
    if target.is_file() and blob(target.read_bytes()) == expected:
        continue
    assert not (target.is_file() and target.stat().st_nlink > 1), path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(read(head, path))
    mode = git('ls-tree', head, '--', path).decode().split()[0]
    target.chmod(0o755 if mode == '100755' else 0o644)
(repo / '.git/info/sparse-checkout').write_text(''.join('/' + p + '\n' for p in selected))
git('update-index', '--no-skip-worktree', '-z', '--stdin', data=b''.join(p.encode() + b'\0' for p in selected if p in all_paths))
assert not git('status', '--porcelain').decode().strip()
assert git('diff', '--name-only', main, head).decode().splitlines() == paths
for parent in (ours, main):
    git('merge-base', '--is-ancestor', parent, head)
registries = {'tools/verify_daily_life.sh', 'tools/lib/godot_suite_completions.tsv', 'test/godot_gate_test.sh'}
upstream_blobs = {p: git('rev-parse', main + ':' + p).decode().strip() for p in upstream_non_docs if p not in registries}
assert all(git('rev-parse', head + ':' + p).decode().strip() == sha for p, sha in upstream_blobs.items())
assert git('ls-tree', head, '--', 'tools/verify_daily_life.sh').decode().split()[0] == '100755'
record = {'head': head, 'tree': tree, 'parents': [ours, main], 'main': main, 'merge_base': base, 'upstream_non_docs_preserved': upstream_blobs, 'shared_registries': sorted(registries), 'own_diff_paths': paths, 'expected_daily_suites': 78, 'expected_engine_launches': 79, 'expected_mock_cases': 96, 'combined_native_web': 'pending final actual PR CI; no engine started', 'old_native_browser_source': '58437ae8977f2f0ac1fd51dbdd61e2274ac12132'}
(out / 'integration.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps({k: v for k, v in record.items() if k != 'own_diff_paths'}, indent=2))
