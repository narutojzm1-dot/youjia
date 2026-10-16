from pathlib import Path
import subprocess,urllib.request,concurrent.futures,hashlib,json,os
from PIL import Image,ImageChops
repo='C:/Users/Zengm/.codex/worktrees/ui-audio-704/youjia';sha='ef097e5cd47d468e901ee498af20b719315f13e8';prefix='art/concepts/env_fx_stream_20261014/'
old=Path('C:/Users/Zengm/AppData/Local/Temp/youjia-stream804-linear-435-review');out=Path('C:/Users/Zengm/AppData/Local/Temp/youjia-stream804-ef-review');out.mkdir(exist_ok=True)
rows=[x.split(None,3) for x in subprocess.check_output(['git','-C',repo,'ls-tree','-r',sha,prefix],text=True).splitlines()];rows=[(x[3],x[2]) for x in rows if Path(x[3]).suffix in ['.gd','.gdshader','.tscn','.png','.godot','.py','.cfg']]
def copy(pair):
 path,blob=pair;p=old/path;b=p.read_bytes() if p.exists() else b''
 if hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()!=blob:
  with urllib.request.urlopen(urllib.request.Request('https://raw.githubusercontent.com/narutojzm1-dot/youjia/'+sha+'/'+path,headers={'User-Agent':'Youjia-Lead-repro'}),timeout=30) as r:b=r.read()
 assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==blob,path
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(b);return {'path':path,'git_blob':blob}
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:files=list(pool.map(copy,rows))
proj=out/prefix/'godot_preview';project=proj/'project.godot';original=project.read_bytes();project.write_bytes(original.replace(b'viewport_width=1672',b'viewport_width=400').replace(b'viewport_height=941',b'viewport_height=300'))
env=os.environ.copy();env['APPDATA']=str(out/'appdata');env['LOCALAPPDATA']=str(out/'localappdata');engine='C:/Users/Zengm/AppData/Local/Temp/youjia-local-tools/godot/Godot_v4.7.2-stable_win64_console.exe';runs=[]
def run(name,args):
 p=subprocess.run([engine,'--path',str(proj),*args],env=env,capture_output=True,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW);raw=p.stdout+p.stderr;(out/(name+'.log')).write_bytes(raw);text=raw.decode('utf-8',errors='replace');errors=[x for x in text.splitlines() if 'ERROR:' in x or 'SCRIPT ERROR:' in x];assert p.returncode==0 and not errors,(p.returncode,errors);runs.append({'name':name,'exit':p.returncode,'errors':errors,'log_sha256':hashlib.sha256(raw).hexdigest(),'relevant':[x for x in text.splitlines() if 'base_sample_linear=' in x or 'OpenGL' in x]})
run('import',['--headless','--editor','--import','--quit'])
for name,extra in [('default',[]),('base-nearest',['--base-nearest'])]:run(name,['--rendering-method','gl_compatibility','--resolution','400x300','--position','-2400,-2400','res://stream_flow_crop_demo.tscn','--','--phase','0','--scale','2.0','--offset','-364.63','-1237.39','--dump-frame',str(out/(name+'.png')),*extra])
near=(out/'base-nearest.log').read_text(encoding='utf-8');same=ImageChops.difference(Image.open(out/'default.png'),Image.open(out/'base-nearest.png')).getbbox() is None
result={'source':sha,'source_files_verified':len(files),'files':files,'runs':runs,'only_project_viewport_override':[400,300],'direct_png_not_resized':True,'nearest_argument_observed_linear_true':'base_sample_linear=true' in near,'nearest_and_default_images_identical':same,'finding':'_parse_user_args sets base_sample_linear=false, then _ready overwrites true; legacy nearest control is ineffective','hardware_phone_claim':False}
assert result['nearest_argument_observed_linear_true'] and same
(out/'repro.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in result.items() if k not in ['files']}),flush=True)
