from pathlib import Path
import subprocess,json,time,datetime,sys
out=Path(__file__).parent;repo='narutojzm1-dot/youjia';run=39046332348
def api(path):return json.loads(subprocess.check_output(['gh','api','repos/'+repo+'/'+path]).decode())
deadline=time.monotonic()+1800
previous=None
while time.monotonic()<deadline:
 d=api('actions/runs/'+str(run))
 if d['status']=='completed':
  if d['conclusion']!='success':
   (out/'publish-failed.json').write_text(json.dumps(d,indent=2));print('PUBLISH_FAILED '+str(d['conclusion']),flush=True);sys.exit(2)
  break
 jobs=api('actions/runs/'+str(run)+'/jobs')['jobs']
 active=[s['name'] for j in jobs for s in j['steps'] if s['status']=='in_progress']
 if active!=previous:print('PUBLISH_ACTIVE '+json.dumps(active),flush=True);previous=active
 time.sleep(40)
else:raise TimeoutError('Publication monitoring deadline, not assumed success')
g=api('git/ref/heads/gh-pages')['object']['sha']
while time.monotonic()<deadline:
 rows=api('actions/runs?head_sha='+g+'&per_page=20')['workflow_runs']
 page=next((r for r in rows if 'pages' in r['name'].lower()),None)
 if page and page['status']=='completed':
  if page['conclusion']!='success':
   (out/'pages-failed.json').write_text(json.dumps(page,indent=2));raise RuntimeError('Pages failed')
  result={'publish':{'id':d['id'],'head_sha':d['head_sha'],'conclusion':d['conclusion']},'pages':{'id':page['id'],'head_sha':page['head_sha'],'conclusion':page['conclusion']},'gh_pages_commit':g,'recorded_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
  (out/'publish-complete.json').write_text(json.dumps(result,indent=2)+'\n')
  print('PUBLISH_PAGES_SUCCESS '+json.dumps(result),flush=True);break
 if previous!='pages':print('WAIT_PAGES '+g,flush=True);previous='pages'
 time.sleep(30)
else:raise TimeoutError('Pages monitoring deadline')
