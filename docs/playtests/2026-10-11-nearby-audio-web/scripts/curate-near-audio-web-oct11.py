from pathlib import Path
import hashlib, json, shutil
R=Path(r'D:\games\youjia-test\assistant-recovery')
O=Path(r'D:\games\youjia-test\assistant\docs\playtests\2026-10-11-nearby-audio-web')
P=R/'nearby-audio-web-proof-oct11'
assert (P/'long/summary.json').is_file(), 'A live or failed run is not a completed run'
assert (P/'recording-software-analysis.json').is_file()
assert not (O/'evidence-index.json').exists(), 'Do not overwrite finished curation'
rows=[];full=[];excluded=[]
def cp(p,t):
    data=p.read_bytes();assert len(data)<100_000_000
    d=O/t;d.parent.mkdir(parents=True,exist_ok=True)
    if d.exists():assert d.read_bytes()==data
    else:shutil.copyfile(p,d)
    assert d.read_bytes()==data
    rows.append({'path':str(t).replace('\\','/'),'source':str(p.relative_to(R)).replace('\\','/'),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
for p in sorted(P.rglob('*')):
    if p.is_file():cp(p,Path('raw')/p.relative_to(P))
for p in sorted((R/'audio-validation-merge-record').rglob('*')):
    if p.is_file():cp(p,Path('merge-record')/p.relative_to(R/'audio-validation-merge-record'))
for name in ['audio-validation-initialization-interrupted-oct11.json','nearby-audio-observer-calibration-oct11.json','nearby-audio-observer-calibration-preflight-oct11.json','audio623-live-oct11.json','audio542-live-oct11.json','audio196-live-oct11.json','pr623-assistant-web-audio-scope-oct11.md']:
    cp(R/name,Path('metadata')/name)
for name in ['browser-near-audio-long-oct11.py','nearby-web-audio-observer-oct11.js','nearby-web-audio-observer-preflight-oct11.js','calibrate-nearby-audio-observer-oct11.py','probe-web-audio-combination-oct11.py','probe-near-audio-track-metadata-oct11.gd','verify-export-near-audio-combination-oct11.ps1','verify-export-near-audio-combination-initial-oct11.ps1','resolve-audio-validation-merge-oct11.py','analyze-near-audio-recordings-oct11.py','curate-near-audio-web-oct11.py','analyze-near-audio-run-oct11.py','verify-near-audio-proof-git-oct11.py']:
    cp(R/name,Path('scripts')/name)
for p in sorted((R/'nearby-audio-combination-web').rglob('*')):
    if not p.is_file():continue
    data=p.read_bytes();item={'source':str(p.relative_to(R)).replace('\\','/'),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()};full.append(item)
    if p.suffix in ['.pck','.wasm']:excluded.append(item)
    else:cp(p,Path('export-auxiliary')/p.relative_to(R/'nearby-audio-combination-web'))
O.mkdir(parents=True,exist_ok=True)
(O/'.gdignore').write_bytes(b'')
(O/'.gitattributes').write_bytes(b'* -text\n')
(O/'evidence-index.json').write_bytes((json.dumps(rows,indent=2)+'\n').encode())
(O/'local-export-manifest.json').write_bytes((json.dumps(full,indent=2)+'\n').encode())
(O/'curation.json').write_bytes((json.dumps({'rawFiles':len(rows),'rawBytes':sum(x['bytes'] for x in rows),'selection':'All actual native, preflight, long browser, software recordings and decode metrics; initialization, CRLF completion-marker failure and missing fixture failure retained. Merge records and recoverable Git bundles included. Local duplicate PCK/WASM retained with byte counts and SHA256 only. No physical-device, audible quality, public release or uninterrupted ten-minute hearing claim.','excludedLocallyRetained':excluded},indent=2)+'\n').encode())
print(json.dumps({'rawFiles':len(rows),'rawBytes':sum(x['bytes'] for x in rows)}))
