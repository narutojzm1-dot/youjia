from pathlib import Path
import json,subprocess,os,shutil
root=Path('/tmp/youjia-photo447');out=Path('/dev/shm/photo447-evidence')
first=out/'post-gate-before-reimport-failure';first.mkdir(exist_ok=False)
for name in ['gate-contract-console.log','mat-completion-console.log','post-gate-mat.log','post-gate-exit-codes.json']:
 shutil.move(str(out/name),str(first/name))
(first/'cause.json').write_text(json.dumps({'cause':'Tracked .png.import files were restored to repository versions to merge main; four cloud-band mappings contain old placeholder cache paths. This standalone recheck omitted the required editor import before loading the suite.','remedy':'Run normal editor import, then rerun the same suite and strict verified export. No source image or assertion changes.','product_bug_claim':False},indent=2)+'\n')
env=os.environ.copy();env.update({'GODOT':'/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64','XDG_DATA_HOME':'/dev/shm/photo447-state/post-gate/data','XDG_CONFIG_HOME':'/dev/shm/photo447-state/post-gate/config','XDG_CACHE_HOME':'/dev/shm/photo447-state/post-gate/cache','YOUJIA_TEST_ISOLATED_DATA':'/dev/shm/photo447-state/post-gate/data'})
steps=[('post-gate-import',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /dev/shm/photo447-evidence/post-gate-import.log --headless --path . --editor --import --quit']),('gate-contract',['bash','test/godot_gate_test.sh']),('mat-completion',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite /dev/shm/photo447-evidence/post-gate-mat.log test/photo_arrival_mat_suite.gd --headless --path .']),('verified-export',['bash','-c','source tools/lib/verified_godot.sh; XDG_DATA_HOME=/tmp/262-export-state/data run_verified_godot /dev/shm/photo447-evidence/verified-export.log --headless --path . --export-release Web /dev/shm/photo447-preview/index.html'])]
results=[]
for name,args in steps:
 with (out/(name+'-console.log')).open('wb') as f:done=subprocess.run(args,cwd=root,env=env,stdout=f,stderr=subprocess.STDOUT)
 result={'step':name,'args':args,'exit_code':done.returncode};results.append(result)
 (out/'post-gate-exit-codes.json').write_text(json.dumps({'source':'85217509f369e2dc06495bb1fa4ff1649b181a47','steps':results},indent=2)+'\n')
 print(json.dumps(result),flush=True)
 if done.returncode:raise SystemExit(done.returncode)
for name in ['index.html','index.js','index.wasm','index.pck']:assert (Path('/dev/shm/photo447-preview')/name).stat().st_size>0
print('POST_GATE_VALIDATION_AND_EXPORT_EXIT_0',flush=True)
