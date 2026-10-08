import hashlib,json,shutil
from pathlib import Path

recovery=Path(r'D:\games\youjia-test\assistant-recovery')
artifact=Path(r'D:\games\youjia-test\assistant\docs\playtests\2026-10-08-nearby-direct-pick')
source='0689ff912abf2b52e8bfb9d38bccb15b1b60e916'
views=[('390','nearby565-web-canonical-390'),('844','nearby565-web-canonical-844-serial'),('1280','nearby565-web-desktop-current')]
summary=[]
for width,folder in views:
    original=recovery/folder/width
    rows=json.loads((recovery/folder/'summary.json').read_text(encoding='utf-8'))
    assert len(rows)==1 and not rows[0]['errors']
    package=json.loads((original/'package.json').read_text(encoding='utf-8'))
    assert package['source']==source and len(package['files'])==11
    destination=artifact/'web'/width;destination.mkdir(parents=True,exist_ok=True)
    for path in original.iterdir():
        if path.is_file():shutil.copy2(path,destination/path.name)
    summary.extend(rows)
    shutil.copy2(recovery/(folder+'.log'),artifact/'web'/(width+'.log'))
(artifact/'web'/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert sum(row['events'] for row in summary)==32
prior=artifact/'prior-web';prior.mkdir(exist_ok=True)
for name in ['nearby565-browser-390','nearby565-browser-844','nearby565-final-browser-390','nearby565-final-browser-844','nearby565-entry-browser-390','nearby565-entry-browser-844','nearby565-entry-browser-1280','nearby565-web-combined','nearby565-web-complete','nearby565-web-desktop-recheck','nearby565-web-canonical-844']:
    original=recovery/name
    if not original.exists():continue
    for path in original.rglob('*.json'):
        if 'commands' in path.parts:continue
        destination=prior/name/path.relative_to(original);destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,destination)
    for path in original.rglob('*timeout.png'):
        destination=prior/name/path.relative_to(original);destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,destination)
    if (recovery/(name+'.log')).exists():shutil.copy2(recovery/(name+'.log'),prior/(name+'.log'))
# Original c98d6d3 return symptom was a pause panel. Keep its visual witness.
shutil.copy2(recovery/'nearby565-browser-390'/'returned-yard.png',prior/'c98d6d3-return-opened-pause.png')
candidate=recovery/'nearby565-combined'
bundle={'kind':'local-candidate','sourceCommit':source,'engine':'4.7.2.stable.official.ed1daf0bf','overridePresentAtExport':False,'sha256':{}}
for path in sorted(candidate.rglob('*')):
    if path.is_file():bundle['sha256'][path.relative_to(candidate).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
assert len(bundle['sha256'])==19
(artifact/'bundle.json').write_text(json.dumps(bundle,indent=2)+'\n',encoding='utf-8')
shutil.copy2(recovery/'browser-complete565.py',artifact/'browser-complete565.py')
shutil.copy2(recovery/'archive-nearby565.py',artifact/'archive-nearby565.py')
(artifact/'.gitattributes').write_text('* -text whitespace=cr-at-eol\n*.log -diff\n',encoding='utf-8')
hashes={path.relative_to(artifact).as_posix():hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(artifact.rglob('*')) if path.is_file() and path.name!='sha256.json'}
(artifact/'sha256.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'source':source,'states':sum(row['events'] for row in summary),'errors':sum(len(row['errors']) for row in summary),'files':len(hashes),'pck_sha256':bundle['sha256']['index.pck']},indent=2))
