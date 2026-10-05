from pathlib import Path
import os, subprocess, json, hashlib, datetime, sys
repo=Path('/tmp/youjia-soft455'); evidence=Path('/tmp/soft455-evidence'); state=Path('/tmp/soft455-state');export=Path('/tmp/soft455-web')
engine='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
for p in [state/'data',state/'config',state/'cache',export]:p.mkdir(parents=True,exist_ok=True)
env={**os.environ,'GODOT':engine,'XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(state/'data')}
results=[]
def step(name,args,override=None):
 path=evidence/(name+'.log');started=datetime.datetime.now(datetime.timezone.utc).isoformat()
 with path.open('wb') as stream:proc=subprocess.run(args,cwd=repo,env={**env,**(override or {})},stdout=stream,stderr=subprocess.STDOUT)
 result={'step':name,'args':args,'started_at':started,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'returncode':proc.returncode,'log':str(path),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()};results.append(result)
 (evidence/'process-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps(result),flush=True)
 if proc.returncode:raise RuntimeError(name+' returned '+str(proc.returncode))
 return path.read_text(errors='replace')
try:
 version=step('godot-version',[engine,'--version']);assert version.strip()=='4.7.2.stable.official.ed1daf0bf',version
 step('gate-contract',['bash','test/godot_gate_test.sh'])
 step('import',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /tmp/soft455-evidence/import-engine.log --headless --path . --editor --import --quit'])
 specialized=step('specialized',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite /tmp/soft455-evidence/specialized-engine.log test/soft_button_disabled_suite.gd --headless --path .'])
 assert specialized.splitlines().count('PASS: soft_button_disabled 4400 checks')==1,'specialized exact4400 not present once'
 daily=step('daily',['bash','tools/verify_daily_life.sh'])
 count=sum(line.startswith('Godot Engine v4.7.2.stable.official.ed1daf0bf')for line in daily.splitlines())
 assert count==74,f'expected 1import+73suites, observed Godot startup banners {count}'
 assert daily.splitlines().count('PASS: soft_button_disabled 4400 checks')==1,'daily exact4400 missing'
 assert '[photo-arrival-mat] PASS: 550 checks' in daily,'inherited mat550 missing'
 step('web-retention',[sys.executable,'test/web_bundle_retention_test.py'])
 step('storage-publish',[sys.executable,'test/publish_storage_modules_test.py'])
 step('export',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /tmp/soft455-evidence/export-engine.log --headless --path . --export-release Web /tmp/soft455-web/index.html'], {'XDG_DATA_HOME':'/tmp/262-export-state/data'})
 for name in ['index.html','index.js','index.wasm','index.pck']: assert (export/name).stat().st_size>0,name
 source=json.loads((evidence/'source.json').read_text())
 metadata={'schema':'youjia.candidate/v1','candidateOnly':True,'source':source['runtime_source'],'sourceTree':source['tree'],'entry':'index','createdAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(export.iterdir()) if p.is_file()}}
 (export/'candidate-release.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n');(evidence/'candidate-release.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
 (evidence/'validation-result.json').write_text(json.dumps({'status':'passed','engine':version.strip(),'godot_daily_startups':count,'godot_daily_suites':73,'specialized_checks':4400,'source':source,'process_results':results,'candidate_only':True,'browser_started':False,'final_independent_review':'pending'},indent=2)+'\n')
 (evidence/'run.exit').write_text('0\n')
 print('VALIDATION_COMPLETE exit0',flush=True)
except BaseException as error:
 (evidence/'validation-failure.json').write_text(json.dumps({'exception':repr(error),'process_results':results},indent=2)+'\n');(evidence/'run.exit').write_text('1\n');print('VALIDATION_FAILED',repr(error),flush=True);raise
