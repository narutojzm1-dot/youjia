"""Prepared ordinary-UI QA. Requires explicit candidate URL/build/PCK before running.
Media emulation uses actual browser matchMedia; no game state setters.
"""
import argparse,hashlib,io,json,time
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--url',required=True);ap.add_argument('--runtime',required=True);ap.add_argument('--entry',required=True);ap.add_argument('--pck-sha256',required=True);ap.add_argument('--out',required=True);a=ap.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=False)
r={'runtime':a.runtime,'expected_pck':a.pck_sha256,'inputs':[],'media':[],'errors':[],'builds':[],'limits':['browser media emulation, not OS settings or physical phone','listener multiplicity is not proved by screenshots','photo detector needs visual confirmation']}
def log(v):r['inputs'].append(dict(v,time=time.monotonic()))
def card_visible(blob):
 im=Image.open(io.BytesIO(blob)).convert('RGB'); pts=[]
 for x in range(5,19,3):
  for y in range(30,240,10):pts.append(im.getpixel((x,y)))
 return sum(min(z)>170 and max(z)-min(z)<85 for z in pts)/len(pts)>.65
INJECT="(()=>{window.audit={puts:[],faults:[],replies:[]};const def=Object.defineProperty;Object.defineProperty=function(o,k,d){if(o===window&&k==='YoujiaSaveHost'){const h=d.value;let wraps={};for(let m of ['prepare','submit','resolve','acknowledge'])if(h[m])wraps[m]=(...a)=>{let cb=a.pop();audit.replies.push({method:m,stage:'call',args:a,time:Date.now()});h[m](...a,raw=>{audit.replies.push({method:m,stage:'reply',raw,time:Date.now()});cb(raw)})};d={...d,value:Object.freeze({...h,...wraps})}}return def.call(this,o,k,d)};const put=IDBObjectStore.prototype.put;IDBObjectStore.prototype.put=function(v,k){let e={key:k,value:v,time:Date.now(),complete:false,aborted:false};if(this.name==='records')audit.puts.push(e);if(k==='intent'&&v.state==='prepared'&&!audit.faults.length&&!window.disableCleanupFault){let p=JSON.parse(v.parent.payload_bytes),c=JSON.parse(v.candidate.payload_bytes);if(Object.keys(p.keepsakes).length>0&&p.exploration_committed_serial>0&&p.exploration?.session&&c.exploration?.session===null&&p.exploration_committed_serial===c.exploration_committed_serial&&JSON.stringify(p.keepsakes)===JSON.stringify(c.keepsakes)){audit.faults.push(e);e.injected=true;throw new DOMException('controlled exact idle cleanup intent failure','UnknownError')}}let r=put.apply(this,arguments);this.transaction.addEventListener('complete',()=>e.complete=true);this.transaction.addEventListener('abort',()=>e.aborted=true);return r}})()"
READ_DB = """async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 def stable(pg,name,stage):
  response=pg.request.get(a.url.rstrip('/')+'/game-release.json?t='+str(time.time()));assert response.status==200,response.status
  manifest=response.json();r.setdefault('manifests',[]).append({'page':name,'stage':stage,'manifest':manifest,'time':time.monotonic()});assert manifest['sourceCommit']==a.runtime,manifest
 def bind(ctx,name):
  pg=ctx.new_page();pg.add_init_script(INJECT);pg.add_init_script('window.disableCleanupFault='+('true' if r['builds'] else 'false'));pg.on('framenavigated',lambda f:r.setdefault('navigation',[]).append({'time':time.monotonic(),'url':f.url,'main':f==pg.main_frame}));pg.on('domcontentloaded',lambda:r.setdefault('dom_ready',[]).append(time.monotonic()));pg.on('console',lambda m:r.setdefault('all_console',[]).append({'type':m.type,'text':m.text,'time':time.monotonic()}));pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
  stable(pg,name,'before')
  response=pg.request.get(a.url.rstrip('/')+'/'+a.entry+'.pck');body=response.body();actual_hash=hashlib.sha256(body).hexdigest();assert response.status==200 and actual_hash==a.pck_sha256,(response.status,actual_hash);r.setdefault('pck_checks',[]).append({'page':name,'sha256':actual_hash,'bytes':len(body)});pg.goto(a.url+'?qa='+str(time.time()));entry=pg.locator('html').get_attribute('data-build');r['builds'].append({'page':name,'entry':entry});assert entry==a.entry,(entry,a.entry);pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1200);return pg
 def shot(pg,n):log({'screenshot':n});pg.screenshot(path=str(out/(n+'.png')),scale='css')
 def click(pg,x,y):log({'click':[x,y]});pg.mouse.click(x,y)
 def media(pg,value):
  log({'emulate_media':value});pg.emulate_media(reduced_motion=value);r['media'].append({'time':time.monotonic(),'requested':value,'actual':pg.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")})
 try:
  ctx=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=2);pg=bind(ctx,'fault-main')
  def sample(name):
   shot(pg,name);(out/(name+'-audit.json')).write_text(json.dumps(pg.evaluate('audit'),ensure_ascii=False,indent=2));(out/(name+'-db.json')).write_text(json.dumps(pg.evaluate(READ_DB),ensure_ascii=False,indent=2))
  click(pg,640,368);pg.wait_for_timeout(1500);click(pg,329,563);pg.wait_for_timeout(9000)
  for name,x,y in [('shade',824,540),('brook',707,596)]:
   click(pg,x,y);pg.wait_for_timeout(12000);log({'keyboard':'e'});pg.keyboard.press('e');pg.wait_for_timeout(1500);sample('offer-'+name);log({'keyboard':'t'});pg.keyboard.press('t');pg.wait_for_timeout(2500);sample('taken-'+name);click(pg,720,676);pg.wait_for_timeout(1000)
  click(pg,1190,43);pg.wait_for_timeout(18000);sample('03-after-return')
  while True:
   cmdpath=out/'command.json'
   if not cmdpath.exists():pg.wait_for_timeout(250);continue
   cmd=json.loads(cmdpath.read_text());cmdpath.unlink();log({'command':cmd})
   if cmd.get('retry'):click(pg,640,177);pg.wait_for_timeout(15000)
   if cmd.get('reopen'):stable(pg,'fault-main','after');pg.close();pg=bind(ctx,'fault-reopen');click(pg,640,368);pg.wait_for_timeout(5000)
   sample(cmd['name'])
   if cmd.get('exit'):stable(pg,'fault-reopen','after');break
  ctx.close()
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
