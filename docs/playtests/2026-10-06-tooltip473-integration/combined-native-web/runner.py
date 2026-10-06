from pathlib import Path
import subprocess,json,os,datetime,hashlib,re,sys,shutil
repo=Path('/dev/shm/youjia-tooltip473');out=Path('/dev/shm/tooltip473-combined-run');state=Path('/dev/shm/tooltip473-combined-state');export=Path('/dev/shm/tooltip473-web')
source='a0a856f64e7764fbab5270412025e62b8e34cafd';tree='0945747d4680e899bbfe5253a60ca5c0f8cf92e1';binary='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat();hash256=lambda b:hashlib.sha256(b).hexdigest()
def g(*a):return subprocess.check_output(['git','-C',str(repo),*a])
assert g('rev-parse','HEAD').decode().strip()==source and g('rev-parse','HEAD^{tree}').decode().strip()==tree
out.mkdir(exist_ok=False);state.mkdir(exist_ok=False);export.mkdir(exist_ok=False)
live=[]
for line in subprocess.check_output(['ps','-eo','pid,stat,comm'],text=True).splitlines()[1:]:
 p=line.split();
 if len(p)>2 and not p[1].startswith('Z') and ('Godot' in p[2] or p[2] in ['chrome','chromium','firefox']):live.append(line)
assert not live,live
mismatches=[];checked=[]
for entry in g('ls-tree','-rz','HEAD').split(b'\0'):
 if not entry:continue
 meta,n=entry.split(b'\t',1);mode,kind,expected=meta.decode().split();name=n.decode()
 if name.startswith(('docs/','.github/')):continue
 p=repo/name;assert p.is_file(),name;data=p.read_bytes();actual=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 checked.append({'path':name,'expected_git_blob':expected,'actual_git_blob':actual,'bytes':len(data)})
 if actual!=expected:mismatches.append(name)
