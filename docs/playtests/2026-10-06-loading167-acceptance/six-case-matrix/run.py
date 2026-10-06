"""Public loading167 QA: real HTTP abort/DOM retry; no game state injection. Interactive, one browser."""
import argparse,asyncio,sys,json,time,hashlib,traceback,os
from pathlib import Path
from urllib.parse import urlsplit
from playwright.async_api import async_playwright
P=argparse.ArgumentParser();P.add_argument('--out',required=True);P.add_argument('--url',default='https://narutojzm1-dot.github.io/youjia/');A=P.parse_args()
OUT=Path(A.out);OUT.mkdir(exist_ok=False);BASE=A.url.rstrip('/')+'/'
SOURCE='49596fa93bff3c29edfe441898017158c6e469a3';ENTRY='game-49596fa';PCK_SHA='c851ac2b66ef6bba5211b7ba8488173c6b6a336ee7508d6150a5f5ccd488f930';PCK_BYTES=27090652
LICENSE_SHA='9215f5fdd50039a9b6f3d8f0271cbc21bbdf64b917fb118dd29c8a16b9974e00';LICENSE_BYTES=147966
ARGS=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--renderer-process-limit=1']
R={'source':SOURCE,'entry':ENTRY,'role':'CODEX-LEAD delegated QA support; not GAME-QA impersonation','started_utc':None,'cases':[],'browser_args':ARGS,'limits':['Desktop browser viewport/media emulation; not physical device/OS change','Exactly one injected engine-JS abort per context; expected errors retained','First WASM request held at least4 seconds through capture; not natural performance','No internal game/Tuning/save/seed/time setters; no synthetic failure DOM','Screenshots/CSS sampling cannot prove every animation frame; ordinary yard entry only']}
def utc():return time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
def flush():(OUT/'result.json').write_text(json.dumps(R,ensure_ascii=False,indent=2))
def put(name,data):
 p=OUT/name;assert not p.exists(),name;p.write_bytes(data if isinstance(data,bytes) else data.encode())
