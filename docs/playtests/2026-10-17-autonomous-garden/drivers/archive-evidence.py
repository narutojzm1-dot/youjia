from pathlib import Path
import json,gzip,hashlib,shutil
src=Path(__file__).parent
dest=src/'evidence-ready';dest.mkdir(exist_ok=True)
manifest=[]
def copy(p,relative):
    target=dest/relative;target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(p.read_bytes());manifest.append({'path':relative,'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
for p in src.glob('*.log'):
    target=dest/'logs'/(p.name+'.gz');target.parent.mkdir(exist_ok=True)
    with target.open('wb') as raw:
        with gzip.GzipFile(filename='',mode='wb',fileobj=raw,mtime=0) as f:f.write(p.read_bytes())
    manifest.append({'path':str(target.relative_to(dest)).replace('\\','/'),'raw_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
for n in ['fixture.gd','fixture.json','source-chain.gd','garden-photo.json','bloom-photo.json','old-photo-probe.gd','old-pck-photo.json','old-pck-only-photo.json','garden-web.cjs','garden-bloom.cjs','make-bloom-driver.py','prepare-source.py','pack-probe.gd','candidate-pack.json','candidate-pack-r2.json','runtime-code-equivalence.json','remaining-validation.json','tail-run-index.json','garden-public.cjs','audit-public.py','garden-source-ui.cjs','make-explore-driver.py','prepare-public-driver.py','prepare-natural-bloom.py','garden-natural-bloom.cjs','source-web-validate.py','validate-public-fixture.gd','fixture-public-old-photo.json','old-photo-public-fixture-source.json','finalize-docs.py','preserve-final.py','monitor-publication.py','push-evidence.py','archive-evidence.py']:
    if (src/n).exists():copy(src/n,'drivers/'+n)
for d in ['web-actual','web-actual-r2','web-bloom-sun','web-bloom-overcast','web-bloom-sun-r2','web-bloom-overcast-r2','web-natural-bloom']:
    for p in (src/d).glob('*'):
        if p.is_file():copy(p,d+'/'+p.name)
for d in ['writer4-r2','writer4-r3']:
    for p in (src/d).rglob('result.json'):
        copy(p,str(p.relative_to(src)).replace('\\','/'))
for n in ['result.json','source-ui-00.jpg','source-ui-02.jpg','source-ui-10.jpg']:
    if (src/'web-source-ui-r2'/n).exists():copy(src/'web-source-ui-r2'/n,'web-source-ui-r2/'+n)
for p in (src/'web-source-ui-r3').glob('*'):
    if p.is_file():copy(p,'web-source-ui-r3/'+p.name)
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print('Prepared evidence files',len(manifest),'bytes',sum(p.stat().st_size for p in dest.rglob('*') if p.is_file()))
