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
READ_DB = """async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 def stable(pg,name,stage):
  manifest=pg.request.get(a.url.rstrip('/')+'/game-release.json?t='+str(time.time())).json();assert manifest['sourceCommit']==a.runtime,manifest;r.setdefault('manifests',[]).append({'page':name,'stage':stage,'manifest':manifest,'time':time.monotonic()})
 def bind(ctx,name):
  pg=ctx.new_page();pg.on('framenavigated',lambda f:r.setdefault('navigation',[]).append({'time':time.monotonic(),'url':f.url,'main':f==pg.main_frame}));pg.on('domcontentloaded',lambda:r.setdefault('dom_ready',[]).append(time.monotonic()));pg.on('console',lambda m:r.setdefault('all_console',[]).append({'type':m.type,'text':m.text,'time':time.monotonic()}));pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
  stable(pg,name,'before')
  response=pg.request.get(a.url.rstrip('/')+'/'+a.entry+'.pck');actual_hash=hashlib.sha256(response.body()).hexdigest();assert response.status==200 and actual_hash==a.pck_sha256,(response.status,actual_hash);r.setdefault('pck_checks',[]).append({'page':name,'sha256':actual_hash});pg.goto(a.url+'?qa='+str(time.time()));entry=pg.locator('html').get_attribute('data-build');assert entry==a.entry,(entry,a.entry);r['builds'].append({'page':name,'entry':entry});pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1200);return pg
 def shot(pg,n):log({'screenshot':n});pg.screenshot(path=str(out/(n+'.png')),scale='css')
 def click(pg,x,y):log({'click':[x,y]});pg.mouse.click(x,y)
 def media(pg,value):
  log({'emulate_media':value});pg.emulate_media(reduced_motion=value);r['media'].append({'time':time.monotonic(),'requested':value,'actual':pg.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")})
 try:
  ctx=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=2);pg=bind(ctx,'heteroswap-main')
  def key(k):log({'keyboard':k});pg.keyboard.press(k)
  def db(name):
   data=pg.evaluate(READ_DB);(out/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2));return data
  def payload(data):
   rec=data.get('youjia-save-host-v1',{}).get('records',{});keys=rec.get('keys',[])
   return json.loads(rec['values'][keys.index('current')]['payload_bytes']) if 'current' in keys else {}
  click(pg,640,368);pg.wait_for_timeout(1500);click(pg,364,412);pg.wait_for_timeout(8000);click(pg,114,675);pg.wait_for_timeout(700);shot(pg,'initial-album');click(pg,918,605);pg.wait_for_timeout(500);db('initial-db')
  success=False
  for trip in (1,2):
   click(pg,329,563);pg.wait_for_timeout(9000);shot(pg,f't{trip}-outside')
   for name,x,y in [('gate',978,466),('shade',824,540),('brook',707,596),('slope',585,641)]:
    click(pg,x,y);pg.wait_for_timeout(12000);key('e');pg.wait_for_timeout(2500);shot(pg,f't{trip}-{name}-offer');before=payload(db(f't{trip}-{name}-before'));key('t');pg.wait_for_timeout(6000);shot(pg,f't{trip}-{name}-taken');after=payload(db(f't{trip}-{name}-after'))
    prior=(before.get('exploration',{}).get('session') or {}).get('carried',[]);post=(after.get('exploration',{}).get('session') or {}).get('carried',[])
    hit=len(prior)==3 and len(post)==3 and post==prior[1:]+[post[-1]] and prior[0]!=post[-1];r.setdefault('swap_observations',[]).append({'trip':trip,'stop':name,'before':prior,'after':post,'hetero_candidate':hit});success=success or hit
    click(pg,720,676);pg.wait_for_timeout(1000)
   click(pg,1190,43);pg.wait_for_timeout(15000);shot(pg,f't{trip}-returned');db(f't{trip}-settled-db');click(pg,114,675);pg.wait_for_timeout(700);shot(pg,f't{trip}-album');click(pg,918,605);pg.wait_for_timeout(500)
   if success:break
  db('pre-close-db');stable(pg,'heteroswap-main','after');pg.close();pg=bind(ctx,'heteroswap-reopen');click(pg,640,368);pg.wait_for_timeout(4000);click(pg,114,675);pg.wait_for_timeout(700);shot(pg,'reopened-album');db('reopened-db');stable(pg,'heteroswap-reopen','after');ctx.close()
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
