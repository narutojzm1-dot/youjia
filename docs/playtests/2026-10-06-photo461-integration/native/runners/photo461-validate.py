from pathlib import Path
import os, subprocess, json, hashlib, datetime, sys
repo=Path('/tmp/youjia-photo461'); evidence=Path('/tmp/photo461-evidence'); state=Path('/tmp/photo461-state');export=Path('/tmp/photo461-web')
engine='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
assert os.environ.get('PHOTO461_ENGINE_WINDOW')=='granted','Parent must explicitly grant sole engine window before execution.'
assert not (evidence/'process-results.json').exists(),'Never overwrite a previous actual run; retain failed logs and prepare a separate retry.'
source=json.loads((evidence/'source.json').read_text());head=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip();assert head==source['runtime_source']
live=[]
for line in subprocess.check_output(['ps','-eo','pid,ppid,stat,comm,args'],text=True).splitlines()[1:]:
 p=line.split(None,4)
 if len(p)==5 and not p[2].startswith('Z') and ('Godot' in p[3] or p[3] in {'chromium','chrome','firefox'}):live.append(line)
assert not live,live
preflight={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'live_engine_browser':live,'source_head':head,'memory_bytes':int(Path('/sys/fs/cgroup/memory.current').read_text()),'untracked':subprocess.check_output(['git','-C',str(repo),'ls-files','--others','--exclude-standard'],text=True).splitlines(),'engine_window':'explicit parent grant'}
(evidence/'preflight.json').write_text(json.dumps(preflight,indent=2)+'\n')
for p in [state/'data',state/'config',state/'cache']:p.mkdir(parents=True,exist_ok=True)
export.mkdir(exist_ok=False)
env={**os.environ,'GODOT':engine,'XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(state/'data')}
results=[]
def step(name,args,override=None):
 path=evidence/(name+'.log');started=datetime.datetime.now(datetime.timezone.utc).isoformat()
 with path.open('xb') as stream:proc=subprocess.run(args,cwd=repo,env={**env,**(override or {})},stdout=stream,stderr=subprocess.STDOUT)
 result={'step':name,'args':args,'started_at':started,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'returncode':proc.returncode,'log':str(path),'bytes':path.stat().st_size,'sha256':hashlib.file_digest(path.open('rb'),'sha256').hexdigest()};results.append(result)
 (evidence/'process-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(json.dumps(result),flush=True)
 if proc.returncode:raise RuntimeError(name+' returned '+str(proc.returncode))
 return path.read_text(errors='replace')
try:
 version=step('godot-version',[engine,'--version']);assert version.strip()=='4.7.2.stable.official.ed1daf0bf'
 step('gate-contract',['bash','test/godot_gate_test.sh'])
 step('import',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /tmp/photo461-evidence/import-engine.log --headless --path . --editor --import --quit'])
 specialized=step('specialized',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite /tmp/photo461-evidence/specialized-engine.log test/photo_arrival_shutter_paper_suite.gd --headless --path .'])
 assert specialized.splitlines().count('[photo-arrival-shutter-paper] PASS: 1290 checks')==1,'specialized exact1290 not present once'
 daily=step('daily',['bash','tools/verify_daily_life.sh'])
 count=sum(line.startswith('Godot Engine v4.7.2.stable.official.ed1daf0bf') for line in daily.splitlines());assert count==75,f'expected 1import+74suites, startup banners {count}'
 for marker in ['[photo-arrival-shutter-paper] PASS: 1290 checks','[photo-arrival-mat] PASS: 550 checks','PASS: soft_button_disabled 4400 checks']:
  assert daily.splitlines().count(marker)==1,'daily exact marker missing or duplicate: '+marker
 step('web-retention',[sys.executable,'test/web_bundle_retention_test.py'])
 step('storage-publish',[sys.executable,'test/publish_storage_modules_test.py'])
 step('export',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /tmp/photo461-evidence/export-engine.log --headless --path . --export-release Web /tmp/photo461-web/index.html'],{'XDG_DATA_HOME':'/tmp/262-export-state/data'})
 for name in ['index.html','index.js','index.wasm','index.pck']:assert (export/name).stat().st_size>0,name
 metadata={'schema':'youjia.candidate/v1','candidateOnly':True,'source':source['runtime_source'],'sourceCommit':source['runtime_source'],'sourceTree':source['tree'],'entry':'index','createdAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.file_digest(p.open('rb'),'sha256').hexdigest()} for p in sorted(export.iterdir()) if p.is_file()}}
 (export/'candidate-release.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n');(evidence/'candidate-release.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
 (evidence/'validation-result.json').write_text(json.dumps({'status':'passed','engine':version.strip(),'godot_daily_startups':count,'godot_daily_suites':74,'specialized_checks':1290,'source':source,'process_results':results,'candidate_only':True,'browser_started':False,'final_independent_review':'pending'},indent=2)+'\n');(evidence/'run.exit').write_text('0\n');print('VALIDATION_COMPLETE exit0',flush=True)
except BaseException as error:
 (evidence/'validation-failure.json').write_text(json.dumps({'exception':repr(error),'process_results':results},indent=2)+'\n');(evidence/'run.exit').write_text('1\n');print('VALIDATION_FAILED',repr(error),flush=True);raise
