"""PR473 ordinary Chinese tooltip hover/leave/rehover/open/return candidate QA; no game/business state injection."""
import argparse,sys,json,time,hashlib,traceback,os
from pathlib import Path
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--url',required=True);ap.add_argument('--runtime',required=True);ap.add_argument('--entry',required=True);ap.add_argument('--pck-sha256',required=True);ap.add_argument('--pck-bytes',type=int,required=True);ap.add_argument('--out',required=True);ap.add_argument('--manifest',default='game-release.json');ap.add_argument('--tree',required=True);ap.add_argument('--manifest-sha256',required=True);a=ap.parse_args()
assert os.environ.get('TOOLTIP473_BROWSER_WINDOW') == 'granted', 'Requires explicit root sole-browser grant'
OUT=Path(a.out);OUT.mkdir(exist_ok=False);BASE=a.url.rstrip('/')+'/'
r={'source':a.runtime,'entry':a.entry,'expected_pck_sha256':a.pck_sha256,'expected_pck_bytes':a.pck_bytes,'inputs':[],'bindings':[],'errors':[],'console':[],'asset_responses':[],'browser_args':['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--renderer-process-limit=1'],'started_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'limits':['ordinary mouse/keyboard only; no save/game state/seed/time setters','browser media emulation at context creation, not physical device/OS setting','ordinary Chinese tooltip only; Main startup forces zh-CN and UI has no language selector; English only native controlled coverage; no touch382/focus459/input-race/audio/storage claims','no hearing or complete storage acceptance']}
def flush():(OUT/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
def event(v):r['inputs'].append(dict(v,utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),monotonic=time.monotonic()));flush()
def unique(name):
 p=OUT/name
 if p.exists():raise RuntimeError('Refuse overwrite '+str(p))
 return p
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--renderer-process-limit=1'])
 ctx=None;pg=None;case='';last_action=0.0
 def bind(stage):
  q=pg.request.get(BASE+a.manifest+'?tooltip473='+str(time.time()));manifest=q.json();assert q.status==200 and manifest.get('sourceCommit',manifest.get('source'))==a.runtime and manifest['entry']==a.entry and manifest['candidateOnly'] is True and all(manifest[k]==a.runtime for k in ('source','sourceCommit') if k in manifest),manifest
  assert manifest.get('sourceTree')==a.tree and manifest.get('schema')=='youjia.candidate/v1',manifest
  assert hashlib.sha256(q.body()).hexdigest()==a.manifest_sha256, 'Frozen manifest hash changed'
  assert manifest['files'][a.entry+'.pck']['sha256']==a.pck_sha256 and manifest['files'][a.entry+'.pck']['bytes']==a.pck_bytes
  html=pg.request.get(BASE+'?tooltip473='+str(time.time()));assert html.status==200 and hashlib.sha256(html.body()).hexdigest()==manifest['files']['index.html']['sha256']
  package=pg.request.get(BASE+a.entry+'.pck?tooltip473='+str(time.time()));body=package.body();nbytes=len(body);sha=hashlib.sha256(body).hexdigest();pckstatus=package.status;assert pckstatus==200 and nbytes==a.pck_bytes and sha==a.pck_sha256;del body;package.dispose()
  unique(case+'-'+stage+'-manifest.json').write_bytes(q.body());unique(case+'-'+stage+'-index.html').write_bytes(html.body())
  r['bindings'].append({'case':case,'stage':stage,'manifest':manifest,'html_status':html.status,'html_sha256':hashlib.sha256(html.body()).hexdigest(),'pck':{'status':pckstatus,'bytes':nbytes,'sha256':sha},'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())});
  module_checks=[]
  for filename,want in manifest['files'].items():
   if filename.startswith('web/save/') or filename=='open-source-licenses.html':
    response=pg.request.get(BASE+filename+'?tooltip473='+str(time.time()));payload=response.body();actual={'path':filename,'status':response.status,'bytes':len(payload),'sha256':hashlib.sha256(payload).hexdigest()};assert actual['status']==200 and actual['bytes']==want['bytes'] and actual['sha256']==want['sha256'];module_checks.append(actual);del payload;response.dispose()
  assert len([x for x in module_checks if x['path'].startswith('web/save/')])==10;assert any(x['path']=='open-source-licenses.html' for x in module_checks);r['bindings'][-1]['dependency_checks']=module_checks;q.dispose();html.dispose();flush()
 def shot(name):
  event({'screenshot_request':name,'case':case});pg.screenshot(path=str(unique(name+'.png')),scale='device');event({'screenshot_complete':name,'case':case})
 def new_case(c):
  global ctx,pg,case
  if ctx is not None:raise RuntimeError('Close current context explicitly before the next fresh case')
  assert c['motion']=='no-preference', 'This E2E plan uses ordinary Chinese normal-animation only'
  assert (int(c['width']),int(c['height'])) == (1280,720), 'Single fresh desktop context, resize in same page'
  case=c['name']
  if ctx is None:ctx=b.new_context(viewport={'width':c['width'],'height':c['height']},device_scale_factor=2,reduced_motion=c['motion'])
  pg=ctx.new_page()
  pg.on('pageerror',lambda e:r['errors'].append({'case':case,'error':str(e)}));pg.on('console',lambda m:r['console'].append({'case':case,'type':m.type,'text':m.text}));pg.on('crash',lambda:r['errors'].append({'case':case,'crash':True}));pg.on('response',lambda q:r['asset_responses'].append({'case':case,'url':q.url,'status':q.status}) if any(q.url.split('?')[0].endswith(x) for x in ('.js','.wasm','.pck','.mjs')) else None)
  pg.add_init_script("window.qaFirstFrame=false;addEventListener('youjia:first-frame',()=>window.qaFirstFrame=true)");bind('before');nav=pg.goto(BASE+'?tooltip473='+str(time.time()));actual_html=hashlib.sha256(nav.body()).hexdigest();assert actual_html==r['bindings'][-1]['html_sha256'];r['bindings'][-1]['loaded_html_sha256']=actual_html;pg.wait_for_function('window.qaFirstFrame',timeout=180000);assert pg.locator('html').get_attribute('data-build')==a.entry;pg.wait_for_timeout(700);event({'case_open':case,'width':c['width'],'height':c['height'],'motion':c['motion'],'actual_dpr':pg.evaluate('devicePixelRatio'),'actual_reduce':pg.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")});shot(case+'-title');print('READY',case,flush=True)
 try:
  for line in sys.stdin:
   cmds=json.loads(line)
   if isinstance(cmds,dict):cmds=[cmds]
   stop=False
   for c in cmds:
    event({'command':c,'case':case});op=c['op']
    if op=='new':new_case(c)
    elif op=='resize':
     assert (int(c['width']),int(c['height'])) in [(390,844),(568,320),(1280,720)]
     pg.set_viewport_size({'width':int(c['width']),'height':int(c['height'])});pg.wait_for_timeout(550);event({'viewport':pg.viewport_size,'actual_dpr':pg.evaluate('devicePixelRatio')})
    elif op=='move':pg.mouse.move(c['x'],c['y'],steps=int(c.get('steps',1)))
    elif op=='click':
     gap=0.55-(time.monotonic()-last_action)
     if gap>0:pg.wait_for_timeout(gap*1000)
     pg.mouse.click(c['x'],c['y']);last_action=time.monotonic();event({'actual_click':{'x':c['x'],'y':c['y']},'minimum_independent_action_spacing_ms':550})
    elif op=='key':
     gap=0.55-(time.monotonic()-last_action)
     if gap>0:pg.wait_for_timeout(gap*1000)
     pg.keyboard.press(c['key']);last_action=time.monotonic();event({'actual_key':c['key'],'minimum_independent_action_spacing_ms':550})
    elif op=='wait':pg.wait_for_timeout(min(15000,int(c['ms'])))
    elif op=='shot':shot(c['name'])
    elif op=='burst':
     for i in range(min(15,int(c.get('count',6)))):
      if i:pg.wait_for_timeout(min(1000,int(c.get('interval_ms',0))))
      shot(c['name']+'-%02d'%i)
    elif op=='close':bind('after');ctx.close();event({'case_closed':case});ctx=None;pg=None
    elif op=='end':
     if ctx is not None:bind('after');ctx.close();event({'case_closed':case});ctx=None;pg=None
     stop=True;break
    else:raise ValueError(op)
   flush();print('DONE',flush=True)
   if stop:break
 except BaseException:
  r['driver_error']=traceback.format_exc();print(r['driver_error'],flush=True);raise
 finally:
  if ctx is not None:ctx.close()
  b.close();r['closed_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime());(OUT/'run.py').write_text(Path(__file__).read_text());flush()
