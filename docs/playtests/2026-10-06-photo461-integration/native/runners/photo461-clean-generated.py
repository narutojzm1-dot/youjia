from pathlib import Path
import subprocess,json,hashlib,os
repo=Path('/tmp/youjia-photo461');evidence=Path('/tmp/photo461-evidence')
assert (evidence/'run.exit').read_text().strip()=='0'
assert (evidence/'outer.exit').read_text().strip()=='0'
def g(*args):return subprocess.check_output(['git','-C',str(repo),*args])
changed=g('diff','--name-only').decode().splitlines();unexpected=[x for x in changed if not x.endswith('.import')];assert not unexpected,unexpected
(evidence/'generated-import-only.diff').write_bytes(g('diff','--',*changed)if changed else b'')
(evidence/'generated-import-files.json').write_text(json.dumps(changed,indent=2)+'\n')
if changed:subprocess.run(['git','-C',str(repo),'restore','--worktree','--',*changed],check=True)
tracked=set(g('ls-files','-z').decode().split('\0'));untracked=[p for p in g('ls-files','--others','--exclude-standard','-z').decode().split('\0')if p]
removed=[];unknown=[]
for rel in untracked:
 p=repo/rel
 if rel.endswith('.gd.uid') and rel[:-4] in tracked:
  data=p.read_bytes();removed.append({'path':rel,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'text':data.decode()});p.unlink()
 else:unknown.append(rel)
(evidence/'generated-uids-cleaned.json').write_text(json.dumps({'removed':removed,'unrecognized_left_untouched':unknown},indent=2)+'\n')
assert not unknown,unknown
assert not g('status','--porcelain')
(evidence/'post-clean-status.txt').write_text(g('status','--short').decode())
print('restored automatic imports',len(changed),'removed generated UID files',len(removed),'status clean')
