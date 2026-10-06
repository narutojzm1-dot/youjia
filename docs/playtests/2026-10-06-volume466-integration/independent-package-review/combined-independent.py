from pathlib import Path
import ast,hashlib,json,subprocess,re,datetime
O=Path('/tmp/volume466-independent-evidence');O.mkdir(exist_ok=True)
code=Path('/tmp/photo447-full-pck-independent.py').read_text();tree=ast.parse(code);f=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='parse');ns={};exec('from pathlib import Path\nimport struct,hashlib,json\n'+ast.unparse(f),ns)
a=ns['parse']('/dev/shm/volume466-web-v1/index.pck');b=ns['parse']('/dev/shm/volume466-web-v2/index.pck')
add=sorted(b['files'].keys()-a['files'].keys());rem=sorted(a['files'].keys()-b['files'].keys());ch={k:{'old':a['files'][k],'new':b['files'][k]}for k in a['files'].keys()&b['files'].keys() if a['files'][k]!=b['files'][k]}
assert not add and not rem
q=Path('/dev/shm/volume466-candidate-qa');arch=Path('/dev/shm/youjia-volume466/docs/playtests/2026-10-06-volume466-integration/browser-candidate-146c')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
raw={str(p.relative_to(q)):sha(p)for p in q.rglob('*')if p.is_file()};copy={str(p.relative_to(arch)):sha(p)for p in arch.rglob('*')if p.is_file()};assert raw==copy and len(raw)==55 and len(list(q.glob('*.png')))==44
for l in (q/'SHA256SUMS').read_text().splitlines():s,n=l.split('  ',1);assert raw[n]==s
r=json.loads((q/'result.json').read_text());cmds=[e['command']for e in r['inputs']if 'command'in e];assert len([c for c in cmds if c['op']=='new'])==1;assert not [c for c in cmds if c['op']=='db'];assert not r['errors'] and not [c for c in r['console']if c['type']=='error'];assert len(r['bindings'])==2
for binding in r['bindings']:
 assert binding['manifest']['sourceCommit']=='146c3711537e4fa6657f1fd54e7472747cd0b10d'
 assert binding['pck']['bytes']==a['bytes'] and binding['pck']['sha256']==a['sha256']
 assert len(binding['dependency_checks'])==11
 for dep in binding['dependency_checks']:assert dep['status']==200 and dep['sha256']==binding['manifest']['files'][dep['path']]['sha256']
logs=[]
for d,fn in [('combined-v1','process-results.json'),('export-v2','process-result.json')]:
 p=Path('/dev/shm/volume466-evidence')/d;lst=json.loads((p/fn).read_text());lst=lst if isinstance(lst,list)else[lst]
 for v in lst:
  lp=p/v.get('log','export.log');assert sha(lp)==v['log_sha256'];assert v['direct_exit']==0 and not v['strict_error_lines'];lines=lp.read_text().splitlines();assert not [s for s in lines if re.match(r'^(ERROR|SCRIPT ERROR):',s)]
  if 'completion_lines'in v: assert v['completion_lines']==['EXPLORATION SLICE PASS 278/278 failures=[]'] and v['completion_lines'][0] in lines
  logs.append({'stage':d,'name':v.get('name','export'),'sha256':sha(lp),'direct_exit':0,'completion':v.get('completion_lines')})
s={'verified_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_source':'146c3711537e4fa6657f1fd54e7472747cd0b10d','combined_source':'49cf808ae6854406851592301e843bb557639500','old_pck':{k:v for k,v in a.items()if k!='files'},'new_pck':{k:v for k,v in b.items()if k!='files'},'added_members':add,'removed_members':rem,'changed_members':ch,'identical_member_count':len(a['files'])-len(ch),'qa55_files_exact':True,'qa44_pngs':True,'qa54_sums_pass':True,'qa1_context0_DB':True,'qa2_bindings_pass':True,'logs':logs}
(O/'combined-web-verification.json').write_text(json.dumps(s,ensure_ascii=False,indent=2)+'\n');print(json.dumps({'pckmembers':len(a['files']),'identical':s['identical_member_count'],'changed':list(ch),'qa55_exact':True,'logs':logs},indent=2))
