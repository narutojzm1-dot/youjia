from pathlib import Path
import json,hashlib,shutil
R=Path(r'D:\games\youjia-test\assistant-recovery')
O=Path(r'D:\games\youjia-test\assistant\docs\playtests\2026-10-11-nearby-input-release')
assert not (O/'evidence-index.json').exists(), 'Completed curation must not be overwritten'
retry=json.loads((R/'nearby-public-inputc282-desktop-observed/summary.json').read_text(encoding='utf-8'))
assert len(retry)==1 and retry[0]['view'][0]==1280 and not retry[0]['errors']
combined=[]
for w in [390,844]:
    folder=R/'nearby-public-inputc282-browser'/str(w)
    ev=json.loads((folder/'events.json').read_text(encoding='utf-8'))
    p=json.loads((folder/'package.json').read_text(encoding='utf-8'))
    assert p['source']=='c28246f14dd8bca837624699ca9447124e39d0d1'
    assert ev[-1]['stage']=='reload-yard' and not ev[-1]['errors']
    k=ev[-1]['payload']['keepsakes'];assert len(k)==1 and list(k.values())==[1]
    combined.append({'view':p['viewport'],'events':len(ev),'keepsakes_after_reload':k,'errors':ev[-1]['errors'],'provenance':'completed viewport within original three-view driver; overall run later failed desktop navigation30s'})
combined.append(retry[0] | {'provenance':'independent desktop observed run with domcontentloaded then actual first-frame, cold600s observation budget; actual completion marker and summary retained, terminal exit code not retained'})
O.mkdir(parents=True,exist_ok=True)
rows=[];full=[];excluded=[];missing=[]
def cp(p,t):
    b=p.read_bytes();assert len(b)<100_000_000,str(p)
    d=O/t;d.parent.mkdir(parents=True,exist_ok=True)
    if d.exists():assert d.read_bytes()==b, f'Unexpected pre-existing bytes: {d}'
    else:shutil.copyfile(p,d)
    assert d.read_bytes()==b
    rows.append({'path':str(t).replace('\\','/'),'source':str(p.relative_to(R)).replace('\\','/'),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
for folder,target in [('nearby-public-input3ca-release','release-3ca'),('nearby-public-input3ca-browser','failure-source-changed'),('nearby-public-inputc282-release','release-current'),('nearby-public-inputc282-browser','browser-initial'),('nearby-public-inputc282-desktop-retry','failure-desktop-cold180'),('nearby-public-inputc282-desktop-observed','browser-desktop-observed')]:
    for p in sorted((R/folder).rglob('*')):
        if not p.is_file():continue
        b=p.read_bytes(); item={'path':str(p.relative_to(R)).replace('\\','/'),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()};full.append(item)
        if p.suffix in ['.pck','.wasm']:excluded.append(item)
        else:cp(p,Path(target)/p.relative_to(R/folder))
for name in ['nearby-public-input3ca-release.log','nearby-public-input3ca-browser.log','nearby-public-inputc282-release.log','nearby-public-inputc282-browser.log','nearby-public-inputc282-desktop-retry.log','nearby-public-inputc282-desktop-observed.log','hud734-publish-success.json','hud734-pages-success.json','nearby-c282-publish-success.json','nearby-c282-publish-success.log','nearby-c282-pages-success.json','nearby-pages-tree-input3ca-oct11.json','nearby-pages-tree-inputc282-oct11.json','nearby-goal-audit-source-oct11.json','audio623-live-oct11.json','audio542-live-oct11.json','audio196-live-oct11.json','nearby-audio623-files-oct11.json','input-public-network-analysis-oct11.json']:
    if (R/name).exists():cp(R/name,Path('metadata')/name)
    else:missing.append(name)
for name in ['verify-nearby-public-release.py','browser-nearby-public-input3ca-oct11.py','browser-nearby-public-input-current-oct11.py','browser-nearby-public-desktop-retry-oct11.py','browser-nearby-public-desktop-observed-oct11.py','prepare-input3ca-public-browser-oct11.py','prepare-input-current-public-browser-oct11.py','prepare-input-public-desktop-retry-oct11.py','prepare-input-public-observed-oct11.py','curate-input-public-release-oct11.py','analyze-input-public-network-oct11.py']:
    cp(R/name,Path('scripts')/name)
for p in sorted((R/'pck-budget-c282').glob('*')):
    if p.is_file():cp(p,Path('pck-budget')/p.name)
cp(R/'nearby565-completion-audit-oct11.md',Path('completion-audit.md'))
(O/'summary-combined.json').write_bytes((json.dumps({'source':'c28246f14dd8bca837624699ca9447124e39d0d1','aggregation':'two completed original viewports plus independent desktop repeat; not a fabricated original all-view runner pass','viewports':combined,'events':sum(x['events'] for x in combined)},indent=2)+'\n').encode('utf-8'))
(O/'.gdignore').write_bytes(b'')
(O/'.gitattributes').write_bytes(b'* -text\n')
(O/'evidence-index.json').write_bytes((json.dumps(rows,indent=2)+'\n').encode('utf-8'))
(O/'local-full-archive-manifest.json').write_bytes((json.dumps(full,indent=2)+'\n').encode('utf-8'))
(O/'curation.json').write_bytes((json.dumps({'rawFiles':len(rows),'rawBytes':sum(x['bytes'] for x in rows),'selection':'Every original browser/release file except duplicate PCK/WASM, exact metadata/scripts and requirement audit. Initial version race, desktop30s navigation and cold180s failure preserved. First two terminal stderr traces were returned by exec but not recorded to files; not reconstructed. Observed driver stdout text may have native code-page corruption; canonical loading-network JSON was written UTF8.','missingNotReconstructed':missing,'excludedLocallyRetained':excluded},indent=2)+'\n').encode('utf-8'))
print(json.dumps({'rawFiles':len(rows),'rawBytes':sum(x['bytes'] for x in rows),'combinedEvents':sum(x['events'] for x in combined)}))