def event(c,k,**v):c['events'].append(dict(event=k,utc=utc(),monotonic=time.monotonic(),**v));flush()
def asset(url):return urlsplit(url).path.rsplit('/',1)[-1].endswith(('.wasm','.js','.pck','.mjs'))
DOM="""() => {
const ids=['loading','game-title','loading-status','loading-detail','loading-progress','loading-notice','loading-retry','loading-build'];let o={};
for(const id of ids){const e=document.getElementById(id),r=e.getBoundingClientRect(),s=getComputedStyle(e);o[id]={text:e.innerText||e.textContent,hidden:e.hidden,display:s.display,rect:{x:r.x,y:r.y,w:r.width,h:r.height},fontSize:s.fontSize,lineHeight:s.lineHeight,color:s.color,backgroundColor:s.backgroundColor,transform:s.transform,animationName:s.animationName,animationDuration:s.animationDuration,transitionDuration:s.transitionDuration,clientWidth:e.clientWidth,scrollWidth:e.scrollWidth,clientHeight:e.clientHeight,scrollHeight:e.scrollHeight};}
const e=document.getElementById('loading');o.pseudo={};for(const q of ['::before','::after']){const s=getComputedStyle(e,q);o.pseudo[q]={transform:s.transform,animationName:s.animationName,animationDuration:s.animationDuration,transitionDuration:s.transitionDuration,backgroundSize:s.backgroundSize,backgroundPosition:s.backgroundPosition,hasBackground:s.backgroundImage!=='none'};}
return {elements:o,viewport:{w:innerWidth,h:innerHeight,dpr:devicePixelRatio},reduce:matchMedia('(prefers-reduced-motion: reduce)').matches,build:document.documentElement.dataset.build,firstFrameObserved:window.__qa167FirstFrame===true,loadTimings:window.youjiaLoadTimings||null};} """
async def main():
 R['started_utc']=utc();flush();ctx=None;pg=None;c=None;tasks=set();global_html=None;manifest=None
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=ARGS)
  R['browser_version']=browser.version;R['browser_opened_utc']=utc();flush()
  async def binding(stage):
   nonlocal global_html,manifest
   stamp=str(time.time_ns());headers={'Cache-Control':'no-cache'}
   q=await ctx.request.get(BASE+'game-release.json?qa167='+stamp,headers=headers);assert q.status==200;manifest=await q.json();assert manifest['sourceCommit']==SOURCE and manifest['entry']==ENTRY and manifest['storageModules']['entry']=='save-49596fa',manifest
   h=await ctx.request.get(BASE+'?qa167='+stamp,headers=headers);hb=await h.body();hh=hashlib.sha256(hb).hexdigest();assert h.status==200
   if global_html is None:global_html=hh
   assert hh==global_html,'Public HTML changed during matrix'
   qk=await ctx.request.get(BASE+ENTRY+'.pck?qa167='+stamp,headers=headers);kb=await qk.body();pk={'status':qk.status,'bytes':len(kb),'sha256':hashlib.sha256(kb).hexdigest()};assert pk=={'status':200,'bytes':PCK_BYTES,'sha256':PCK_SHA};del kb;await qk.dispose()
   deps=[]
   for name,want in manifest['storageModules']['sha256'].items():
    path=manifest['storageModules']['entry']+'/'+name;d=await ctx.request.get(BASE+path+'?qa167='+stamp,headers=headers);db=await d.body();record={'path':path,'status':d.status,'bytes':len(db),'sha256':hashlib.sha256(db).hexdigest()};assert record['status']==200 and record['sha256']==want;deps.append(record);del db;await d.dispose()
   assert len(deps)==10
   d=await ctx.request.get(BASE+'open-source-licenses.html?qa167='+stamp,headers=headers);db=await d.body();lic={'status':d.status,'bytes':len(db),'sha256':hashlib.sha256(db).hexdigest()};assert lic=={'status':200,'bytes':LICENSE_BYTES,'sha256':LICENSE_SHA};del db;await d.dispose()
   put(c['name']+'-'+stage+'-manifest.json',json.dumps(manifest,indent=2));put(c['name']+'-'+stage+'-index.html',hb)
   record={'stage':stage,'utc':utc(),'html_sha256':hh,'pck':pk,'storage_modules':deps,'license':lic};c['bindings'].append(record);await q.dispose();await h.dispose();flush()
  async def shot(stage):
   event(c,'screenshot_requested',stage=stage);name=c['name']+'-'+stage+'.png';await pg.screenshot(path=str(OUT/name),scale='css',timeout=30000);snap=await pg.evaluate(DOM);c['snapshots'].append({'stage':stage,'utc':utc(),'file':name,'dom':snap});event(c,'screenshot_completed',stage=stage)
  async def response_read(resp,record,expected_modules):
   if resp.status!=200:return
   path=urlsplit(resp.url).path;file=path.rsplit('/',1)[-1]
   if file.endswith('.mjs') and record.get('phase') not in ['controlled-initial-js-hold','expected-network-failure','dom-retry']:
    data=await resp.body();record['decoded_body_bytes']=len(data);record['sha256']=hashlib.sha256(data).hexdigest();del data
    if file.endswith('.pck'):assert record['sha256']==PCK_SHA and record['decoded_body_bytes']==PCK_BYTES
    else:assert record['sha256']==expected_modules[file]
   flush()
  async def begin(cmd):
   nonlocal ctx,pg,c
   assert ctx is None,'Previous context must be closed'
   c={'name':cmd['name'],'viewport':{'width':cmd['width'],'height':cmd['height']},'motion':cmd['motion'],'events':[],'bindings':[],'snapshots':[],'console':[],'page_errors':[],'requests_failed':[],'responses':[],'cdp_responses':[],'cdp_transfer_bytes':[],'response_body_errors':[]};R['cases'].append(c)
   ctx=await browser.new_context(viewport=c['viewport'],device_scale_factor=1,reduced_motion=c['motion'],service_workers='block');pg=await ctx.new_page();cdp=await ctx.new_cdp_session(pg);await cdp.send('Network.enable');await cdp.send('Network.setCacheDisabled',{'cacheDisabled':True});c['cache_controls']={'fresh_context':True,'service_workers':'block','Network.setCacheDisabled':True,'routing_disables_http_cache':True}
   await binding('before')
   local_c=c;modules=dict(manifest['storageModules']['sha256'])
   pg.on('pageerror',lambda e:local_c['page_errors'].append({'utc':utc(),'stage':local_c.get('phase'),'error':str(e)}))
   pg.on('console',lambda m:local_c['console'].append({'utc':utc(),'stage':local_c.get('phase'),'type':m.type,'text':m.text}))
   pg.on('requestfailed',lambda req:local_c['requests_failed'].append({'utc':utc(),'stage':local_c.get('phase'),'url':req.url,'failure':req.failure}))
   pg.on('crash',lambda:local_c['page_errors'].append({'utc':utc(),'crash':True}))
   def response(resp):
    if not asset(resp.url):return
    record={'url':resp.url,'status':resp.status,'utc':utc(),'phase':local_c.get('phase')};local_c['responses'].append(record)
    if local_c.get('phase') in ['controlled-initial-js-hold','expected-network-failure','dom-retry']:record['body_hash_coverage']='Excluded: old-navigation body can become stale during actual DOM retry reload'
    if urlsplit(resp.url).path.endswith('.pck'):record['body_hash_coverage']='Not collected via DevTools; public HTTP bytes separately hash checked before/after'
    task=asyncio.create_task(response_read(resp,record,modules));tasks.add(task)
    def done(t):
     tasks.discard(t)
     if not t.cancelled() and t.exception():local_c['response_body_errors'].append(str(t.exception()))
    task.add_done_callback(done)
   pg.on('response',response)
   ids=set()
   def cdp_response(v):
    rr=v['response']
    if asset(rr['url']):ids.add(v['requestId']);local_c['cdp_responses'].append({'requestId':v['requestId'],'url':rr['url'],'status':rr['status'],'fromDiskCache':rr.get('fromDiskCache',False),'fromServiceWorker':rr.get('fromServiceWorker',False),'fromPrefetchCache':rr.get('fromPrefetchCache',False),'mimeType':rr.get('mimeType')})
   cdp.on('Network.responseReceived',cdp_response);cdp.on('Network.loadingFinished',lambda v:local_c['cdp_transfer_bytes'].append({'requestId':v['requestId'],'encodedDataLength':v['encodedDataLength']}) if v['requestId'] in ids else None)
   first_js=asyncio.Event();release_js=asyncio.Event();wasm_started=asyncio.Event();wasm_shots=asyncio.Event();wasm_done=asyncio.Event();js_count=0;wasm_count=0
   async def route(reqroute):
    nonlocal js_count,wasm_count
    name=urlsplit(reqroute.request.url).path.rsplit('/',1)[-1]
    if name==ENTRY+'.js':
     js_count+=1
     if js_count==1:
      start=time.monotonic();event(local_c,'injected_js_hold_start',url=reqroute.request.url);first_js.set();await release_js.wait();await reqroute.abort('failed');event(local_c,'injected_js_abort',url=reqroute.request.url,held_seconds=time.monotonic()-start);return
    if name==ENTRY+'.wasm':
     wasm_count+=1
     if wasm_count==1:
      start=time.monotonic();event(local_c,'wasm_hold_start',url=reqroute.request.url);wasm_started.set();await asyncio.sleep(4);await wasm_shots.wait();await reqroute.continue_();event(local_c,'wasm_hold_released',held_seconds=time.monotonic()-start);wasm_done.set();return
    await reqroute.continue_()
   await ctx.route('**/*',route)
   await pg.add_init_script("window.__qa167FirstFrame=false;addEventListener('youjia:first-frame',()=>{window.__qa167FirstFrame=true},{once:true});")
   c['phase']='controlled-initial-js-hold';nav=await pg.goto(BASE+'?qa167='+str(time.time_ns()),wait_until='domcontentloaded',timeout=90000);nb=await nav.body();c['navigation_html_sha256']=hashlib.sha256(nb).hexdigest();assert c['navigation_html_sha256']==global_html
   await asyncio.wait_for(first_js.wait(),30);await pg.locator('#loading').wait_for(state='visible');await shot('01-loading-initial');release_js.set();c['phase']='expected-network-failure'
   await pg.locator('#loading-retry').wait_for(state='visible',timeout=45000);assert '游戏加载失败' in await pg.locator('#loading-status').inner_text();await shot('02-network-failure')
   c['phase']='dom-retry';event(c,'dom_retry_click',selector='#loading-retry')
   async with pg.expect_navigation(wait_until='domcontentloaded',timeout=90000) as nv:await pg.locator('#loading-retry').click()
   nresp=await nv.value;assert hashlib.sha256(await nresp.body()).hexdigest()==global_html
   c['phase']='retry-real-wasm-hold';await asyncio.wait_for(wasm_started.wait(),45);await shot('03-retry-loading-a');await asyncio.sleep(1);await shot('04-retry-loading-b');wasm_shots.set();await asyncio.wait_for(wasm_done.wait(),30)
   c['phase']='retry-engine-start';await pg.wait_for_function('window.__qa167FirstFrame===true',timeout=180000);await pg.wait_for_function("document.getElementById('loading').hidden===true",timeout=30000);assert await pg.locator('html').get_attribute('data-build')==ENTRY;assert await pg.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")==(cmd['motion']=='reduce')
   await pg.wait_for_timeout(300);await shot('05-retry-title');c['route_counts']={'engine_js':js_count,'wasm':wasm_count,'intentional_aborts':1};c['phase']='title-ready';event(c,'title_ready');print('TITLE_READY '+c['name'],flush=True)
  async def close_case():
   nonlocal ctx,pg,c
   assert ctx is not None
   if tasks:await asyncio.gather(*list(tasks),return_exceptions=True)
   assert not c['response_body_errors'],c['response_body_errors']
   assert not c['page_errors'],c['page_errors']
   failures=c['requests_failed'];assert len(failures)==1 and urlsplit(failures[0]['url']).path.endswith('/'+ENTRY+'.js') and failures[0]['failure']=='net::ERR_FAILED',failures
   errors=[x for x in c['console'] if x['type']=='error'];assert len(errors)==2,errors
   assert sum(x['text']=='Failed to load resource: net::ERR_FAILED' for x in errors)==1
   assert sum(x['text'].startswith('[game-loading] Startup failed Error: Engine script could not be loaded') for x in errors)==1
   assert all(x['stage'] in ['controlled-initial-js-hold','expected-network-failure'] for x in errors),errors
   c['expected_error_whitelist']={'network':[{'url':failures[0]['url'],'failure':'net::ERR_FAILED'}],'console':errors,'all_page_errors_must_be_empty':True,'unexpected_errors_ignored':False}
   assert len([x for x in c['responses'] if x['url'].split('?')[0].endswith('/'+ENTRY+'.pck') and x['status']==200])>=1
   c['pck_browser_binding_limit']='Actual browser URL/200/cache flags/encoded transfer recorded; exact public PCK bytes separately downloaded before/after. No claim of browser response.body hash.'
   assert len({urlsplit(x['url']).path.rsplit('/',1)[-1] for x in c['responses'] if x.get('sha256') and x['url'].split('?')[0].endswith('.mjs')})==10
   assert not any(x['fromDiskCache'] or x['fromServiceWorker'] or x['fromPrefetchCache'] for x in c['cdp_responses'])
   await binding('after');await ctx.close();event(c,'context_closed');ctx=None;pg=None;print('CONTEXT_CLOSED '+c['name'],flush=True)
  try:
   while True:
    line=await asyncio.to_thread(sys.stdin.readline)
    if not line:break
    commands=json.loads(line);commands=commands if isinstance(commands,list) else [commands]
    stop=False
    for cmd in commands:
     if cmd['op']=='case':await begin(cmd)
     elif cmd['op']=='enter':
      assert ctx is not None;c['phase']='ordinary-yard-entry';event(c,'ordinary_mouse_click',x=cmd['x'],y=cmd['y']);await pg.mouse.click(cmd['x'],cmd['y']);await pg.wait_for_timeout(900);await shot('06-yard-entered');await pg.wait_for_timeout(450);await shot('07-yard-stable');print('YARD_CAPTURED '+c['name'],flush=True)
     elif cmd['op']=='close':await close_case()
     elif cmd['op']=='end':
      if ctx is not None:await close_case()
      stop=True;break
     else:raise ValueError(cmd)
    flush();print('DONE',flush=True)
    if stop:break
  except BaseException:
   R['driver_error']=traceback.format_exc();flush();print(R['driver_error'],flush=True);raise
  finally:
   if ctx is not None:await ctx.close();event(c,'context_closed_in_finally')
   await browser.close();R['browser_closed_utc']=utc();put('run.py',Path(__file__).read_bytes());flush();print('BROWSER_CLOSED '+R['browser_closed_utc'],flush=True)
asyncio.run(main())
