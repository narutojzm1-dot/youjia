from pathlib import Path
import hashlib, json, shutil

R = Path(r'D:\games\youjia-test\assistant-recovery')
O = Path(r'D:\games\youjia-test\assistant\docs\playtests\2026-10-11-nearby-input')
assert not O.exists(), 'Do not overwrite existing proof'
O.mkdir(parents=True)
rows, full, excluded = [], [], []

def copy(p, target):
    b = p.read_bytes()
    assert len(b) < 100_000_000, str(p)
    q = O / target
    q.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(p, q)
    assert q.read_bytes() == b
    rows.append({'path':str(target).replace('\\','/'), 'source':str(p.relative_to(R)).replace('\\','/'), 'bytes':len(b), 'sha256':hashlib.sha256(b).hexdigest()})

for folder, target in [
    ('nearby-public-window64c-release','public-window64c/release'),
    ('nearby-public-window64c-browser','public-window64c/browser'),
    ('hud734-final-browser','candidate-hud734/browser'),
    ('nearby-input-trace-browser','diagnostic-input/browser'),
    ('nearby-web-storage-fault-oct11','storage-fault/initial-assertion-failure'),
    ('nearby-web-storage-fault-resolve-oct11','storage-fault/resolved'),
]:
    for p in sorted((R/folder).rglob('*')):
        if not p.is_file(): continue
        b = p.read_bytes()
        item = {'path':str(p.relative_to(R)).replace('\\','/'), 'bytes':len(b), 'sha256':hashlib.sha256(b).hexdigest()}
        full.append(item)
        if p.suffix in ('.pck','.wasm'):
            excluded.append(item)
        else:
            copy(p, Path(target)/p.relative_to(R/folder))

groups = {
    'public-window64c': ['nearby-public-window64c-release.log','nearby-public-window64c-browser.log','nearby-pages-tree-window64c-oct11.json','window64c-publish-success.json','window64c-pages-success.json'],
    'candidate-hud734/native': ['382-hud-pointer-baseline.log','382-hud-pointer-fixed.log','382-hud734-audio_button_input.log','382-hud734-modal_touch_input.log','382-hud734-volume_slider_input.log','382-hud734-nearby_direct_pick.log','382-hud734-native-trip-capacity.log','382-hud734-exploration_slice.log','382-hud734-exploration_slice-fixture-restored.log'],
    'candidate-hud734': ['hud734-final-import.log','hud734-final-export.log','hud734-final-browser.log','hud734-final-web/candidate-source.json','hud734-ci-success.json','hud734-ci-success.log','hud734-merge.json','hud734-pr737-final.json','hud734-pr737-comments.json','hud734-pr737-reviews.json','hud734-pr737-inline.json'],
    'diagnostic-input': ['382-near-entry-dispatch-baseline-import.log','382-near-entry-dispatch-baseline.log','382-near-entry-dispatch-camera.log','nearby-input-trace-export.log','nearby-input-trace-browser.log'],
    'scripts': ['browser-nearby-public-quiet-point-oct11.py','verify-nearby-public-release.py','browser-hud734-ordinary-oct11.py','export-hud734-web-oct11.ps1','prepare-hud734-browser-oct11.py','probe-near-entry-dispatch-oct11.gd','trace-near-input-web-oct11.py','export-input-trace-oct11.ps1','browser-nearby-web-storage-fault-oct11.py','browser-nearby-web-storage-fault-resolve-oct11.py','prepare-nearby-web-fault-oct11.py','prepare-nearby-web-fault-resolve-oct11.py','run-native565.ps1'],
}
for target, names in groups.items():
    for name in names:
        p = R / name
        assert p.is_file(), str(p)
        copy(p, Path(target)/p.name)
copy(Path(__file__),Path('scripts')/Path(__file__).name)
(O/'.gitattributes').write_text('* -text\n',encoding='utf-8')
(O/'.gdignore').write_text('',encoding='utf-8')
(O/'evidence-index.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'local-full-archive-manifest.json').write_text(json.dumps(full,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'curation.json').write_text(json.dumps({'rawRepositoryFiles':len(rows),'rawRepositoryBytes':sum(x['bytes'] for x in rows),'selection':'Every original file in the six stated browser/public folders except runtime .pck/.wasm, plus exact named logs, metadata and drivers; initial failed browser attempt retained. No edited images/videos. Original fault v1 terminal stdout was not captured to a file and is not reconstructed.','excludedRuntimeLocallyRetained':excluded,'localArchiveFiles':len(full),'localArchiveBytes':sum(x['bytes'] for x in full)},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'files':len(rows),'bytes':sum(x['bytes'] for x in rows),'output':str(O)}))
