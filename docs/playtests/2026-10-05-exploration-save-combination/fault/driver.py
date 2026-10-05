from pathlib import Path
from playwright.sync_api import sync_playwright
import json,time
out=Path('/workspace/exploration-save-combination-public/fault');q=out/'command.json';q.unlink(missing_ok=True)
read="""async()=>{let a=await indexedDB.databases();let d=a.find(x=>x.name==='youjia-save-host-v1');if(!d)return {};return await new Promise((ok,no)=>{let r=indexedDB.open(d.name);r.onsuccess=()=>{let db=r.result,t=db.transaction('records','readonly'),g=t.objectStore('records').get('current');g.onsuccess=()=>ok(g.result);t.oncomplete=()=>db.close()}})}"""
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl']);page_builds=[];ctx=b.new_context(viewport={'width':1280,'height':720});errors=[];events=[]
 def page():
  pg=ctx.new_page();pg.add_init_script("(()=>{window.audit={armed:false,puts:[],lost:[],resolves:[]};const def=Object.defineProperty;Object.defineProperty=function(o,k,d){if(o===window&&k==='YoujiaSaveHost'){const h=d.value;d={...d,value:Object.freeze({...h,submit:(...a)=>{let cb=a.pop();h.submit(...a,raw=>{let v=JSON.parse(raw);if(audit.armed&&!audit.dropped&&audit.target_generation===v.generation){audit.dropped=true;audit.lost.push({raw,time:Date.now()});cb(JSON.stringify({schema:'youjia.save-error/v1',code:'CONTROLLED_EXPLORATION_RECEIPT_LOSS',cause:'actual exploration trip current complete; receipt transport dropped'}))}else cb(raw)})},resolve:(...a)=>{let cb=a.pop();h.resolve(...a,raw=>{audit.resolves.push({raw,time:Date.now()});cb(raw)})}})}}return def.call(this,o,k,d)};const put=IDBObjectStore.prototype.put;IDBObjectStore.prototype.put=function(v,k){let r=put.apply(this,arguments);if(audit.armed&&this.name==='records'&&k==='current'){let payload=JSON.parse(v.payload_bytes);let record={generation:v.generation,payload,success:false,complete:false,aborted:false};audit.puts.push(record);if(payload.exploration_committed_serial>0&&!audit.target_generation)audit.target_generation=v.generation;r.addEventListener('success',()=>record.success=true);this.transaction.addEventListener('complete',()=>{record.complete=true;record.time=Date.now()});this.transaction.addEventListener('abort',()=>record.aborted=true)}return r}})()");pg.on('pageerror',lambda e:errors.append(str(e)));pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)");pg.goto('https://narutojzm1-dot.github.io/youjia/');pg.wait_for_function('window.first',timeout=120000);build=pg.locator('html').get_attribute('data-build');manifest=pg.evaluate("async()=>await(await fetch('game-release.json',{cache:'no-store'})).json()");assert build=='game-33b105f' and manifest['sourceCommit']=='33b105f075a1b851450f647c623302070ffafe1f',(build,manifest);page_builds.append({'html':build,'manifest':manifest});(out/'page-builds.json').write_text(json.dumps(page_builds));return pg
 pg=page();manifest=pg.evaluate("async()=>await(await fetch('game-release.json',{cache:'no-store'})).json()");build=pg.locator('html').get_attribute('data-build');assert build=='game-33b105f',(build,manifest)
 (out/'manifest.json').write_text(json.dumps(manifest));pg.mouse.click(640,360);pg.wait_for_timeout(3500);pg.screenshot(path=str(out/'initial.png'))
 while True:
  if not q.exists():pg.wait_for_timeout(300);continue
  cmd=json.loads(q.read_text());q.unlink();events.append(cmd)
  for a in cmd.get('actions',[]):
   if a[0]=='click':pg.mouse.click(a[1],a[2])
   elif a[0]=='key':pg.keyboard.press(a[1])
   elif a[0]=='hold':pg.keyboard.down(a[1]);pg.wait_for_timeout(a[2]);pg.keyboard.up(a[1])
   elif a[0]=='arm':pg.evaluate('audit.armed=true')
   elif a[0]=='wait':pg.wait_for_timeout(a[1])
   elif a[0]=='resize':pg.set_viewport_size({'width':a[1],'height':a[2]})
   elif a[0]=='reopen':pg.close();pg=page()
   elif a[0]=='fresh':ctx.close();ctx=b.new_context(viewport={'width':a[1],'height':a[2]});pg=page()
  name=cmd['name'];(out/(name+'-audit.json')).write_text(json.dumps(pg.evaluate('audit'),ensure_ascii=False,indent=2));pg.screenshot(path=str(out/(name+'.png')));v=pg.evaluate(read);(out/(name+'.json')).write_text(json.dumps(v,ensure_ascii=False,indent=2));(out/'events.json').write_text(json.dumps(events));(out/'errors.json').write_text(json.dumps(errors));(out/'done').write_text(name)
  if cmd.get('exit'):break
 b.close()
