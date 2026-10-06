from pathlib import Path
import subprocess,os,json
repo=Path('/tmp/youjia-photo461');out=Path('/tmp/photo461-evidence/shutter-contract-cases');out.mkdir(exist_ok=True)
fake=out/'fake-godot';fake.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$PHOTO461_TEST_OUTPUT"\n');fake.chmod(0o755)
label='[photo-arrival-shutter-paper] PASS: '
cases=[('actual-positive',label+'1290 checks',0),('positive-min',label+'1 checks',0),('zero',label+'0 checks',1),('negative',label+'-1 checks',1),('wrong-suite','[photo-arrival-mat] PASS: 1290 checks',1),('bracketless','photo-arrival-shutter-paper PASS: 1290 checks',1),('suffix',label+'1290 checks pending',1),('empty','',1),('late-error',label+'1290 checks\nERROR: late failure',1)]
rows=[]
for name,text,expect in cases:
 log=out/(name+'.log');env={**os.environ,'GODOT':str(fake),'PHOTO461_TEST_OUTPUT':text,'PHOTO461_LOG':str(log)}
 result=subprocess.run(['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite "$PHOTO461_LOG" test/photo_arrival_shutter_paper_suite.gd --headless --path .'],cwd=repo,env=env,capture_output=True)
 (out/(name+'-wrapper.log')).write_bytes(result.stdout+result.stderr)
 rows.append({'name':name,'output':text,'expected_returncode':expect,'actual_returncode':result.returncode,'passed':result.returncode==expect})
record={'type':'controlled fake executable wrapper test; no Godot engine','scope':'new exact bracketed shutter-paper completion registration','cases':rows,'passed':all(x['passed'] for x in rows)}
(out/'result.json').write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record,indent=2));assert record['passed']
