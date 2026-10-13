import hashlib
import json
import subprocess
from pathlib import Path

repo = Path(r'D:\games\youjia-test\assistant').resolve()
backup = Path(r'D:\games\youjia-test\assistant-recovery\find16-generated-metadata-before-main-oct13').resolve()
assert backup.parent == Path(r'D:\games\youjia-test\assistant-recovery').resolve()
assert not backup.exists(), 'Never overwrite a previous snapshot'

def git(*args):
    return subprocess.check_output(['git', '-c', 'core.safecrlf=false', '-C', str(repo), *args])

assert not git('diff', '--cached', '--name-only').strip(), 'Unexpected staged work'
tracked = git('diff', '--name-only', '-z').decode().strip('\0').split('\0')
untracked = git('ls-files', '--others', '--exclude-standard', '-z').decode().strip('\0').split('\0')
tracked = [p for p in tracked if p]
untracked = [p for p in untracked if p]
assert tracked and all(p.endswith('.import') for p in tracked), 'Unexpected tracked edits'
extra_imports = {'assets/holiday/characters/shelter/horse-rest.png.import', 'assets/holiday/characters/shelter/llama-rest.png.import'}
assert all(p.endswith(('.gd.uid', '.gdshader.uid')) or p in extra_imports for p in untracked), 'Unexpected untracked work'
backup.mkdir()
rows = []
for kind, paths in [('tracked', tracked), ('untracked', untracked)]:
    for rel in paths:
        source = (repo / rel).resolve()
        assert repo in source.parents and source.is_file()
        data = source.read_bytes()
        target = (backup / kind / rel).resolve()
        assert backup in target.parents
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        assert target.read_bytes() == data
        rows.append({'kind': kind, 'path': rel, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
(backup / 'context.json').write_text(json.dumps({'source': git('rev-parse', 'HEAD').decode().strip(), 'reason': 'Preserve import/UID output from our previous native Godot run before integrating new main; production/code/docs changes are excluded and would abort this script.', 'files': rows}, ensure_ascii=False, indent=2), encoding='utf-8')
(backup / 'tracked.patch').write_bytes(git('diff', '--', *tracked))
for row in rows:
    source = (repo / row['path']).resolve()
    assert repo in source.parents and hashlib.sha256(source.read_bytes()).hexdigest() == row['sha256'], 'File changed after snapshot'
git('restore', '--worktree', '--', *tracked)
for row in rows:
    if row['kind'] == 'untracked':
        source = (repo / row['path']).resolve()
        assert repo in source.parents and hashlib.sha256(source.read_bytes()).hexdigest() == row['sha256']
        source.unlink()
status = git('status', '--porcelain=v1').decode().strip()
assert not status, status
print(json.dumps({'trackedPreservedAndRestored': len(tracked), 'untrackedPreservedAndRemoved': len(untracked), 'snapshot': str(backup), 'status': 'CLEAN'}))
