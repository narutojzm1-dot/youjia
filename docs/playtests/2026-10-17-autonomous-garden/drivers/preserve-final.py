from pathlib import Path
import os,subprocess,json,hashlib,zipfile,shutil,datetime
out=Path(__file__).parent;root=Path(r'C:/Users/jiangzengming/.codex/worktrees/growth-garden-700/youjia')
backup=Path(r'D:/work/migration/youjia-migration-20261015/leader-garden-20261018')
backup.mkdir(parents=True,exist_ok=True)
record=backup/'preservation.json'
assert not record.exists(),'Already preserved; inspect record instead of duplicate stashing'
assert json.loads((out/'public-files/audit.json').read_text())['pass']
assert json.loads((out/'web-public/result.json').read_text())['pass']
def git(*args):return subprocess.check_output(['git',*args],cwd=root).decode().strip()
def checked(command,cwd=None):
 result=subprocess.run(command,cwd=cwd,capture_output=True)
 if result.returncode:raise RuntimeError(result.stdout.decode(errors='replace')+result.stderr.decode(errors='replace'))
 return result
rows=[r for r in subprocess.check_output(['git','status','--porcelain=v1','-z','--untracked-files=all'],cwd=root).decode().split('\0') if r]
allowed=('config/build_identity.json','web/loading.html')
def generated(n):return n.endswith(('.import','.uid','.translation','.pyc')) or n in allowed or n.startswith('test/photo_writer_epoch/old-')
assert all(generated(row[3:]) for row in rows),[row for row in rows if not generated(row[3:])]
files=[];archive=backup/'generated-working-files.zip'
anchor='refs/codex-migration/garden-generated-20261018'
existing=subprocess.run(['git','rev-parse','--verify',anchor],cwd=root,capture_output=True,text=True)
if existing.returncode==0:
 assert archive.is_file() and not rows,'Resume only the preserved clean worktree'
 statuses={r[3:]:r[:2] for r in json.loads((out/'generated-worktree-status.json').read_text())}
 with zipfile.ZipFile(archive) as z:
  for name in z.namelist():
   data=z.read(name);assert name in statuses and generated(name)
   files.append({'path':name,'git_status':statuses[name],'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
 before=None;after=existing.stdout.strip()
else:
 with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for row in rows:
   name=row[3:];p=root/name
   if not p.is_file():continue
   data=p.read_bytes();z.writestr(name,data)
   files.append({'path':name,'git_status':row[:2],'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
 previous=subprocess.run(['git','rev-parse','--verify','refs/stash'],cwd=root,capture_output=True,text=True)
 before=previous.stdout.strip() if previous.returncode==0 else None
 checked(['git','-c','core.autocrlf=false','stash','push','--include-untracked','-m','CODEX-LEAD migration garden700 generated imports 20261018'],cwd=root)
 after=git('rev-parse','--verify','refs/stash');assert after!=before
 git('update-ref',anchor,after)
with zipfile.ZipFile(archive) as z:
 for item in files:assert hashlib.sha256(z.read(item['path'])).hexdigest()==item['sha256']
assert not git('status','--porcelain=v1','--untracked-files=all'),'Unpreserved workspace changes remain'
checked(['git','fetch','origin','main'],cwd=root)
bundle=backup/'garden-incremental.bundle'
prerequisite='fbc20456149bf9dfb8e66c3645d5537af77c07d3'
refs=['codex/lead-garden-700','codex/lead-garden-evidence-700','refs/remotes/origin/main',anchor]
if not bundle.exists():checked(['git','bundle','create',str(bundle),*refs,'^'+prerequisite],cwd=root)
checked(['git','bundle','verify',str(bundle)],cwd=root)
verify=backup/'verify.git';checked(['git','init','--bare',str(verify)])
common=Path(git('rev-parse','--path-format=absolute','--git-common-dir'))
(verify/'objects/info').mkdir(parents=True,exist_ok=True)
(verify/'objects/info/alternates').write_bytes(((common/'objects').as_posix()+'\n').encode('utf8'))
checked(['git','--git-dir',str(verify),'update-ref','refs/prerequisite/base',prerequisite])
checked(['git','--git-dir',str(verify),'bundle','unbundle',str(bundle)])
shutil.copytree(out/'evidence-ready',backup/'evidence',dirs_exist_ok=True)
shutil.copytree(out/'public-files',backup/'public-files',dirs_exist_ok=True)
private=backup/'private-automation';private.mkdir(exist_ok=True)
base=Path(r'C:/Users/jiangzengming/.codex/automations/automation')
for name in ['automation.toml','project-mail-state.json','prompt-maintenance-state.json','continuation-20261017-garden700.json']:
 if (base/name).is_file():shutil.copyfile(base/name,private/name)
data={'recorded_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'prerequisite_commit':prerequisite,'incremental_not_empty_clone':True,'prerequisite_verification':'exact prior commit available through existing local object-cache alternates; actual bundle unbundle; not empty repository full history','bundle':bundle.name,'bundle_bytes':bundle.stat().st_size,'bundle_sha256':hashlib.sha256(bundle.read_bytes()).hexdigest(),'refs':{r:git('rev-parse',r) for r in refs},'metadata_zip':archive.name,'metadata_zip_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'metadata_files':files,'stash_before':before,'stash_after':after,'stash_untracked_parent':after+'^3','source_workspace_clean':True,'excluded_rebuild_cache_and_browser_profiles':True,'original_migration_backups_unchanged':True}
record.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(backup/'RESTORE.txt').write_text('Supplement only. Keep the complete original migration folder. This bundle requires '+prerequisite+' and is not an empty-clone repository. Import bundle into a repository containing that prerequisite; inspect advertised refs with git bundle list-heads. Source and evidence are also on remote branches. Generated tracked/untracked import artifacts are preserved in the exact raw ZIP, SHA256 list and anchored stash (untracked third parent). Extract only after reviewing paths in a chosen checkout. private-automation contains dedup/continuation state, not browser profiles. The old 3f02f0b484 migration snapshot remains local and is not uploaded by this supplement.\n',encoding='utf8')
print(json.dumps({'backup':str(backup),'bundle_bytes':data['bundle_bytes'],'raw_generated_files':len(files),'stash':after,'clean':True}))
