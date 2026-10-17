from pathlib import Path
import os,subprocess,json,hashlib
root=Path(r'C:/Users/jiangzengming/.codex/worktrees/growth-garden-700/youjia');out=Path(__file__).parent
branch='codex/lead-garden-evidence-700'
parent='1ab59c1113dd0a1c7d55ca9e34cf3f89ab152814'
old=subprocess.run(['git','rev-parse','--verify','refs/heads/'+branch],cwd=root,capture_output=True,text=True)
if old.returncode==0:parent=old.stdout.strip()
env=os.environ.copy();env['GIT_INDEX_FILE']=str(out/'evidence.index')
def git(*args,input=None):return subprocess.check_output(['git',*args],cwd=root,env=env,input=input).decode().strip()
git('read-tree',parent)
count=0
for p in sorted((out/'evidence-ready').rglob('*')):
 if not p.is_file():continue
 name='docs/playtests/2026-10-17-autonomous-garden/'+p.relative_to(out/'evidence-ready').as_posix()
 assert name.startswith('docs/playtests/2026-10-17-autonomous-garden/') and '..' not in name.split('/')
 blob=git('hash-object','-w','--stdin',input=p.read_bytes())
 git('update-index','--add','--cacheinfo','100644',blob,name);count+=1
if (out/'docs-final').exists():
 for p in sorted((out/'docs-final').rglob('*')):
  if not p.is_file():continue
  name=p.relative_to(out/'docs-final').as_posix()
  assert name.startswith('docs/') and '..' not in name.split('/')
  blob=git('hash-object','-w','--stdin',input=p.read_bytes())
  git('update-index','--add','--cacheinfo','100644',blob,name);count+=1
tree=git('write-tree');sha=git('commit-tree',tree,'-p',parent,input=b'docs: CODEX-LEAD #700 autonomous garden runtime evidence\n')
git('update-ref','refs/heads/'+branch,sha,parent if old.returncode==0 else '0'*40)
(out/'evidence-commit.json').write_text(json.dumps({'branch':branch,'sha':sha,'parent':parent,'files':count},indent=2)+'\n')
print('Evidence commit',sha,'files',count,flush=True)
subprocess.run(['git','push','origin','refs/heads/'+branch+':refs/heads/'+branch],cwd=root,check=True)
