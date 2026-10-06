from pathlib import Path
import subprocess, json, os, datetime, hashlib
repo=Path('/tmp/youjia-camera400');evidence=Path('/tmp/camera400-evidence/v2-pair');state=Path('/tmp/camera400-v2-state');engine='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
assert os.environ.get('CAMERA400_ENGINE_WINDOW')=='granted';evidence.mkdir(exist_ok=False);assert not state.exists()
source=json.loads(Path('/tmp/camera400-evidence/v2-source-pair.json').read_text())
def git(*args):return subprocess.check_output(['git','-C',str(repo),*args])
assert git('rev-parse','HEAD').decode().strip()==source['new_red']
live=[]
for line in subprocess.check_output(['ps','-eo','pid,ppid,stat,comm,args'],text=True).splitlines()[1:]:
 p=line.split(None,4)
 if len(p)==5 and not p[2].startswith('Z') and ('Godot' in p[3] or p[3] in {'chromium','chrome','firefox'}):live.append(line)
assert not live,live
(evidence/'preflight.json').write_text(json.dumps({'source':source,'live_engine_browser':live,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat()},indent=2)+'\n')
results=[]
def run(name,args,expected):
 for directory in ['data','config','cache']:(state/name/directory).mkdir(parents=True)
 env={**os.environ,'GODOT':engine,'XDG_DATA_HOME':str(state/name/'data'),'XDG_CONFIG_HOME':str(state/name/'config'),'XDG_CACHE_HOME':str(state/name/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(state/name/'data')}
 log=evidence/(name+'.log');started=datetime.datetime.now(datetime.timezone.utc).isoformat()
 with log.open('xb') as stream:proc=subprocess.run(args,cwd=repo,env=env,stdout=stream,stderr=subprocess.STDOUT)
 text=log.read_text(errors='replace');record={'step':name,'source':git('rev-parse','HEAD').decode().strip(),'args':args,'started_at':started,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':proc.returncode,'expected_exit':expected,'sha256':hashlib.sha256(log.read_bytes()).hexdigest(),'log':str(log),'completion_lines':[s for s in text.splitlines() if s.startswith('[camera400-handoff]') or 'CONTRACT PASS' in s]};results.append(record);(evidence/'process-results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(record),flush=True)
 assert proc.returncode==expected,(name,proc.returncode)
 assert not any(line.startswith('SCRIPT ERROR') for line in text.splitlines())
 traces=[json.loads(line.removeprefix('CAMERA400_TRACE ')) for line in text.splitlines() if line.startswith('CAMERA400_TRACE ')]
 if traces:(evidence/(name+'-traces.json')).write_text(json.dumps(traces,indent=2)+'\n')
 return text
red=run('red-v2',['timeout','180',engine,'--headless','--path','.','--script','res://test/camera400_handoff_suite.gd'],1)
assert '[camera400-handoff] FAIL: 204 checks ' in red
(repo/'scripts/game/yard_world.gd').write_bytes(git('show',source['new_green']+':scripts/game/yard_world.gd'))
git('read-tree',source['new_green']);git('update-ref','HEAD',source['new_green'])
green=run('green-v2',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite /tmp/camera400-evidence/v2-pair/green-engine.log test/camera400_handoff_suite.gd --headless --path .'],0)
assert green.splitlines().count('[camera400-handoff] PASS: 204 checks []')==1
mocks=run('gate-contract-v2',['bash','test/godot_gate_test.sh'],0)
assert 'CAMERA400 COMPLETION CONTRACT PASS 14' in mocks and 'GODOT GATE CONTRACT PASS 64' in mocks
print('PAIR_COMPLETE: original code remains FAIL; fixed code PASS; 14 new format mocks PASS',flush=True)
