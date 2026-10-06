from pathlib import Path
import subprocess,os,json,datetime,time,re
r=Path('/tmp/youjia-camera400-bounds');e=Path('/tmp/camera400-bounds-evidence/short-v3');e.mkdir(exist_ok=False);s=Path('/dev/shm/camera400-bounds-state-short-v3');s.mkdir(exist_ok=False)
engine='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64';source=json.load(open('/tmp/camera400-bounds-evidence/prepared-source.json'))
assert os.environ.get('CAMERA400_BOUNDS_SHORT_WINDOW')=='granted'
live=[]
for line in subprocess.check_output(['ps','-eo','pid,stat,comm,args'],text=True).splitlines()[1:]:
 p=line.split(None,3)
 if len(p)==4 and not p[1].startswith('Z') and ('Godot' in p[2] or p[2] in {'chromium','chrome','firefox'}):live.append(line)
assert not live,live
cache=Path('/dev/shm/camera400-bounds-import');assert cache.is_dir() and (r/'.godot').resolve()==cache
for name in ['data','config','cache']:(s/name).mkdir()
env={**os.environ,'XDG_DATA_HOME':str(s/'data'),'XDG_CONFIG_HOME':str(s/'config'),'XDG_CACHE_HOME':str(s/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(s/'data')};results=[]
files=['scripts/main.gd','scripts/game/yard_world.gd'];green={p:(r/p).read_bytes() for p in files}
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def step(name,args,limit):
 start=now();t=time.monotonic()
 with (e/(name+'.log')).open('w') as f:
  proc=subprocess.run(['timeout','--kill-after=5',str(limit),*args],cwd=r,env=env,stdout=f,stderr=subprocess.STDOUT)
 result={'name':name,'direct_exit':proc.returncode,'started':start,'closed':now(),'seconds':time.monotonic()-t};results.append(result);(e/'results.json').write_text(json.dumps({'source':source,'results':results},indent=2)+'\n');print(json.dumps(result),flush=True);return proc.returncode
try:
 for p in files:(r/p).write_bytes(subprocess.check_output(['git','-C',str(r),'show',source['base']+':'+p]))
 red=step('red-old-production',[engine,'--headless','--path',str(r),'--script','test/camera400_backdrop_suite.gd'],80)
 log=(e/'red-old-production.log').read_text()
 assert red==1 and '[camera400-backdrop] FAIL:' in log and 'real camera introduces no paper outside baseline coverage' in log and 'SCRIPT ERROR' not in log, 'red must be real geometric assertion failure, not parse/runtime'
 for p,data in green.items():(r/p).write_bytes(data)
 assert step('green-candidate',[engine,'--headless','--path',str(r),'--script','test/camera400_backdrop_suite.gd'],80)==0
 log=(e/'green-candidate.log').read_text();assert re.search(r'^\[camera400-backdrop\] PASS: [1-9][0-9]* checks \[\]$',log,re.M) and not re.search(r'^(?:SCRIPT ERROR|ERROR):',log,re.M)
 print('SHORT_NATIVE_COMPLETE',flush=True)
finally:
 for p,data in green.items():(r/p).write_bytes(data)
 (e/'window-closed.json').write_text(json.dumps({'closed':now(),'results':results,'production_restored_to_candidate':True,'browser_started':False,'full_gate_run':False,'export_run':False},indent=2)+'\n')
 print('SHORT_NATIVE_WINDOW_CLOSED',now(),flush=True)