assert all(x.endswith('.import') for x in mismatches),mismatches
(out/'preflight-files.json').write_text(json.dumps({'source':source,'tree':tree,'files':checked,'generated_import_metadata_differs':mismatches,'keep_generated_until_export':True},indent=2)+'\n')
(out/'preflight.json').write_text(json.dumps({'source':source,'tree':tree,'started':now(),'live_engine_browser':live,'memory':int(Path('/sys/fs/cgroup/memory.current').read_text()),'camera_dependency_status':'4598 frozen candidate, not yet merged','readonly_candidate_combination':json.loads(Path('/dev/shm/tooltip473-combination/combination.json').read_text())},indent=2)+'\n')
recorder=out/'godot-recorder.py';recorder.write_text('''#!/usr/bin/env python3
import subprocess,os,sys,json,datetime
from pathlib import Path
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
start=now()
code=subprocess.run(['/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64',*sys.argv[1:]]).returncode
row={'args':sys.argv[1:],'started':start,'ended':now(),'direct_exit':code,'phase':os.environ.get('TOOLTIP473_PHASE'),'isolated_data':os.environ.get('XDG_DATA_HOME')}
with Path(os.environ['TOOLTIP473_PROCESS_LOG']).open('a') as f:f.write(json.dumps(row)+'\\n')
sys.exit(code)
''');recorder.chmod(0o755)
env=os.environ.copy();env.update({'GODOT':str(recorder),'TOOLTIP473_PROCESS_LOG':str(out/'engine-processes.jsonl'),'TOOLTIP473_PHASE':'daily','XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(state/'data')})
for k in ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME']:Path(env[k]).mkdir(parents=True,exist_ok=True)
link=state/'data/godot/export_templates';link.parent.mkdir(parents=True,exist_ok=True);link.symlink_to('/tmp/262-export-state/data/godot/export_templates',target_is_directory=True)
results=[]
def step(name,cmd,extra=None):
 start=now();print('START',name,start,flush=True);log=out/(name+'.log')
 with log.open('wb') as f:r=subprocess.run(cmd,cwd=repo,env={**env,**(extra or {})},stdout=f,stderr=subprocess.STDOUT)
 row={'name':name,'command':cmd,'started':start,'ended':now(),'direct_exit':r.returncode,'log':name+'.log','sha256':hash256(log.read_bytes())};results.append(row);(out/'process-results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(row),flush=True)
 assert r.returncode==0,(name,r.returncode)
 return log.read_text(errors='replace')
try:
 daily=step('daily',['bash','tools/verify_daily_life.sh'])
 procs=[json.loads(s) for s in (out/'engine-processes.jsonl').read_text().splitlines()];suite_procs=[p for p in procs if any('res://test/' in x for x in p['args'])];assert len(procs)==81 and len(suite_procs)==80,(len(procs),len(suite_procs));assert all(p['direct_exit']==0 for p in procs)
 for marker in ['PASS: paper_tooltip_style 104 checks','PASS: paper_tooltip_interaction 230 checks','GODOT GATE CONTRACT PASS 124','TOOLTIP473 COMPLETION CONTRACT PASS 28','VOLUME466 COMPLETION CONTRACT PASS 28']:
  assert daily.splitlines().count(marker)==1,marker
 assert sum(s.startswith('Loading shell PASS:') for s in daily.splitlines())==1
 assert sum(s.startswith('MOTION PREFERENCE JS PASS ') for s in daily.splitlines())==1
 step('retention',[sys.executable,'test/web_bundle_retention_test.py'])
 step('publisher-fixture',[sys.executable,'test/publish_storage_modules_test.py'])
 # Retain generated/import metadata until this release export has completed.
 step('export',['bash','-euo','pipefail','-c','source tools/lib/verified_godot.sh; run_verified_godot "$1" --headless --path . --export-release Web "$2"','tooltip473',str(out/'export-engine.log'),str(export/'index.html')],{'TOOLTIP473_PHASE':'export'})
 for name in ['index.html','index.js','index.wasm','index.pck']:assert (export/name).stat().st_size>0,name
 shutil.copytree(repo/'web/save',export/'web/save');shutil.copyfile(repo/'site/open-source-licenses.html',export/'open-source-licenses.html')
 files={str(p.relative_to(export)):{'bytes':p.stat().st_size,'sha256':hash256(p.read_bytes())} for p in sorted(export.rglob('*')) if p.is_file()}
 manifest={'schema':'youjia.candidate/v1','source':source,'sourceCommit':source,'sourceTree':tree,'entry':'index','candidateOnly':True,'createdAt':now(),'engine':'4.7.2.stable.official.ed1daf0bf','files':files,'storageModules':{'entry':'web/save','sha256':{p.name:hash256(p.read_bytes()) for p in sorted((export/'web/save').glob('*.mjs'))}}};assert len(manifest['storageModules']['sha256'])==10
 (export/'game-release.json').write_text(json.dumps(manifest,indent=2)+'\n');(out/'candidate-preview-release.json').write_bytes((export/'game-release.json').read_bytes())
 report={'status':'passed','source':source,'tree':tree,'daily_actual_launches':len(procs),'daily_actual_suites':len(suite_procs),'native_tooltip_style_checks':104,'native_tooltip_interaction_checks':230,'mock_total':124,'new_tooltip_mocks':28,'node_programs':2,'processes':results,'candidate_only':True,'camera_dependency':'4598 candidate, not stated merged','browser_started':False,'closed_at':now(),'pck':files['index.pck'],'manifest_sha256':hash256((export/'game-release.json').read_bytes())};(out/'result.json').write_text(json.dumps(report,indent=2)+'\n');(out/'outer.exit').write_text('0\n');print('COMBINED_CLOSED',json.dumps(report),flush=True)
except BaseException as error:
 (out/'failure.json').write_text(json.dumps({'error':repr(error),'closed_at':now(),'processes':results},indent=2)+'\n');(out/'outer.exit').write_text('1\n');raise
