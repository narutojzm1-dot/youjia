import hashlib,json,shutil,subprocess
from pathlib import Path
root=Path(r'D:\games\youjia-test\assistant-recovery')
repo=Path(r'D:\games\youjia-test\assistant')
dest=repo/'docs/playtests/2026-10-12-nearby-find-audio/raw/merge-main-oct13'
assert not dest.exists(), 'Do not overwrite archived evidence'
dest.mkdir(parents=True)
rows=[]
def copy_file(source,rel):
    source=Path(source);target=dest/rel;data=source.read_bytes()
    assert not target.exists()
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    assert target.read_bytes()==data
    rows.append({'path':str(rel).replace('\\','/'),'original':str(source),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
for folder,label in [('nearby-find-audio-main-oct13','validation'),('find16-generated-metadata-before-main-oct13','generated-before-main'),('find16-import-stat-before-main-oct13','import-stat-before-main'),('find16-generated-metadata-current2272-oct13','generated-current')]:
    source=root/folder
    for path in sorted(source.rglob('*')):
        if path.is_file():copy_file(path,Path(label)/path.relative_to(source))
copy_file(root/'ci-38268872009-failed.log',Path('ci-38268872009-failed.log'))
for name in ['verify-find16-main-oct13.ps1','browser-near-find-audio-main-oct13.py','browser-near-find-audio-main-baseline-oct13.py','nearby-find-audio-observer-oct12.js','analyze-near-find-audio-main-oct13.py','preserve-find16-generated-metadata-oct13.py','preserve-find16-import-stat-oct13.py','preserve-find16-current2272-metadata-oct13.py']:
    copy_file(root/name,Path('drivers')/name)
(dest/'index.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
web=root/'nearby-find-audio-main-oct13/web'
windows=json.loads((web/'signal-windows.json').read_text())
metrics=[{'stage':w['stage'],'rms':max((s['rms'] for r in w['rows'] for s in r['signal']),default=0),'peak':max((s['peak'] for r in w['rows'] for s in r['signal']),default=0),'nonFinite':sum(s['nonFinite'] for r in w['rows'] for s in r['signal'])} for w in windows]
steps=json.loads((web/'steps.json').read_text())
stats={'source':'2272b045a2acbe051196e1aafbff3f3217f942c6','main':'53d1b38a96260f0186f181167c5d6bca5201c168','rawFiles':len(rows),'rawBytes':sum(r['bytes'] for r in rows),'softwareWindows':metrics,'maxBackendBuffers':max(s['audio']['backend']['buffers'] for s in steps),'maxBackendPlayers':max(s['audio']['backend']['players'] for s in steps),'baseline':json.loads((web/'baseline-backend.json').read_text()),'original266Archive':'Unchanged. Verify its own raw-index.json independently; do not combine new counts into the historical index.','uncovered':'No physical phone/background/lock-screen or perceptual device mix acceptance; 623 regional draft remains separate.'}
(dest/'context.json').write_text(json.dumps(stats,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
old_index=json.loads((repo/'docs/playtests/2026-10-12-nearby-find-audio/raw-index.json').read_text(encoding='utf-8-sig'))
for row in old_index:
    data=(repo/'docs/playtests/2026-10-12-nearby-find-audio'/row['path']).read_bytes()
    assert len(data)==row['bytes'] and hashlib.sha256(data).hexdigest()==row['sha256'],row['path']
print(json.dumps(stats,ensure_ascii=False))
print('FIND16_ARCHIVE_CURRENT_AND_ORIGINAL_266_VERIFIED')
