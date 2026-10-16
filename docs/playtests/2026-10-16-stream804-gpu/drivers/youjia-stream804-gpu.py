import os,json,tarfile,subprocess,time,sys
from pathlib import Path
root=Path(r'C:\Users\Zengm\AppData\Local\Temp\youjia-stream804-gpu')
root.mkdir(exist_ok=True)
archive=Path(r'C:\Users\Zengm\AppData\Local\Temp\youjia-stream804-preview.tar')
project=root/'art/concepts/env_fx_stream_20261014/godot_preview'
if not (project/'project.godot').exists():
    with tarfile.open(archive) as tf:
        for member in tf.getmembers():
            target=(root/member.name).resolve()
            assert target.is_relative_to(root.resolve()) and not member.issym() and not member.islnk()
        tf.extractall(root)
engine=Path(r'C:\Users\Zengm\AppData\Local\Temp\youjia-local-tools\godot\Godot_v4.7.2-stable_win64_console.exe')
env=os.environ.copy();env['APPDATA']=str(root/'appdata');env['LOCALAPPDATA']=str(root/'localappdata')
results={'sha':'2e03211f3e3f850b27f7d8236b10ce5e7fe13e41','isolated':True,'runs':[]}
def run(name,args,timeout=80):
    p=subprocess.run([str(engine),'--path',str(project)]+args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,env=env,timeout=timeout)
    log=p.stdout.decode('utf-8',errors='replace');(root/(name+'.log')).write_text(log,encoding='utf-8')
    record={'name':name,'exit':p.returncode,'errors':[line for line in log.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR:' in line]}
    results['runs'].append(record);(root/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8');print(json.dumps(record),flush=True)
    return record
run('import',['--headless','--editor','--import','--quit'])
run('self-check',['--headless','--','--self-check'])
if '--headless-only' not in sys.argv:
    for index in [0,10,20,40]:
        run('gpu-phase-'+str(index),['--rendering-method','gl_compatibility','--resolution','1280x720','--','--phase-frame',str(index),'--dump-frame',str(root/('gpu-phase-'+str(index)+'.png'))])
    run('gpu-portrait',['--rendering-method','gl_compatibility','--resolution','390x844','--','--phase-frame','10','--keep-ui','--dump-frame',str(root/'gpu-portrait.png')])
results['finished']=time.time();(root/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
