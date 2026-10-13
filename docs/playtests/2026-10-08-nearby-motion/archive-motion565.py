import hashlib,json,shutil
from pathlib import Path
r=Path(r'D:\games\youjia-test\assistant-recovery')
a=Path(r'D:\games\youjia-test\assistant\docs\playtests\2026-10-08-nearby-motion')
a.mkdir(parents=True,exist_ok=True)
(a/'.gdignore').write_bytes(b'')
(a/'.gitattributes').write_bytes(b'* -text whitespace=cr-at-eol\n*.log -diff\n')
def copy(src,dest):
    dest=a/dest;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(r/src,dest)
for name in ['382-nearby565-motion-first-import.log','382-nearby565-motion-first.log','382-nearby565-motion-pick-regression.log','382-nearby565-motion-slice-regression.log','nearby565-motion-gate.log','nearby565-motion-ci-2179e80.log','nearby565-motion-export.log']:
    copy(name,'native/'+name)
for name in ['nearby565-motion-render.log','nearby565-motion-render-error.log','nearby565-motion-render-fixed.log','nearby565-motion-render-fixed-error.log']:
    copy(name,'render/'+name)
for p in (r/'nearby565-motion-render-fixed').iterdir():copy(p.relative_to(r),'render/'+p.name)
for name in ['nearby565-motion-bench.log','nearby565-motion-bench-error.log','nearby565-motion-bench-fixed.log','nearby565-motion-bench-fixed-error.log','nearby565-motion-bench-witness.log','nearby565-motion-bench-witness-error.log','nearby565-motion-gpu.json','nearby565-motion-gpu-summary.json','nearby565-motion-gpu-without-pixel-witness.json','benchmark-motion565.gd']:
    copy(name,'benchmark/'+name)
for p in r.glob('nearby565-motion-gpu-*.png'):copy(p.relative_to(r),'benchmark/'+p.name)
for p in (r/'nearby565-motion-browser').rglob('*'):
    if p.is_file():copy(p.relative_to(r),'web/'+p.relative_to(r/'nearby565-motion-browser').as_posix())
copy('nearby565-motion-browser.log','web/browser.log')
copy('browser-motion565.py','browser-motion565.py')
copy('archive-motion565.py','archive-motion565.py')
copy('run-native565.ps1','run-native565.ps1')
candidate=r/'nearby565-motion-web'
bundle={'sourceCommit':'2179e80e481797b195529108c197c19323cb87bb','kind':'local-candidate','overridePresentAtExport':False,'sha256':{p.relative_to(candidate).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in candidate.rglob('*') if p.is_file()}}
assert len(bundle['sha256'])==19
(a/'bundle.json').write_text(json.dumps(bundle,indent=2)+'\n',encoding='utf-8')
rows=json.loads((a/'web/summary.json').read_text())
assert len(rows)==3 and sum(x['events'] for x in rows)==30 and not any(x['errors'] for x in rows)
hashes={p.relative_to(a).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(a.rglob('*')) if p.is_file() and p.name!='sha256.json'}
(a/'sha256.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'files':len(hashes),'bytes':sum(p.stat().st_size for p in a.rglob('*') if p.is_file()),'source':bundle['sourceCommit'],'web_states':30,'pck_sha256':bundle['sha256']['index.pck']}))
