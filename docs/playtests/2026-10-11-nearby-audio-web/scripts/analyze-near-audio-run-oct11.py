from pathlib import Path
import json, subprocess
R=Path(r'D:\games\youjia-test\assistant-recovery')
P=R/'nearby-audio-web-proof-oct11';L=P/'long'
summary=json.loads((L/'summary.json').read_text(encoding='utf-8'))
steps=json.loads((L/'steps.json').read_text(encoding='utf-8'))
rows=json.loads((L/'long-samples.json').read_text(encoding='utf-8'))
assert not summary['errors'] and summary['nightControls'] and summary['longSpanSeconds']>=699
assert len(steps)==summary['states']
assert all(not v['errors'] and not v['audio']['failures'] for v in rows+steps)
inputs=steps[-1]['inputs'];assert inputs and all(v['trusted'] for step in steps for v in step['inputs'])
backend=[v['audio']['backend'] for v in rows if v['audio']['backend']]
signals=[s for v in rows for s in v['audio']['signal']]
assert all(s['nonFinite']==0 for s in signals)
controls=[]
for prefix in ['day-controls','night-controls']:
 for phase,wanted in [('environment-only',True),('both-off',False),('music-only',True),('master-muted',False),('restored',True)]:
  name=prefix+'-'+phase;checks=json.loads((L/(name+'-signal.json')).read_text());rms=[max((s['rms'] for s in v['signal']),default=0) for v in checks]
  assert max(rms)>1e-6 if wanted else max(rms)<1e-7
  controls.append({'stage':name,'windows':len(rms),'expectedSignal':wanted,'minMaximumRms':min(rms),'maxMaximumRms':max(rms)})
w=R/'nearby-audio-web-validation'
git=lambda args:subprocess.check_output(['git',*args],cwd=w).decode().strip()
result={'exportDeclaredSource':summary['source'],'recoverableWorkingTreeSource':git(['rev-parse','HEAD']),'trackedDirty':git(['status','--porcelain']),'privateCombinationParents':['5d23acbec9d756fc5e3ddee678e2db478ff18935','e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169'],'provenance':'Native129/104/72/189 logs identify4ac plus actual Godot-generated UID/import metadata subsequently recorded by570. Native305/48 and export identify570. Export also generated5 untracked metadata files, and148 tracked modifications were only CRLF/LF. Final06d records those5 original generated files; it is a recoverable snapshot after export, not a newly exported or newly tested production SHA. Both Git bundles and original state hashes retained. Original Leader/542 ancestry is preserved; candidate remains private.','states':len(steps),'samples':len(rows),'longSpanSeconds':summary['longSpanSeconds'],'naturalPicked':summary['naturalPicked'],'keepsakesAfterReload':summary['keepsakesAfterReload'],'backendPeaks':{k:max(v[k] for v in backend) for k in ['buffers','bytes','decoded','starts','players','playing']},'backendFinal':backend[-1],'maximumSignalPeak':max(s['peak'] for s in signals),'nonFinite':sum(s['nonFinite'] for s in signals),'observedJsHeapPeakBytes':max((v['audio']['jsHeap'] or {}).get('used',0) for v in rows),'ordinaryInputEventsAfterReload':len(inputs),'controls':controls,'nightState':next({'utc':v['utc'],'payload':v['payload'],'audio':v['audio']} for v in steps if v['stage']=='natural-near-rain-night'),'limitations':'Fresh local diagnostic browser only, default mute-audio; captured software PCM/Opus and independent decode are not perceptual listening, hardware output, physical phone/background lifecycle, whole browser/WASM/GPU memory or official public version. Deliberate control mute gaps are not uninterrupted listening.'}
(P/'run-analysis.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ['nightState','controls','provenance','limitations']},ensure_ascii=False))
