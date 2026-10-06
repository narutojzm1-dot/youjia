from pathlib import Path
import subprocess,os,json,hashlib
repo=Path('/tmp/youjia-soft455');out=Path('/tmp/soft455-evidence/disabled-contract-cases');out.mkdir(exist_ok=True)
fake=out/'fake-godot';fake.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$SOFT455_TEST_OUTPUT"\n');fake.chmod(0o755)
cases=[('actual-positive','PASS: soft_button_disabled 4400 checks',0),('positive-min','PASS: soft_button_disabled 1 checks',0),('zero','PASS: soft_button_disabled 0 checks',1),('negative','PASS: soft_button_disabled -1 checks',1),('wrong-suite','PASS: soft_button_focus_contrast 4400 checks',1),('suffix','PASS: soft_button_disabled 4400 checks pending',1),('empty','',1),('late-error','PASS: soft_button_disabled 4400 checks\nERROR: late failure',1)]
rows=[]
for name,text,expect in cases:
 log=out/(name+'.log');env={**os.environ,'GODOT':str(fake),'SOFT455_TEST_OUTPUT':text,'SOFT455_LOG':str(log)}
 result=subprocess.run(['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite "$SOFT455_LOG" test/soft_button_disabled_suite.gd --headless --path .'],cwd=repo,env=env,capture_output=True)
 (out/(name+'-wrapper.log')).write_bytes(result.stdout+result.stderr)
 rows.append({'name':name,'output':text,'expected_returncode':expect,'actual_returncode':result.returncode,'passed':result.returncode==expect})
record={'type':'controlled fake executable wrapper test; no Godot engine','scope':'new exact disabled completion registration','cases':rows,'passed':all(x['passed']for x in rows)}
(out/'result.json').write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record,indent=2));assert record['passed']
