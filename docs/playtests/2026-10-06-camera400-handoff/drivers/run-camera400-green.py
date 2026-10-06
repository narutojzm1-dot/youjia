from pathlib import Path
import subprocess, os, json, datetime, hashlib

repo = Path('/tmp/youjia-camera400')
evidence = Path('/tmp/camera400-evidence/green-specialized')
state = Path('/tmp/camera400-green-state')
engine = '/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
assert os.environ.get('CAMERA400_ENGINE_WINDOW') == 'granted'
evidence.mkdir(exist_ok=False)
assert not state.exists()
source = json.loads(Path('/tmp/camera400-evidence/fixed-source.json').read_text())
assert subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip() == source['fixed_source']
live = []
for line in subprocess.check_output(['ps', '-eo', 'pid,ppid,stat,comm,args'], text=True).splitlines()[1:]:
    fields = line.split(None, 4)
    if len(fields) == 5 and not fields[2].startswith('Z') and ('Godot' in fields[3] or fields[3] in {'chromium', 'chrome', 'firefox'}):
        live.append(line)
assert not live, live
(evidence/'preflight.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':source['fixed_source'],'live_engine_browser':live,'memory_bytes':int(Path('/sys/fs/cgroup/memory.current').read_text())},indent=2)+'\n')
results=[]
def step(name,args):
    suite_state=state/name
    for directory in ['data','config','cache']:(suite_state/directory).mkdir(parents=True)
    env={**os.environ,'GODOT':engine,'XDG_DATA_HOME':str(suite_state/'data'),'XDG_CONFIG_HOME':str(suite_state/'config'),'XDG_CACHE_HOME':str(suite_state/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(suite_state/'data')}
    log=evidence/(name+'.log');started=datetime.datetime.now(datetime.timezone.utc).isoformat()
    with log.open('xb') as stream:proc=subprocess.run(args,cwd=repo,env=env,stdout=stream,stderr=subprocess.STDOUT)
    record={'step':name,'args':args,'started_at':started,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'returncode':proc.returncode,'log':str(log),'sha256':hashlib.sha256(log.read_bytes()).hexdigest()};results.append(record)
    (evidence/'process-results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(record),flush=True)
    assert proc.returncode==0,name+' did not pass; retain original log'
    return log.read_text(errors='replace')
step('gate-contract',['bash','test/godot_gate_test.sh'])
for suite in ['camera400_handoff','quiet_sky_look','goose_mount','quiet_stay','motion_preference']:
    command='source tools/lib/verified_godot.sh; run_verified_godot_suite '+str(evidence/(suite+'-engine.log'))+' test/'+suite+'_suite.gd --headless --path .'
    text=step(suite,['bash','-c',command])
    if suite=='camera400_handoff':
        assert text.splitlines().count('[camera400-handoff] PASS: 160 checks []')==1
        traces=[json.loads(line.removeprefix('CAMERA400_TRACE ')) for line in text.splitlines() if line.startswith('CAMERA400_TRACE ')]
        (evidence/'camera400-traces.json').write_text(json.dumps(traces,indent=2)+'\n')
(evidence/'result.json').write_text(json.dumps({'status':'passed','source':source['fixed_source'],'camera_checks':160,'test_body_same_as_before_fix':True,'processes':results,'full_daily_export':'pending exact PR464 integration','browser_executed':False},indent=2)+'\n')
print('SPECIALIZED_GREEN_COMPLETE exit0',flush=True)
