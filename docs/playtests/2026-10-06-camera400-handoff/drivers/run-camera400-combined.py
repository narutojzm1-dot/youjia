from pathlib import Path
import subprocess, json, os, datetime, hashlib, sys, re
repo=Path('/tmp/youjia-camera400');evidence=Path('/tmp/camera400-evidence/combined');state=Path('/tmp/camera400-combined-state');export=Path('/tmp/camera400-web');engine='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
assert os.environ.get('CAMERA400_ENGINE_WINDOW')=='granted';evidence.mkdir(exist_ok=False);assert not state.exists();export.mkdir(exist_ok=False)
source=json.loads(Path('/tmp/camera400-evidence/combined-source.json').read_text());assert subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip()==source['source'];assert not subprocess.check_output(['git','-C',str(repo),'status','--porcelain'],text=True).strip()
live=[]
for line in subprocess.check_output(['ps','-eo','pid,ppid,stat,comm,args'],text=True).splitlines()[1:]:
 p=line.split(None,4)
 if len(p)==5 and not p[2].startswith('Z') and ('Godot' in p[3] or p[3] in {'chromium','chrome','firefox'}):live.append(line)
assert not live,live
(evidence/'preflight.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':source,'live_engine_browser':live,'memory_bytes':int(Path('/sys/fs/cgroup/memory.current').read_text())},indent=2)+'\n')
for name in ['data','config','cache']:(state/name).mkdir(parents=True)
env={**os.environ,'GODOT':engine,'XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(state/'data')};results=[]
def step(name,args,overrides=None):
 log=evidence/(name+'.log');started=datetime.datetime.now(datetime.timezone.utc).isoformat()
 with log.open('xb') as stream:proc=subprocess.run(args,cwd=repo,env={**env,**(overrides or {})},stdout=stream,stderr=subprocess.STDOUT)
 row={'step':name,'args':args,'started_at':started,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':proc.returncode,'log':str(log),'bytes':log.stat().st_size,'sha256':hashlib.sha256(log.read_bytes()).hexdigest()};results.append(row);(evidence/'process-results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(row),flush=True)
 assert proc.returncode==0,name+' failed, retain log'
 return log.read_text(errors='replace')
try:
 daily=step('daily',['bash','tools/verify_daily_life.sh']);launches=sum(s.startswith('Godot Engine v4.7.2.stable.official.ed1daf0bf') for s in daily.splitlines());assert launches==76,launches
 for marker in ['[camera400-handoff] PASS: 202 checks []','[photo-arrival-shutter-paper] PASS: 1290 checks','[photo-arrival-mat] PASS: 550 checks','PASS: soft_button_disabled 4400 checks','GODOT GATE CONTRACT PASS 64','CAMERA400 COMPLETION CONTRACT PASS 14']:
  assert daily.splitlines().count(marker)==1,marker
 assert sum(s.startswith('Loading shell PASS:') for s in daily.splitlines())==1
 assert sum(s.startswith('MOTION PREFERENCE JS PASS ') for s in daily.splitlines())==1
 step('retention',[sys.executable,'test/web_bundle_retention_test.py'])
 step('publisher-fixture',[sys.executable,'test/publish_storage_modules_test.py'])
 step('export',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /tmp/camera400-evidence/combined/export-engine.log --headless --path . --export-release Web /tmp/camera400-web/index.html'],{'XDG_DATA_HOME':'/tmp/262-export-state/data'})
 for name in ['index.html','index.js','index.wasm','index.pck']:assert (export/name).stat().st_size>0,name
 manifest={'candidateOnly':True,'sourceCommit':source['source'],'sourceTree':source['tree'],'entry':'index','createdAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(export.iterdir()) if p.is_file()}}
 (evidence/'candidate-release.json').write_text(json.dumps(manifest,indent=2)+'\n');(export/'candidate-release.json').write_text(json.dumps(manifest,indent=2)+'\n')
 report={'status':'passed','source':source,'daily_suites':75,'daily_engine_launches':76,'native_camera_checks':202,'mock_total':64,'mock_new_camera_format':14,'node_programs':2,'processes':results,'candidate_only':True,'browser_started':False,'independent_review':'pending'}
 (evidence/'result.json').write_text(json.dumps(report,indent=2)+'\n');(evidence/'outer.exit').write_text('0\n');print('COMBINED_COMPLETE exit0',flush=True)
except BaseException as error:
 (evidence/'failure.json').write_text(json.dumps({'error':repr(error),'processes':results},indent=2)+'\n');(evidence/'outer.exit').write_text('1\n');raise
