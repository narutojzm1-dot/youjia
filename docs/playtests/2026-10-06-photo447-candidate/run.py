"""Ordinary-input candidate QA; never injects game business state."""
import argparse,sys,json,time,hashlib,traceback
from pathlib import Path
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--url',required=True);ap.add_argument('--runtime',required=True);ap.add_argument('--entry',required=True);ap.add_argument('--pck-sha256',required=True);ap.add_argument('--pck-bytes',type=int,required=True);ap.add_argument('--out',required=True);a=ap.parse_args()
OUT=Path(a.out);OUT.mkdir(exist_ok=False);BASE=a.url.rstrip('/')+'/'
r={'source':a.runtime,'entry':a.entry,'expected_pck_sha256':a.pck_sha256,'expected_pck_bytes':a.pck_bytes,'inputs':[],'bindings':[],'errors':[],'console':[],'asset_responses':[],'started_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'limits':['ordinary mouse/keyboard only; no save/game state/seed/time setters','browser media emulation at context creation, not physical device/OS setting','screenshots require visual verification of actual photo hold; early/late fade cannot prove opaque full hold','no hearing or complete storage acceptance']}
READ_DB="""async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
def flush():(OUT/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
def event(v):r['inputs'].append(dict(v,utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),monotonic=time.monotonic()));flush()
def unique(name):
 p=OUT/name
 if p.exists():raise RuntimeError('Refuse overwrite '+str(p))
 return p
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 ctx=None;pg=None;case=''
 def bind(stage):
  q=pg.request.get(BASE+'candidate-release.json?photo447='+str(time.time()));manifest=q.json();assert q.status==200 and manifest['sourceCommit']==a.runtime,manifest
  html=pg.request.get(BASE+'?photo447='+str(time.time()));assert html.status==200 and hashlib.sha256(html.body()).hexdigest()==manifest['files']['index.html']['sha256']
  package=pg.request.get(BASE+a.entry+'.pck?photo447='+str(time.time()));body=package.body();nbytes=len(body);sha=hashlib.sha256(body).hexdigest();pckstatus=package.status;assert pckstatus==200 and nbytes==a.pck_bytes and sha==a.pck_sha256;del body;package.dispose()
  unique(case+'-'+stage+'-manifest.json').write_text(json.dumps(manifest,indent=2));unique(case+'-'+stage+'-index.html').write_text(html.text())
  r['bindings'].append({'case':case,'stage':stage,'manifest':manifest,'html_status':html.status,'html_sha256':hashlib.sha256(html.body()).hexdigest(),'pck':{'status':pckstatus,'bytes':nbytes,'sha256':sha},'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())});
  module_checks=[]
  for filename,want in manifest['files'].items():
   if filename.startswith('web/save/'):
    response=pg.request.get(BASE+filename+'?photo447='+str(time.time()));payload=response.body();actual={'path':filename,'status':response.status,'bytes':len(payload),'sha256':hashlib.sha256(payload).hexdigest()};assert actual['status']==200 and actual['bytes']==want['bytes'] and actual['sha256']==want['sha256'];module_checks.append(actual);del payload;response.dispose()
  r['bindings'][-1]['storage_module_checks']=module_checks;q.dispose();html.dispose();flush()
 def shot(name):
  event({'screenshot_request':name,'case':case});pg.screenshot(path=str(unique(name+'.png')),scale='css');event({'screenshot_complete':name,'case':case})
 def new_case(c):
  global ctx,pg,case
  if ctx is not None:
   bind('after')
   if c.get('preserve_context',False):pg.close();event({'page_closed_context_retained':case})
   else:ctx.close();event({'case_closed':case});ctx=None
  case=c['name']
  if ctx is None:ctx=b.new_context(viewport={'width':c['width'],'height':c['height']},device_scale_factor=1,reduced_motion=c['motion'])
  pg=ctx.new_page()
  pg.on('pageerror',lambda e:r['errors'].append({'case':case,'error':str(e)}));pg.on('console',lambda m:r['console'].append({'case':case,'type':m.type,'text':m.text}));pg.on('crash',lambda:r['errors'].append({'case':case,'crash':True}));pg.on('response',lambda q:r['asset_responses'].append({'case':case,'url':q.url,'status':q.status}) if any(q.url.split('?')[0].endswith(x) for x in ('.js','.wasm','.pck','.mjs')) else None)
  pg.add_init_script("window.qaFirstFrame=false;addEventListener('youjia:first-frame',()=>window.qaFirstFrame=true)");bind('before');nav=pg.goto(BASE+'?photo447='+str(time.time()));actual_html=hashlib.sha256(nav.body()).hexdigest();assert actual_html==r['bindings'][-1]['html_sha256'];r['bindings'][-1]['loaded_html_sha256']=actual_html;pg.wait_for_function('window.qaFirstFrame',timeout=180000);pg.wait_for_timeout(700);event({'case_open':case,'width':c['width'],'height':c['height'],'motion':c['motion'],'actual_reduce':pg.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")});shot(case+'-title');print('READY',case,flush=True)
 try:
  for line in sys.stdin:
   cmds=json.loads(line)
   if isinstance(cmds,dict):cmds=[cmds]
   stop=False
   for c in cmds:
    event({'command':c,'case':case});op=c['op']
    if op=='new':new_case(c)
    elif op=='click':pg.mouse.click(c['x'],c['y'])
    elif op=='key':pg.keyboard.press(c['key'])
    elif op=='hold':pg.keyboard.down(c['key']);pg.wait_for_timeout(min(5000,int(c['ms'])));pg.keyboard.up(c['key'])
    elif op=='wait':pg.wait_for_timeout(min(15000,int(c['ms'])))
    elif op=='shot':shot(c['name'])
    elif op=='burst':
     for i in range(min(15,int(c.get('count',6)))):
      if i:pg.wait_for_timeout(min(1000,int(c.get('interval_ms',0))))
      shot(c['name']+'-%02d'%i)
    elif op=='db':unique(c['name']+'.json').write_text(json.dumps(pg.evaluate(READ_DB),ensure_ascii=False,indent=2))
    elif op=='end':bind('after');ctx.close();event({'case_closed':case});ctx=None;stop=True;break
    else:raise ValueError(op)
   flush();print('DONE',flush=True)
   if stop:break
 except BaseException:
  r['driver_error']=traceback.format_exc();print(r['driver_error'],flush=True);raise
 finally:
  if ctx is not None:ctx.close()
  b.close();r['closed_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime());(OUT/'run.py').write_text(Path(__file__).read_text());flush()
