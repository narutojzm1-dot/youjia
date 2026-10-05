from playwright.sync_api import sync_playwright
from pathlib import Path
import json
out=Path('/workspace/production-save-failure-browser-final')
read_db = """async()=>{const all=await indexedDB.databases();let result={};for(const d of all){result[d.name]=await new Promise((resolve,reject)=>{let q=indexedDB.open(d.name);q.onerror=()=>reject(q.error.message);q.onsuccess=()=>{let db=q.result;let names=[...db.objectStoreNames];if(!names.length){db.close();resolve({});return;}let tx=db.transaction(names,'readonly'),r={};for(const n of names){let st=tx.objectStore(n),v=st.getAll(),k=st.getAllKeys();v.onsuccess=()=>{r[n]={values:v.result,...r[n]}};k.onsuccess=()=>{r[n]={keys:k.result,...r[n]}};}tx.oncomplete=()=>{db.close();resolve(r)};tx.onerror=()=>{db.close();reject(tx.error.message)};}});}return result;}"""
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 ctx=b.new_context(viewport={'width':1280,'height':720});errors=[];logs=[];result={}
 def page():
  pg=ctx.new_page();pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:logs.append([m.type,m.text]))
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  pg.goto('http://127.0.0.1:8140/',wait_until='domcontentloaded');pg.wait_for_function('window.first',timeout=90000)
  return pg
 pg=page()
 try:
  pg.mouse.click(640,368);pg.wait_for_timeout(1200)
  result['initial']=pg.evaluate(read_db)
  pg.evaluate("""()=>{window.faults=[];let put=IDBObjectStore.prototype.put;IDBObjectStore.prototype.put=function(value,key){if(this.name==='records'&&key==='current'&&window.faults.length===0&&JSON.parse(value.payload_bytes||'{}').album?.length>0){window.faults.push({key,value,at:Date.now()});this.transaction.abort();throw new DOMException('controlled real commit abort','AbortError');}return put.apply(this,arguments);};}""")
  pg.mouse.click(364,412);pg.wait_for_timeout(2200);pg.mouse.click(500,450);pg.wait_for_timeout(3000);pg.mouse.click(390,423);pg.wait_for_timeout(3000)
  result['faults']=pg.evaluate('window.faults');result['unknown']=pg.evaluate(read_db);pg.screenshot(path=str(out/'unknown.png'))
  pg.mouse.click(640,172);pg.wait_for_timeout(1500);result['resolved']=pg.evaluate(read_db);pg.screenshot(path=str(out/'resolved.png'))
  pg.mouse.click(640,172)
  result['timeline']=[]
  for index,delay in enumerate([0,250,250,500,1000,1500,1000,2000,3000,3000]):
   pg.wait_for_timeout(delay);db=pg.evaluate(read_db)
   result['timeline'].append({'sample':index,'delay_ms':delay,'db':db})
   pg.screenshot(path=str(out/('retry-%02d.png'%index)))
  result['retried']=pg.evaluate(read_db);pg.screenshot(path=str(out/'retried.png'))
  pg.mouse.click(114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'album.png'))
  pg.close();pg=page();pg.mouse.click(640,368);pg.wait_for_timeout(1500);pg.mouse.click(114,675);pg.wait_for_timeout(500)
  result['reopened']=pg.evaluate(read_db);pg.screenshot(path=str(out/'reopened.png'))
 finally:
  result.update(errors=errors,logs=logs);(out/'records.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));b.close()
