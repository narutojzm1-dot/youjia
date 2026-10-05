from playwright.sync_api import sync_playwright
from pathlib import Path
import json
out=Path('/workspace/production-save-browser-review/export4-mobile-long');out.mkdir(exist_ok=True)
seed="""async({primary,backup})=>{await new Promise((ok,no)=>{let q=indexedDB.open('/userfs',21);q.onupgradeneeded=()=>q.result.createObjectStore('FILE_DATA').createIndex('timestamp','timestamp');q.onerror=()=>no(String(q.error));q.onsuccess=()=>{let db=q.result,t=db.transaction('FILE_DATA','readwrite'),s=t.objectStore('FILE_DATA');for(let [n,text]of [['youjia_save.json',primary],['youjia_save.bak',backup]])s.put({timestamp:new Date(),mode:33188,contents:new TextEncoder().encode(text)},'/userfs/godot/app_userdata/悠长的假期/'+n);t.oncomplete=()=>{db.close();ok(true)};t.onerror=()=>no(String(t.error));}})}"""
read="""async()=>{let result={};for(let d of await indexedDB.databases()){result[d.name]=await new Promise((ok,no)=>{let q=indexedDB.open(d.name);q.onsuccess=()=>{let db=q.result,n=[...db.objectStoreNames],t=db.transaction(n,'readonly'),r={};for(let name of n){let s=t.objectStore(name),v=s.getAll();v.onsuccess=()=>r[name]=v.result.map(x=>x.contents?{...x,contents:new TextDecoder().decode(x.contents)}:x)}t.oncomplete=()=>{db.close();ok(r)};t.onerror=()=>no(String(t.error));};});}return result;}"""
primary=' { "version":5, "locale":"zh-CN", "holiday_day":3, "unknown_big":900719925474099312345, "unknown_note":" preserve spacing " }\n'
backup='\n {"version":5,"holiday_day":2,"unknown_backup":true} '
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 for label,pri,bak in [('good',primary,backup)]:
  ctx=b.new_context(viewport={'width':390,'height':844},device_scale_factor=3,accept_downloads=True);page=ctx.new_page();errors=[]
  page.goto('http://127.0.0.1:8140/save/budgets.mjs');page.evaluate(seed,{'primary':pri,'backup':bak})
  def start():
   global page
   page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)");page.goto('http://127.0.0.1:8140/');page.wait_for_timeout(18000)
  start();page.screenshot(path=str(out/(label+'-startup.png')));r={'seed_primary':pri,'seed_backup':bak,'startup':page.evaluate(read)}
  if label=='good':
   r['gameplay']=page.evaluate(read)
   old=ctx.new_page();old.goto('http://127.0.0.1:8140/save/budgets.mjs');old.evaluate(seed,{'primary':primary+'  ','backup':backup});old.close();page.close();start();page.screenshot(path=str(out/'good-diverged.png'));r['diverged']=page.evaluate(read)
   with page.expect_download(timeout=15000) as download:
    page.mouse.click(195,445)
   download.value.save_as(str(out/'backup-download.json'))
   page.mouse.click(195,485);page.wait_for_timeout(15000);page.screenshot(path=str(out/'continued.png'));r['continued']=page.evaluate(read)
  r['errors']=errors;(out/(label+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2,default=str));ctx.close()
 b.close()
