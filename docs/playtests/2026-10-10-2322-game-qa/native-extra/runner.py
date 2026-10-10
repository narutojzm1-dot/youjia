import pathlib,subprocess,os,json,datetime,sys
root=pathlib.Path(__file__).resolve().parent
run=root/'native'/(sys.argv[1] if len(sys.argv)>1 else '2026-10-06-1005');run.mkdir(parents=True,exist_ok=True)
probe=run/'profile-probe';probe.mkdir(exist_ok=True)
(probe/'project.godot').write_text('[application]\nconfig/name="youjia-qa-profile-probe"\n',encoding='utf-8')
(probe/'probe.gd').write_text('extends SceneTree\nfunc _initialize():\n\tprint("QA_USER_DIR=", OS.get_user_data_dir())\n\tquit(0)\n',encoding='utf-8')
env=os.environ.copy();env['APPDATA']=(run/'roaming').as_posix();env['LOCALAPPDATA']=(run/'local').as_posix();env['XDG_DATA_HOME']=env['APPDATA'];env['YOUJIA_TEST_ISOLATED_DATA']=env['XDG_DATA_HOME']
for k in ['APPDATA','LOCALAPPDATA','XDG_DATA_HOME']:pathlib.Path(env[k]).mkdir(parents=True,exist_ok=True)
exe='D:/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe'
def invoke(args,timeout=300):
 return subprocess.run(args,env=env,encoding='utf-8',errors='replace',capture_output=True,timeout=timeout)
r=invoke([exe,'--headless','--path',str(probe),'--script',str(probe/'probe.gd')],30)
(run/'profile.log').write_text(r.stdout+r.stderr,encoding='utf-8')
print(r.stdout,flush=True)
line=next((x.split('=',1)[1] for x in r.stdout.splitlines() if x.startswith('QA_USER_DIR=')),None)
assert r.returncode==0 and line and pathlib.Path(line).resolve().is_relative_to(run.resolve()),'Native profile isolation could not be verified; no game suites run'
source=root.parent/'source'
sha=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
result={'sourceSha':sha,'startedUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'profileProbe':line,'engine':exe,'tests':[]}
logroot=run.as_posix().replace('D:','/d')
script=run/'verify.sh'
script.write_text('''#!/usr/bin/env bash
set -euo pipefail
cd /d/games/youjia-test/source
export GODOT=/d/games/youjia-tmp-godot/Godot_v4.7.2-stable_win64_console.exe
source tools/lib/verified_godot.sh
''',encoding='utf-8')
entries=['photo_diary_weather','house_sleep','yard_decor_rejection','resting_eyelids','painted_rest_breath']
for entry in entries:
 # Windows Godot uses APPDATA; the repository suites additionally require
 # matching XDG/marker strings and a fresh profile per standalone invocation.
 case=run/('case-'+entry)
 env['APPDATA']=(case/'data').as_posix();env['XDG_DATA_HOME']=env['APPDATA'];env['YOUJIA_TEST_ISOLATED_DATA']=env['APPDATA']
 env['LOCALAPPDATA']=(case/'local').as_posix();env['XDG_CONFIG_HOME']=(case/'config').as_posix();env['XDG_CACHE_HOME']=(case/'cache').as_posix()
 for k in ['APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_CACHE_HOME']:pathlib.Path(env[k]).mkdir(parents=True,exist_ok=True)
 if entry=='import':cmd=f'run_verified_godot {logroot}/import.log --headless --path . --editor --import --quit'
 else:cmd=f'run_verified_godot_suite {logroot}/{entry}.log test/{entry}_suite.gd --headless --path .'
 task=run/(entry+'.sh');task.write_text(script.read_text(encoding='utf-8')+cmd+'\n',encoding='utf-8')
 print('RUN',entry,flush=True)
 try:
  r=invoke(['C:/Program Files/Git/bin/bash.exe',str(task)],330)
  (run/(entry+'-wrapper.log')).write_text(r.stdout+r.stderr,encoding='utf-8')
  result['tests'].append({'entry':entry,'exit':r.returncode,'summary':[s for s in r.stdout.splitlines() if any(k in s for k in ['PASS','checks','[daily-check]','ERROR:','SCRIPT ERROR'])][-12:]})
  print(entry,r.returncode,result['tests'][-1]['summary'],flush=True)
 except subprocess.TimeoutExpired as e:
  result['tests'].append({'entry':entry,'exit':None,'error':'wrapper orchestration timeout'});break
 if r.returncode!=0:break
result['endedUtc']=datetime.datetime.now(datetime.timezone.utc).isoformat()
(run/'results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False),flush=True)

