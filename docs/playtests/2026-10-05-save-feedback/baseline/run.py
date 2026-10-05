from playwright.sync_api import sync_playwright
from pathlib import Path
import json
out=Path('/workspace/save-feedback-baseline')
read="""async()=>new Promise((ok,no)=>{let r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>{let db=r.result,t=db.transaction('records','readonly'),q=t.objectStore('records').getAll(),k=t.objectStore('records').getAllKeys();t.oncomplete=()=>{ok({keys:k.result,values:q.result});db.close()}}})"""
hook="""(()=>{window.audit={armed:false,submits:[],completes:[],resolves:[]};let def=Object.defineProperty;Object.defineProperty=function(o,k,d){if(o===window&&k==='YoujiaSaveHost'){let host=d.value;let wrapped={...host,submit:(...args)=>{let cb=args.pop();host.submit(...args,(raw)=>{if(audit.armed&&!audit.dropped){audit.dropped=true;audit.submits.push({raw,time:Date.now()});cb(JSON.stringify({schema:'youjia.save-error/v1',code:'CONTROLLED_RECEIPT_LOSS',cause:'real submit completed, transport receipt lost'}));}else cb(raw)})},resolve:(...args)=>{let cb=args.pop();host.resolve(...args,(raw)=>{audit.resolves.push({raw,time:Date.now()});cb(raw)})}};d={...d,value:Object.freeze(wrapped)}}return def.call(this,o,k,d)};let put=IDBObjectStore.prototype.put;IDBObjectStore.prototype.put=function(v,k){let r=put.apply(this,arguments);if(audit.armed&&this.name==='records'&&k==='current'){let rec={generation:v.generation,request_id:v.request_id,put_success:false,complete:false,aborted:false};audit.completes.push(rec);r.addEventListener('success',()=>rec.put_success=true);this.transaction.addEventListener('complete',()=>{rec.complete=true;rec.at=Date.now()});this.transaction.addEventListener('abort',()=>rec.aborted=true)}return r};})()"""
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl']);ctx=b.new_context(viewport={'width':1280,'height':720});pg=ctx.new_page();errors=[];pg.on('pageerror',lambda e:errors.append(str(e)));pg.add_init_script(hook);pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)");result={}
 try:
  pg.goto('https://narutojzm1-dot.github.io/youjia/');pg.wait_for_function('window.first',timeout=120000);result['html']=pg.locator('html').get_attribute('data-build');result['manifest']=pg.evaluate("async()=>await(await fetch('game-release.json',{cache:'no-store'})).json()");assert result['html']=='game-7c1608c'
  pg.mouse.click(640,368);pg.wait_for_timeout(4000);result['before']=pg.evaluate(read);pg.evaluate('audit.armed=true')
  pg.mouse.click(1165,44);pg.wait_for_timeout(500);pg.mouse.click(640,278);pg.wait_for_timeout(500);pg.mouse.click(640,383);pg.wait_for_timeout(6000)
  result['unknown_audit']=pg.evaluate('audit');result['unknown_db']=pg.evaluate(read);pg.screenshot(path=str(out/'unknown.png'))
  assert result['unknown_audit']['dropped'];assert result['unknown_audit']['completes'][0]['complete']
  pg.mouse.click(640,172);pg.wait_for_timeout(6000);result['after_audit']=pg.evaluate('audit');result['after_db']=pg.evaluate(read);pg.screenshot(path=str(out/'after-one-confirm.png'))
 finally:
  result['errors']=errors;(out/'records.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));b.close()
