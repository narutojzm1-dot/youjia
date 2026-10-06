from pathlib import Path
import hashlib, json, subprocess

repo = Path('/tmp/youjia-camera400-bounds')
out = Path('/tmp/camera400-bounds-mergework')
ours = '58437ae8977f2f0ac1fd51dbdd61e2274ac12132'
base = 'b9f68c3c5c4e70e16cefde9b4400bb1d553ff915'
main = '8ae57959ff95117047c4362704c298b583d651a7'
def git(*args, data=None):
    return subprocess.check_output(['git', '-C', str(repo), *args], input=data)
def read(ref, path):
    return git('show', ref + ':' + path)
def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
assert git('rev-parse', 'HEAD').decode().strip() == ours
assert git('merge-base', ours, main).decode().strip() == base
status = git('status', '--porcelain').decode().splitlines()
assert status == ['?? docs/playtests/2026-10-06-camera400-backdrop/native/'], status
paths = git('diff', '--name-only', base, ours).decode().splitlines()
selected = [p[1:] for p in (repo / '.git/info/sparse-checkout').read_text().splitlines() if p.startswith('/')]
merged = {}
for path in paths:
    own = read(ours, path)
    if path in ('docs/requirements.md', 'docs/decisions.md'):
        previous = read(base, path)
        assert own.startswith(previous)
        merged[path] = read(main, path) + own[len(previous):]
    else:
        old = subprocess.run(['git', '-C', str(repo), 'rev-parse', base + ':' + path], capture_output=True, text=True)
        upstream = subprocess.run(['git', '-C', str(repo), 'rev-parse', main + ':' + path], capture_output=True, text=True)
        if old.returncode == 0:
            assert upstream.returncode == 0 and old.stdout == upstream.stdout, path
        else:
            assert upstream.returncode != 0, path
        merged[path] = own
git('read-tree', main)
for path, data in merged.items():
    sha = git('hash-object', '-w', '--stdin', data=data).decode().strip()
    mode = git('ls-tree', ours, '--', path).decode().split()[0]
    git('update-index', '--add', '--cacheinfo', mode, sha, path)
tree = git('write-tree', '--missing-ok').decode().strip()
head = git('commit-tree', tree, '-p', ours, '-p', main, data=b'Integrate quiet backdrop bounds with current reviewed main\n').decode().strip()
git('update-ref', 'HEAD', head)
all_paths = git('ls-tree', '-r', '--name-only', head).decode().splitlines()
git('update-index', '--skip-worktree', '-z', '--stdin', data=b''.join(x.encode() + b'\0' for x in all_paths))
for path in selected:
    target = repo / path
    if path not in all_paths:
        continue
    expected = git('rev-parse', head + ':' + path).decode().strip()
    if target.is_file() and blob(target.read_bytes()) == expected:
        continue
    assert not (target.is_file() and target.stat().st_nlink > 1), path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(read(head, path))
    mode = git('ls-tree', head, '--', path).decode().split()[0]
    target.chmod(0o755 if mode == '100755' else 0o644)
git('update-index', '--no-skip-worktree', '-z', '--stdin', data=b''.join(x.encode() + b'\0' for x in selected if x in all_paths))
for parent in (ours, main):
    git('merge-base', '--is-ancestor', parent, head)
assert git('diff', '--name-only', main, head).decode().splitlines() == paths
runtime_difference = git('diff', '--name-only', ours, head, '--', 'scripts', 'test', 'tools', 'web', 'site', 'project.godot', 'export_presets.cfg', '.github').decode().splitlines()
expected_cloud = ['scripts/exploration/find_reveal.gd', 'scripts/exploration/near_path_scroll.gd', 'test/exploration_slice_suite.gd']
assert runtime_difference == expected_cloud, runtime_difference
cloud = {p: git('rev-parse', main + ':' + p).decode().strip() for p in expected_cloud}
assert all(git('rev-parse', head + ':' + p).decode().strip() == sha for p, sha in cloud.items())
git('diff', '--check', main, head)
record = {'head': head, 'tree': tree, 'parents': [ours, main], 'runtime_tested_source': ours, 'native_base': base, 'integration_main': main, 'own_paths': paths, 'upstream_cloud_blobs_preserved': cloud, 'runtime_difference_from_tested': runtime_difference, 'combined_validation': 'pending final PR full CI and export; old native remains 584 source', 'engine_started': False, 'browser_started': False}
(out / 'integration.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record, indent=2))
