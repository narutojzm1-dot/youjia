from pathlib import Path
import subprocess,zipfile,secrets,os,shutil,json,hashlib,sys
O=Path(__file__).parent/(sys.argv[1] if len(sys.argv)>1 else 'stream804-matrix');O.mkdir(exist_ok=True)
R=Path(r'C:/Users/jiangzengming/.codex/worktrees/growth-garden-700/youjia');sha='33106846329d0917e46f4bbc9c239cd2701bd5f2'
archive=O/'source.zip'
with archive.open('wb') as f:subprocess.run(['git','archive','--format=zip',sha,'art/concepts/env_fx_stream_20261014'],cwd=R,stdout=f,check=True)
with zipfile.ZipFile(archive) as z:z.extractall(O/'source')
cand=O/'source/art/concepts/env_fx_stream_20261014';proj=cand/'godot_preview';site=O/'site';site.mkdir(exist_ok=True)
(O/'uploads').mkdir(exist_ok=True)
build=secrets.token_hex(16);(proj/'build_id.txt').write_bytes((build+'\n').encode())
env=os.environ.copy();env['APPDATA']=str(O.parent/'export-profile')
godot=r'D:/work/tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe'
for label,args in [('import',['--editor','--import','--quit']),('export',['--export-release','Web crop demo 749',str(site/'index.html')])]:
    with (O/(label+'.log')).open('wb') as log:p=subprocess.run([godot,'--headless','--path',str(proj),*args],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    assert p.returncode==0,(label,p.returncode)
identity={'source':sha,'build_id':build,'pck_sha256':hashlib.sha256((site/'index.pck').read_bytes()).hexdigest(),'pck_bytes':(site/'index.pck').stat().st_size,'wasm_sha256':hashlib.sha256((site/'index.wasm').read_bytes()).hexdigest(),'godot':'4.7.2.stable Windows','server_id':secrets.token_hex(16),'original_linux_shell_executed':False,'render_scope':'Actual Windows Chrome hardware GL; isolated candidate only'}
(O/'identity-base.json').write_text(json.dumps(identity,indent=2),encoding='utf-8');print(json.dumps(identity,indent=2))
