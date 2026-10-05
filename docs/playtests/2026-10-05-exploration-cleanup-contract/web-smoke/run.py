import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
read_db = """async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
out=Path('/workspace/cleanup-contract-web-smoke');errors=[];actions=[];db={}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl']);ctx=b.new_context(viewport={'width':1280,'height':720})
 def page():
  pg=ctx.new_page();pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None);pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)");pg.goto('http://127.0.0.1:8194/');pg.wait_for_function('window.first',timeout=120000);return pg
 pg=page()
 def click(tag,x,y,wait=600):
  actions.append({'action':tag,'xy':[x,y],'monotonic':time.monotonic()});pg.mouse.click(x,y);pg.wait_for_timeout(wait)
 def shot(tag):pg.screenshot(path=str(out/(tag+'.png')))
 click('enter',640,360,5000);shot('yard');click('album',114,675);shot('album');pg.keyboard.press('Escape');actions.append({'action':'escape-album','monotonic':time.monotonic()});pg.wait_for_timeout(300)
 click('walk',550,450,1800);db['before_title']=pg.evaluate(read_db)
 click('pause',1165,44);click('request-title',640,278);shot('confirm');click('confirm-title',640,383,4500);shot('title');db['after_title']=pg.evaluate(read_db)
 click('continue-existing',640,360,4000);shot('continued');db['continued']=pg.evaluate(read_db)
 pg.close();actions.append({'action':'actual-page-close','monotonic':time.monotonic()});pg=page();click('reopen-existing',640,360,4000);shot('reopened');db['reopened']=pg.evaluate(read_db)
 (out/'db.json').write_text(json.dumps(db,ensure_ascii=False,indent=2));(out/'result.json').write_text(json.dumps({'runtime':'2b79d6538dab1e35a8dff6161b0104bce434196f','actions':actions,'errors':errors},indent=2));b.close()
