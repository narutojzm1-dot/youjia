from pathlib import Path
import subprocess,os,json,time,math,sys
import numpy as np
from PIL import Image
out=Path('C:/Users/Zengm/AppData/Local/Temp/youjia-stream804-crop-9f7-review')
project=out/'art/concepts/env_fx_stream_20261014/godot_preview'
engine=Path('C:/Users/Zengm/AppData/Local/Temp/youjia-local-tools/godot/Godot_v4.7.2-stable_win64_console.exe')
env=os.environ.copy();env['APPDATA']=str(out/'appdata');env['LOCALAPPDATA']=str(out/'localappdata')
r={'source':'9f7ab71b3d1fadeec0973f49ca4e33c4355b0760','isolated':True,'started':time.time(),'runs':[]}
def run(name,args):
    p=subprocess.run([str(engine),'--path',str(project)]+args,env=env,capture_output=True,timeout=85)
    log=(p.stdout+p.stderr).decode('utf-8',errors='replace');(out/(name+'.log')).write_text(log,encoding='utf-8')
    row={'name':name,'exit':p.returncode,'errors':[x for x in log.splitlines() if 'ERROR:' in x or 'SCRIPT ERROR:' in x]}
    r['runs'].append(row);(out/'gpu-review.json').write_text(json.dumps(r,indent=2),encoding='utf-8');print(json.dumps(row),flush=True)
    assert p.returncode==0 and not row['errors'],row
run('import',['--headless','--editor','--import','--quit'])
run('crop-self-check',['--headless','res://stream_flow_crop_demo.tscn','--','--self-check'])
for n,phase in [('0',0),('quarter',math.pi/2),('half',math.pi),('full',math.tau)]:
    for kind,scene in [('full','stream_flow_preview.tscn'),('crop','stream_flow_crop_demo.tscn')]:
        run(kind+'-'+n,['--rendering-method','gl_compatibility','--resolution','1672x941','res://'+scene,'--','--phase',repr(phase),'--dump-frame',str(out/(kind+'-'+n+'.png'))])
for name,args in [('zero',['--strength','0']),('reduced',['--reduced'])]:
    run('crop-'+name,['--rendering-method','gl_compatibility','--resolution','1672x941','res://stream_flow_crop_demo.tscn','--','--phase',repr(math.pi/2),'--dump-frame',str(out/('crop-'+name+'.png')),*args])
base=np.array(Image.open(project/'textures/near_path_base.png').convert('RGB')).astype(int)
prot=np.array(Image.open(project/'textures/mask_protect.png'));prot=(prot[...,0] if prot.ndim==3 else prot)>0
inside=np.zeros(base.shape[:2],bool);inside[543:845,191:374]=True
def img(name):
    a=np.array(Image.open(out/(name+'.png')).convert('RGB')).astype(int)
    assert a.shape==base.shape,{'actual':a.shape,'base':base.shape,'no_resize_or_crop_performed':True}
    return a
r['comparisons']=[]
for name in ['0','quarter','half','full']:
    a,b=img('full-'+name),img('crop-'+name);d=np.abs(a-b).max(2);db=np.abs(b-base).max(2)
    row={'phase':name,'shape':list(b.shape),'crop_vs_full_max':int(d.max()),'different_pixels':int((d>0).sum()),'outside_max':int(db[~inside].max()),'protected_max':int(db[prot].max())};r['comparisons'].append(row)
    assert row['crop_vs_full_max']<=1 and row['outside_max']==0 and row['protected_max']==0,row
r['loop_max']=int(np.abs(img('crop-0')-img('crop-full')).max())
r['half_changed']=int((np.abs(img('crop-0')-img('crop-half')).max(2)>0).sum())
r['zero_max']=int(np.abs(img('crop-zero')-base).max());r['reduced_max']=int(np.abs(img('crop-reduced')-base).max())
assert r['loop_max']==r['zero_max']==r['reduced_max']==0 and r['half_changed']>0
r['finished']=time.time();r['pass']=True;(out/'gpu-review.json').write_text(json.dumps(r,indent=2),encoding='utf-8');print(json.dumps(r),flush=True)
