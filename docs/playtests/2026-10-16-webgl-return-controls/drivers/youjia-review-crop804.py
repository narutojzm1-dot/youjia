from pathlib import Path
import subprocess,zipfile,io,json,hashlib,sys
repo=Path('C:/Users/Zengm/.codex/worktrees/ui-audio-704/youjia')
sha='9f7ab71b3d1fadeec0973f49ca4e33c4355b0760'
out=Path('C:/Users/Zengm/AppData/Local/Temp/youjia-stream804-crop-9f7-review')
out.mkdir(exist_ok=False)
raw=subprocess.check_output(['git','-C',str(repo),'archive','--format=zip',sha,'art/concepts/env_fx_stream_20261014'])
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    for info in z.infolist():
        dest=(out/info.filename).resolve()
        assert dest.is_relative_to(out.resolve())
        if info.is_dir():dest.mkdir(parents=True,exist_ok=True)
        else:dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(z.read(info))
art=out/'art/concepts/env_fx_stream_20261014'
r=subprocess.run([sys.executable,str(art/'make_crop_textures.py'),'--check'],capture_output=True,text=True,encoding='utf-8')
(out/'crop-check.log').write_text(r.stdout+r.stderr,encoding='utf-8')
files=[]
for f in sorted((art/'godot_preview/textures/crop').glob('*.png')):
    b=f.read_bytes();files.append({'file':f.name,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
receipt={'source':sha,'test':'author crop source equality --check, no rendering performed','exit':r.returncode,'files':files}
(out/'receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
print(r.stdout);print(json.dumps(receipt));sys.exit(r.returncode)
