import hashlib,json,subprocess
from pathlib import Path
repo=Path(r'D:\games\youjia-test\assistant').resolve()
backup=Path(r'D:\games\youjia-test\assistant-recovery\find16-generated-metadata-b784-oct15').resolve()
assert backup.parent==Path(r'D:\games\youjia-test\assistant-recovery').resolve() and not backup.exists()
def git(*args):return subprocess.check_output(['git','-c','core.safecrlf=false','-C',str(repo),*args])
assert not git('diff','--cached','--name-only').strip()
records=[r for r in git('status','--porcelain=v1','-z').decode().split('\0') if r]
extra_imports={'assets/holiday/characters/shelter/horse-rest.png.import','assets/holiday/characters/shelter/llama-rest.png.import'}
assert all((r.startswith(' M ') and r.endswith('.import')) or (r.startswith('?? ') and (r.endswith(('.gd.uid','.gdshader.uid')) or r[3:] in extra_imports)) for r in records), 'Unexpected work; do not restore it'
backup.mkdir()
rows=[]
for record in records:
    rel=record[3:];kind='untracked' if record.startswith('?? ') else 'tracked'
    source=(repo/rel).resolve();assert repo in source.parents and source.is_file()
    data=source.read_bytes();target=(backup/kind/rel).resolve();assert backup in target.parents
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data);assert target.read_bytes()==data
    rows.append({'kind':kind,'path':rel,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
(backup/'context.json').write_text(json.dumps({'source':git('rev-parse','HEAD').decode().strip(),'scope':'Actual generated import/UID inputs of current native and stamped Web b784 validation, preserved before restoring known metadata; no source art/audio bytes changed.','files':rows},indent=2),encoding='utf-8')
for row in rows:
    source=(repo/row['path']).resolve();assert repo in source.parents and hashlib.sha256(source.read_bytes()).hexdigest()==row['sha256']
tracked=[r['path'] for r in rows if r['kind']=='tracked']
if tracked:git('restore','--worktree','--',*tracked)
for row in rows:
    if row['kind']=='untracked':
        source=(repo/row['path']).resolve();assert repo in source.parents and hashlib.sha256(source.read_bytes()).hexdigest()==row['sha256'];source.unlink()
assert not git('status','--porcelain=v1').strip()
print(json.dumps({'filesPreserved':len(rows),'status':'CLEAN','snapshot':str(backup)}))
