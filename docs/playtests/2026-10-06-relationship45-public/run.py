import sys,json,time,hashlib,traceback
from pathlib import Path
from playwright.sync_api import sync_playwright
OUT=Path('/tmp/relationship45-public');OUT.mkdir(exist_ok=False)
SOURCE='089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21'; ENTRY='game-089d453'; HASH='fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8'; BASE='https://narutojzm1-dot.github.io/youjia/'
READ_DB="""async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
r={'source':SOURCE,'entry':ENTRY,'expected_pck_bytes':27088396,'expected_pck_sha256':HASH,'inputs':[],'bindings':[],'errors':[],'console':[],'started_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'limits':['ordinary UI only, no seed/time/location/runtime/save injection','single fresh profile; at most 3 lead-away/return/release attempts then 90 seconds quiet observation','10 percent linger cannot be declared observed merely from saved memory or still frames','desktop Chromium; not physical device or audio comfort QA']}
def flush(): (OUT/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
def event(value):r['inputs'].append(dict(value,utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),monotonic=time.monotonic()));flush()
def unique(name):
 p=OUT/name
 if p.exists(): raise RuntimeError('Refuse overwrite '+str(p))
 return p
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 ctx=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=1)
 seq=0
 def bind(stage,full=True):
  data=pg.request.get(BASE+'game-release.json?relationship45='+str(time.time()),headers={'Cache-Control':'no-cache'});manifest=data.json();assert manifest['sourceCommit']==SOURCE,manifest
  html=pg.request.get(BASE+'?relationship45='+str(time.time()),headers={'Cache-Control':'no-cache'});assert 'data-build="'+ENTRY+'"' in html.text()
  v={'page':seq,'stage':stage,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'manifest':manifest,'manifest_status':data.status,'html_status':html.status,'html_sha256':hashlib.sha256(html.body()).hexdigest()}
  if full:
   q=pg.request.get(BASE+ENTRY+'.pck?relationship45='+str(time.time()),headers={'Cache-Control':'no-cache'});body=q.body();v['pck']={'status':q.status,'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest()};assert q.status==200 and len(body)==27088396 and v['pck']['sha256']==HASH,v
  r['bindings'].append(v);flush()
 def newpage():
  global pg,seq
  seq+=1;pg=ctx.new_page();pg.on('pageerror',lambda e:r['errors'].append({'page':seq,'error':str(e)}));pg.on('console',lambda m:r['console'].append({'page':seq,'type':m.type,'text':m.text}));pg.on('crash',lambda:r['errors'].append({'page':seq,'crash':True}));pg.add_init_script("window.qaFirstFrame=false;addEventListener('youjia:first-frame',()=>window.qaFirstFrame=true)");bind('before');pg.goto(BASE+'?relationship45='+str(time.time()));assert pg.locator('html').get_attribute('data-build')==ENTRY;pg.wait_for_function('window.qaFirstFrame',timeout=180000);pg.wait_for_timeout(1000);event({'page_open':seq});pg.screenshot(path=str(unique('page%d-title.png'%seq)));print('READY page',seq,flush=True)
 try:
  newpage()
  for line in sys.stdin:
   cmds=json.loads(line)
   if isinstance(cmds,dict):cmds=[cmds]
   stop=False
   for c in cmds:
    event({'command':c,'page':seq});op=c['op']
    if op=='click':pg.mouse.click(c['x'],c['y'])
    elif op=='move':pg.mouse.move(c['x'],c['y'])
    elif op=='key':pg.keyboard.press(c['key'])
    elif op=='hold':
     pg.keyboard.down(c['key']);pg.wait_for_timeout(min(15000,int(c['ms'])));pg.keyboard.up(c['key'])
    elif op=='wait':pg.wait_for_timeout(min(30000,int(c['ms'])))
    elif op=='shot':pg.screenshot(path=str(unique(c['name']+'.png')))
    elif op=='db':
     data=pg.evaluate(READ_DB);unique(c['name']+'.json').write_text(json.dumps(data,ensure_ascii=False,indent=2));brief=[]
     for db in data.values():
      rec=db.get('records',{});keys=rec.get('keys',[])
      for k,v in zip(keys,rec.get('values',[])):
       if isinstance(v,dict) and 'payload_bytes' in v:
        payload=json.loads(v['payload_bytes']);brief.append({'key':k,'generation':v.get('generation'),'memory':payload.get('animal_relationship_memory'),'album':payload.get('album'),'elapsed':payload.get('holiday_day_elapsed')})
     print('DB',c['name'],json.dumps(brief,ensure_ascii=False),flush=True)
    elif op=='reopen':bind('after');pg.close();event({'page_closed':seq});newpage()
    elif op=='end':bind('after');pg.close();event({'page_closed':seq});stop=True;break
    else:raise RuntimeError('Unknown command '+op)
   flush();print('DONE',flush=True)
   if stop:break
 except BaseException as e:r['driver_error']=traceback.format_exc();print(r['driver_error'],flush=True);raise
 finally:
  ctx.close();b.close();r['closed_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime());(OUT/'run.py').write_text(Path(__file__).read_text());flush()
