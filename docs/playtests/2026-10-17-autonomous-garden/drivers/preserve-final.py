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
rows=[r for r in subprocess.check_output(['git','status','--porcelain=v1','-z','--untracked-files=all'],cwd=root).decode().split('\0') if r]
allowed=('config/build_identity.json','web/loading.html')
def generated(n):return n.endswith(('.import','.uid','.translation','.pyc')) or n in allowed or n.startswith('test/photo_writer_epoch/old-')
assert all(generated(row[3:]) for row in rows),[row for row in rows if not generated(row[3:])]
files=[];archive=backup/'generated-working-files.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for row in rows:
  name=row[3:];p=root/name
  if not p.is_file():continue
  data=p.read_bytes();z.writestr(name,data)
  files.append({'path':name,'git_status':row[:2],'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
with zipfile.ZipFile(archive) as z:
 for item in files:assert hashlib.sha256(z.read(item['path'])).hexdigest()==item['sha256']
before=git('rev-parse','--verify','refs/stash')
subprocess.run(['git','stash','push','--include-untracked','-m','CODEX-LEAD migration garden700 generated imports 20261018'],cwd=root,check=True)
after=git('rev-parse','--verify','refs/stash');assert after!=before
anchor='refs/codex-migration/garden-generated-20261018';git('update-ref',anchor,after)
assert not git('status','--porcelain=v1','--untracked-files=all'),'Unpreserved workspace changes remain'
subprocess.run(['git','fetch','origin','main'],cwd=root,check=True)
bundle=backup/'garden-incremental.bundle'
prerequisite='fbc20456149bf9dfb8e66c3645d5537af77c07d3'
refs=['codex/lead-garden-700','codex/lead-garden-evidence-700','refs/remotes/origin/main',anchor]
subprocess.run(['git','bundle','create',str(bundle),*refs,'^'+prerequisite],cwd=root,check=True)
subprocess.run(['git','bundle','verify',str(bundle)],cwd=root,check=True)
verify=backup/'verify.git';subprocess.run(['git','init','--bare',str(verify)],check=True,stdout=subprocess.DEVNULL)
subprocess.run(['git','--git-dir',str(verify),'fetch',str(root),prerequisite+':refs/prerequisite/base'],check=True)
subprocess.run(['git','--git-dir',str(verify),'bundle','unbundle',str(bundle)],check=True,stdout=subprocess.DEVNULL)
shutil.copytree(out/'evidence-ready',backup/'evidence',dirs_exist_ok=True)
shutil.copytree(out/'public-files',backup/'public-files',dirs_exist_ok=True)
private=backup/'private-automation';private.mkdir(exist_ok=True)
base=Path(r'C:/Users/jiangzengming/.codex/automations/automation')
for name in ['automation.toml','project-mail-state.json','prompt-maintenance-state.json','continuation-20261017-garden700.json']:
 if (base/name).is_file():shutil.copyfile(base/name,private/name)
data={'recorded_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'prerequisite_commit':prerequisite,'incremental_not_empty_clone':True,'prerequisite_verification':'seeded exact prior public/main commit from existing local cache, then actual bundle unbundle; not empty repository full history','bundle':bundle.name,'bundle_bytes':bundle.stat().st_size,'bundle_sha256':hashlib.sha256(bundle.read_bytes()).hexdigest(),'refs':{r:git('rev-parse',r) for r in refs},'metadata_zip':archive.name,'metadata_zip_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'metadata_files':files,'stash_before':before,'stash_after':after,'stash_untracked_parent':after+'^3','source_workspace_clean':True,'excluded_rebuild_cache_and_browser_profiles':True,'original_migration_backups_unchanged':True}
record.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(backup/'RESTORE.txt').write_text('Supplement only. Keep the complete original migration folder. This bundle requires '+prerequisite+' and is not an empty-clone repository. Import bundle into a repository containing that prerequisite; inspect advertised refs with git bundle list-heads. Source and evidence are also on remote branches. Generated tracked/untracked import artifacts are preserved in the exact raw ZIP, SHA256 list and anchored stash (untracked third parent). Extract only after reviewing paths in a chosen checkout. private-automation contains dedup/continuation state, not browser profiles. The old 3f02f0b484 migration snapshot remains local and is not uploaded by this supplement.\n',encoding='utf8')
print(json.dumps({'backup':str(backup),'bundle_bytes':data['bundle_bytes'],'raw_generated_files':len(files),'stash':after,'clean':True}))
