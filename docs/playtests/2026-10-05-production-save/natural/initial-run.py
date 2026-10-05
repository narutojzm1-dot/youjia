from playwright.sync_api import sync_playwright
from pathlib import Path
import json
out=Path('/workspace/production-save-browser-review');out.mkdir(exist_ok=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 ctx=b.new_context(viewport={'width':1280,'height':720});pg=ctx.new_page();logs=[];errors=[]
 pg.on('console',lambda m:logs.append([m.type,m.text]));pg.on('pageerror',lambda e:errors.append(str(e)))
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 try:
  pg.goto('http://127.0.0.1:8140/',wait_until='domcontentloaded');pg.wait_for_function('window.first',timeout=90000)
  pg.mouse.click(640,368);pg.wait_for_timeout(1000);pg.mouse.click(364,412);pg.wait_for_timeout(8000);pg.mouse.click(114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'album.png'))
  read_db = """async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
  before=pg.evaluate(read_db)
  ctx=pg.context
  pg.close()
  pg=ctx.new_page();pg.on('console',lambda m:logs.append([m.type,m.text]));pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  pg.goto('http://127.0.0.1:8140/',wait_until='domcontentloaded');pg.wait_for_function('window.first',timeout=90000)
  pg.mouse.click(640,368);pg.wait_for_timeout(1500);pg.mouse.click(114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'reopened-album.png'))
  after=pg.evaluate(read_db)
  result={'before':before,'after':after,'errors':errors,'logs':logs}
  (out/'records.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
  print('databases',list(before),list(after),'errors',errors)
 finally:
  (out/'console.json').write_text(json.dumps({'logs':logs,'errors':errors},ensure_ascii=False,indent=2));pg.screenshot(path=str(out/'last.png'));b.close()
