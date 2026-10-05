from playwright.sync_api import sync_playwright
import json,pathlib,hashlib
out=pathlib.Path('/workspace/save-candidate-browser');out.mkdir(exist_ok=True)
read="""async()=>{const names=await indexedDB.databases();if(!names.some(x=>x.name==='/userfs'))return null;const db=await new Promise((r,j)=>{let q=indexedDB.open('/userfs');q.onsuccess=()=>r(q.result);q.onerror=()=>j(q.error)});try{return await new Promise((r,j)=>{let t=db.transaction('FILE_DATA','readonly');let q=t.objectStore('FILE_DATA').get('/userfs/godot/app_userdata/悠长的假期/youjia_save.json');let v=null;q.onsuccess=()=>{if(q.result)v=JSON.parse(new TextDecoder().decode(q.result.contents))};t.oncomplete=()=>r(v);t.onerror=()=>j(t.error)})}finally{db.close()}}"""
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 c=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=1)
 errors=[]
 def page():
  pg=c.new_page();pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)");pg.goto('http://127.0.0.1:8139/',wait_until='domcontentloaded');pg.wait_for_function('window.first',timeout=90000);return pg
 pg=page();pg.mouse.click(640,368);pg.wait_for_timeout(1200);pg.mouse.click(364,412);pg.wait_for_timeout(8500)
 initial=pg.evaluate(read);print('saved keys',list(initial or {}),flush=True)
 assert initial and len(initial.get('album',[]))>=1,initial
 pg.mouse.click(114,675);pg.wait_for_timeout(1000);pg.screenshot(path=str(out/'natural-album.png'))
 # Genuine close/reopen in same browser profile, no localStorage or game-state writes.
 pg.close();pg=page();restored=pg.evaluate(read);assert restored and restored['album']==initial['album']
 pg.mouse.click(640,368);pg.wait_for_timeout(1000);pg.mouse.click(114,675);pg.wait_for_timeout(500);pg.screenshot(path=str(out/'reopened-album.png'))
 assert not errors,errors
 record={'scope':'local unmodified production Web, actual title/pet/photo/album then close/reopen; IndexedDB inspected readonly. Native forced-write-failure regression separate. Does not prove new Host durability.','viewport':[1280,720],'dpr':1,'album_before':initial['album'],'album_after':restored['album'],'errors':errors,'pck_sha256':hashlib.sha256(pathlib.Path('/workspace/save-candidate-web/index.pck').read_bytes()).hexdigest()}
 (out/'browser.json').write_text(json.dumps(record,ensure_ascii=False,indent=2));print(record);b.close()
