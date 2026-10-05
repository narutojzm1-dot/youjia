from pathlib import Path
import json,hashlib,subprocess,shutil
repo=Path('/tmp/youjia-photo461');out=Path('/tmp/photo461-web');evidence=Path('/tmp/photo461-evidence')
source=json.loads((evidence/'source.json').read_text());assert (evidence/'run.exit').read_text().strip()=='0'
for src in [*(repo/'web/save').glob('*.mjs'),repo/'site/open-source-licenses.html']:
 relative='web/save/'+src.name if src.suffix=='.mjs' else 'open-source-licenses.html'
 expected=subprocess.check_output(['git','-C',str(repo),'show',source['runtime_source']+':'+str(src.relative_to(repo))]);assert src.read_bytes()==expected
 target=out/relative;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(expected)
files={str(p.relative_to(out)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file() and p.name!='candidate-release.json'}
metadata={'schema':'youjia.candidate/v1','sourceCommit':source['runtime_source'],'source':source['runtime_source'],'sourceTree':source['tree'],'base':source['base'],'original':source['original'],'engine':'4.7.2.stable.official.ed1daf0bf','entry':'index','candidateOnly':True,'files':files,'storageModules':{'entry':'web/save','sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest()for p in sorted((out/'web/save').glob('*.mjs'))}}}
(out/'candidate-release.json').write_text(json.dumps(metadata,indent=2)+'\n');(evidence/'candidate-release.json').write_text(json.dumps(metadata,indent=2)+'\n')
print(json.dumps({'source':source['runtime_source'],'pck':files['index.pck'],'moduleCount':len(metadata['storageModules']['sha256']),'export':str(out)},indent=2))
