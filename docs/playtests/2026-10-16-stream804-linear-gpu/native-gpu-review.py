from pathlib import Path
import subprocess,os,json,math,importlib.util,hashlib
import numpy as np
from PIL import Image
out=Path('C:/Users/Zengm/AppData/Local/Temp/youjia-stream804-linear-435-review');art=out/'art/concepts/env_fx_stream_20261014';proj=art/'godot_preview';display=proj/'project.godot'
original=display.read_bytes();display.write_bytes(original.replace(b'viewport_width=1672',b'viewport_width=400').replace(b'viewport_height=941',b'viewport_height=300'))
result={'source':'435cc826fcfd22172745118a2f23fa8b3fa0987c','display_override':{'viewport':[400,300],'original_project_sha256':hashlib.sha256(original).hexdigest(),'modified_project_sha256':hashlib.sha256(display.read_bytes()).hexdigest(),'images_not_resized_or_cropped':True},'runs':[],'comparisons':[]}
env=os.environ.copy();env['APPDATA']=str(out/'appdata');env['LOCALAPPDATA']=str(out/'localappdata');engine='C:/Users/Zengm/AppData/Local/Temp/youjia-local-tools/godot/Godot_v4.7.2-stable_win64_console.exe'
def run(name,args):
 p=subprocess.run([engine,'--path',str(proj),*args],env=env,capture_output=True,timeout=70,creationflags=subprocess.CREATE_NO_WINDOW);raw=p.stdout+p.stderr;log=raw.decode('utf-8',errors='replace');(out/(name+'.log')).write_bytes(raw)
 row={'name':name,'exit':p.returncode,'errors':[l for l in log.splitlines() if 'ERROR:' in l or 'SCRIPT ERROR:' in l],'gpu':[l for l in log.splitlines() if 'OpenGL' in l or 'GPU' in l]};result['runs'].append(row);(out/'gpu-review.json').write_bytes(json.dumps(result,indent=2).encode());assert p.returncode==0 and not row['errors'],row;return row
run('import',['--headless','--editor','--import','--quit'])
spec=importlib.util.spec_from_file_location('original_author_mask_math',art/'verify_scale_linear.py');v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v);v.VW=400;v.VH=300
water=v.load_mask('flow_map.png',3)|v.load_mask('secondary_weight.png');protect=v.load_mask('mask_protect.png',0);rect=np.zeros(water.shape,bool);rect[543:845,191:374]=True
def capture(name,scale,ox,oy,phase=0,extra=(),full=False):
 dest=out/(name+'.png');args=['--rendering-method','gl_compatibility','--resolution','400x300','--position','-2400,-2400','res://'+('stream_flow_preview.tscn' if full else 'stream_flow_crop_demo.tscn'),'--','--phase',repr(phase),'--scale',repr(scale),'--offset',repr(ox),repr(oy),'--dump-frame',str(dest),*extra];row=run(name,args)
 if not full:assert 'base_sample_linear=true' in (out/(name+'.log')).read_text(encoding='utf-8')
 a=np.array(Image.open(dest).convert('RGB')).astype(int);assert a.shape==(300,400,3),a.shape;return a
for scale in [0.75,2.0]:
 ox,oy=v.offset_for(scale,(0.37,0.61));tag=str(scale);sets=v.texel_sets(scale,ox,oy);wa,wy=v.classify(water,sets,False);pa,_=v.classify(protect,sets,False);_,ra=v.classify(rect,sets,False)
 imgs={name:capture(tag+'-'+name,scale,ox,oy,phase,extra,full) for name,phase,extra,full in [('reduced',0,('--reduced',),False),('zero',0,('--strength','0'),False),('tiny',0,('--strength','0.0001'),False),('phase0',0,(),False),('half',math.pi,(),False),('loop',math.tau,(),False),('legacy_full',0,(),True)]}
 base=imgs['reduced'];delta=np.abs(imgs['phase0']-base).max(2);legacy=np.abs(imgs['phase0']-imgs['legacy_full']).max(2);row={'scale':scale,'offset':[ox,oy],'actual_dimensions':[400,300],'zero_vs_reduced_max':int(np.abs(imgs['zero']-base).max()),'tiny_default_vs_linear_painting_max':int(np.abs(imgs['tiny']-base).max()),'outside_crop_max':int(delta[~ra].max(initial=0)),'nonwater_max':int(delta[~wy].max(initial=0)),'protected_max':int(delta[pa].max(initial=0)),'loop_max':int(np.abs(imgs['phase0']-imgs['loop']).max()),'half_changed_pixels':int((np.abs(imgs['phase0']-imgs['half']).max(2)>0).sum()),'legacy_full_reference_water_max':int(legacy[wa].max(initial=0))};result['comparisons'].append(row);print(json.dumps(row),flush=True)
 assert row['zero_vs_reduced_max']==row['outside_crop_max']==row['nonwater_max']==row['protected_max']==row['loop_max']==0,row
 assert row['tiny_default_vs_linear_painting_max']<=1 and row['half_changed_pixels']>0,row
result['scope']='two subpixel scales, direct400x300 nativeGPU only, not full10transform/continuous/Web/host/phone/performance acceptance; old full-reference <=1 oracle no longer valid under intentional continuousUV default'
result['pass']=True;result['files']=[{'name':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.iterdir()) if p.suffix in ['.png','.log']];(out/'gpu-review.json').write_bytes(json.dumps(result,indent=2).encode());print('GPU435_SUBSET_PASS',len(result['runs']),flush=True)
