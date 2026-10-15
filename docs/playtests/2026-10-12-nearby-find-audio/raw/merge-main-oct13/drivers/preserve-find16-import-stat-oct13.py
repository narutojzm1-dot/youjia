import hashlib, json, subprocess
from pathlib import Path
repo=Path(r'D:\games\youjia-test\assistant').resolve()
backup=Path(r'D:\games\youjia-test\assistant-recovery\find16-import-stat-before-main-oct13').resolve()
assert backup.parent == Path(r'D:\games\youjia-test\assistant-recovery').resolve() and not backup.exists()
def git(*args): return subprocess.check_output(['git','-c','core.safecrlf=false','-C',str(repo),*args])
records=[r for r in git('status','--porcelain=v1','-z').decode().split('\0') if r]
assert records and all(r.startswith(' M ') and r.endswith('.import') for r in records)
backup.mkdir()
rows=[]
for record in records:
    rel=record[3:]
    path=(repo/rel).resolve()
    assert repo in path.parents and path.is_file()
    data=path.read_bytes()
    saved=(backup/rel).resolve()
    assert backup in saved.parents
    saved.parent.mkdir(parents=True,exist_ok=True)
    saved.write_bytes(data)
    assert saved.read_bytes()==data
    rows.append({'path':rel,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
(backup/'context.json').write_text(json.dumps({'reason':'Git status also reports 143 import stat/line-ending changes with zero content diff; preserve these before restoring only known metadata.', 'source':git('rev-parse','HEAD').decode().strip(),'files':rows},indent=2),encoding='utf-8')
for row in rows:
    path=(repo/row['path']).resolve()
    assert repo in path.parents and hashlib.sha256(path.read_bytes()).hexdigest()==row['sha256']
git('restore','--worktree','--',*[r['path'] for r in rows])
assert not git('status','--porcelain=v1').strip()
print(json.dumps({'preserved':len(rows),'status':'CLEAN','snapshot':str(backup)}))
