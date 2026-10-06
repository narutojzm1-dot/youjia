from pathlib import Path
import json,hashlib,subprocess,struct,datetime
repo=Path('/dev/shm/youjia-tooltip473');export=Path('/dev/shm/tooltip473-web');out=Path('/dev/shm/tooltip473-combined-run')
summary=json.loads((out/'result.json').read_text());manifest=json.loads((export/'game-release.json').read_text());source=summary['source']
assert summary['status']=='passed' and manifest['source']==source and manifest['sourceTree']==summary['tree']
sha=lambda b:hashlib.sha256(b).hexdigest()
files=[]
for name,expected in manifest['files'].items():
 data=(export/name).read_bytes();actual={'bytes':len(data),'sha256':sha(data)};assert actual==expected,(name,actual,expected);files.append({'path':name,**actual})
actual_names={str(p.relative_to(export)) for p in export.rglob('*') if p.is_file()};assert actual_names==set(manifest['files'])|{'game-release.json'}
modules=[]
for name,expected in manifest['storageModules']['sha256'].items():
 data=(export/'web/save'/name).read_bytes();sourcebytes=subprocess.check_output(['git','-C',str(repo),'show',source+':web/save/'+name]);assert data==sourcebytes and sha(data)==expected;modules.append({'name':name,'sha256':expected,'same_exact_source':True})
assert len(modules)==10
license=(export/'open-source-licenses.html').read_bytes();assert license==subprocess.check_output(['git','-C',str(repo),'show',source+':site/open-source-licenses.html'])
ns={};code=Path('/tmp/pr130-sparse-evidence/compare_pck_members.py').read_text().split('left_hash, left =')[0];exec(compile(code,'pck_reader','exec'),ns)
pcksha,members=ns['read_pck'](export/'index.pck');assert pcksha==summary['pck']['sha256']
metadata=[]
for name in ['game-sharing.json','game-verification.json','template.json','template-provenance.json','config/tuning.json','localization/zh-CN.json','localization/en.json']:
 sourcebytes=subprocess.check_output(['git','-C',str(repo),'show',source+':'+name]);assert members[name]==sourcebytes,name;metadata.append({'path':name,'bytes':len(sourcebytes),'sha256':sha(sourcebytes),'same_exact_source':True})
rows=[{'path':n,'bytes':len(b),'sha256':sha(b)} for n,b in sorted(members.items())]
records=[json.loads(x) for x in (out/'engine-processes.jsonl').read_text().splitlines()];assert len(records)==84 and sum(x['phase']=='daily' and x['args']!=['--version'] for x in records)==81 and sum(x['args']==['--version'] for x in records)==2 and sum(x['phase']=='export' for x in records)==1 and all(x['direct_exit']==0 for x in records)
report={'verified_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':source,'source_tree':summary['tree'],'all_static_files':files,'file_count':len(files),'manifest_sha256':sha((export/'game-release.json').read_bytes()),'pck_sha256':pcksha,'pck_member_count':len(members),'every_member_md5_valid':True,'pck_members':rows,'metadata':metadata,'storage_modules':modules,'license_same_source':True,'actual_engine_processes_including_export_and_version':len(records),'publisher_version_probe_processes':2,'all_engine_direct_exit_zero':True,'browser_run':False}
(out/'offline-export-verification.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ['all_static_files','pck_members','metadata','storage_modules']},indent=2))
