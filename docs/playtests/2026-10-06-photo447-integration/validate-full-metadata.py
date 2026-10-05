from pathlib import Path
import json,subprocess,os,hashlib
root=Path('/tmp/youjia-photo447');out=Path('/dev/shm/photo447-evidence');dest=Path('/dev/shm/photo447-full-export');dest.mkdir(exist_ok=False)
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
assert subprocess.check_output(['git','status','--porcelain'],cwd=root,text=True)==''
metadata=['game-sharing.json','game-verification.json','template.json','template-provenance.json']
records={}
for name in metadata:
 b=(root/name).read_bytes(); assert b==subprocess.check_output(['git','show',source+':'+name],cwd=root)
 records[name]={'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
(out/'full-metadata-input.json').write_text(json.dumps({'source':source,'tree':subprocess.check_output(['git','rev-parse','HEAD^{tree}'],cwd=root,text=True).strip(),'metadata':records,'old_candidate_retained':'/dev/shm/photo447-preview','old_candidate_source':'85217509f369e2dc06495bb1fa4ff1649b181a47','old_candidate_pck_sha256':'812144231f60d96c5b565d0cf735982b356e2efece0eeb0d4ffde865b600e030'},indent=2)+'\n')
env=os.environ.copy();env.update({'GODOT':'/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64','XDG_DATA_HOME':'/dev/shm/photo447-state/post-gate/data','XDG_CONFIG_HOME':'/dev/shm/photo447-state/post-gate/config','XDG_CACHE_HOME':'/dev/shm/photo447-state/post-gate/cache','YOUJIA_TEST_ISOLATED_DATA':'/dev/shm/photo447-state/post-gate/data'})
steps=[('full-metadata-import',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot /dev/shm/photo447-evidence/full-metadata-import.log --headless --path . --editor --import --quit']),('full-metadata-export',['bash','-c','source tools/lib/verified_godot.sh; XDG_DATA_HOME=/tmp/262-export-state/data run_verified_godot /dev/shm/photo447-evidence/full-metadata-export.log --headless --path . --export-release Web /dev/shm/photo447-full-export/index.html'])]
results=[]
for name,args in steps:
 with (out/(name+'-console.log')).open('wb') as f:done=subprocess.run(args,cwd=root,env=env,stdout=f,stderr=subprocess.STDOUT)
 result={'step':name,'args':args,'exit_code':done.returncode};results.append(result)
 (out/'full-metadata-exit-codes.json').write_text(json.dumps({'source':source,'steps':results},indent=2)+'\n')
 print(json.dumps(result),flush=True)
 if done.returncode:raise SystemExit(done.returncode)
files={}
for p in sorted(dest.iterdir()):
 if p.is_file():
  b=p.read_bytes(); files[p.name]={'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
for name in ['index.html','index.js','index.wasm','index.pck']:assert files[name]['bytes']>0
(out/'full-metadata-export-files.json').write_text(json.dumps(files,indent=2)+'\n')
print('FULL_METADATA_IMPORT_AND_EXPORT_EXIT_0',flush=True)
