from playwright.sync_api import sync_playwright
from pathlib import Path
import json
out=Path('/workspace/cleanup-contract-public');out.mkdir(exist_ok=True)
source='4fa150819c304b03fb6a36a149e71d4bcd911000'
url='https://narutojzm1-dot.github.io/youjia/'
builds=[]
actions=[]
def click(pg,x,y):
 actions.append({"mouse":[x,y],"time":__import__("time").time()});(out/"actions.json").write_text(json.dumps(actions,indent=2));pg.mouse.click(x,y)
def bind(pg):
 manifest=pg.request.get(url+'game-release.json?t='+str(__import__('time').time())).json()
 assert manifest['sourceCommit']==source,manifest
 pg.goto(url+'?cleanup-contract='+source[:7],wait_until='domcontentloaded')
 build=pg.locator('html').get_attribute('data-build');assert build=='game-'+source[:7],build
 builds.append({'manifest':manifest,'html':build});(out/'page-builds.json').write_text(json.dumps(builds,indent=2))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 ctx=b.new_context(viewport={'width':1280,'height':720});pg=ctx.new_page();logs=[];errors=[]
 pg.on('console',lambda m:logs.append([m.type,m.text]));pg.on('pageerror',lambda e:errors.append(str(e)))
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 try:
  bind(pg);pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1500)
  click(pg,640,368);pg.wait_for_timeout(1000);click(pg,364,412);pg.wait_for_timeout(8000);click(pg,114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'album.png'))
  read_db = """async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
  before=pg.evaluate(read_db)
  click(pg,918,605);pg.wait_for_timeout(1600);click(pg,1180,45);pg.wait_for_timeout(2200);pg.screenshot(path=str(out/'pause.png'))
  click(pg,640,278);pg.wait_for_timeout(2200);pg.screenshot(path=str(out/'confirm.png'))
  click(pg,640,372);pg.wait_for_timeout(15000);pg.screenshot(path=str(out/'title-return.png'))
  click(pg,640,368);pg.wait_for_timeout(1000);click(pg,114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'return-album.png'))
  ctx=pg.context
  pg.close()
  pg=ctx.new_page();pg.on('console',lambda m:logs.append([m.type,m.text]));pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  bind(pg);pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1500)
  click(pg,640,368);pg.wait_for_timeout(1500);click(pg,114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'reopened-album.png'))
  after=pg.evaluate(read_db)
  result={'before':before,'after':after,'errors':errors,'logs':logs}
  (out/'records.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
  print('databases',list(before),list(after),'errors',errors)
 finally:
  (out/'console.json').write_text(json.dumps({'logs':logs,'errors':errors},ensure_ascii=False,indent=2));pg.screenshot(path=str(out/'last.png'));b.close()
