"""Diagnostic trace build with ordinary browser actions; read-only save observer."""
import json,sys,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
init="""window.first=false;addEventListener('youjia:first-frame',()=>window.first=true);window.trace=[];
for(const kind of ['pointerdown','pointerup','touchstart','touchend','mousedown','mouseup'])document.addEventListener(kind,e=>trace.push({kind,trusted:e.isTrusted,x:e.clientX,y:e.clientY,t:performance.now()}),true);"""
read="""async()=>{const db=await new Promise((yes,no)=>{const r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});const v=await new Promise((yes,no)=>{const r=db.transaction('records','readonly').objectStore('records').get('current');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});db.close();return v?.payload_bytes?JSON.parse(v.payload_bytes):null}"""
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=d3d11','--enable-webgl'])
    for w,h in [(844,390),(390,844)]:
        folder=out/str(w);folder.mkdir(exist_ok=True);messages=[];events=[];errors=[]
        context=browser.new_context(viewport={'width':w,'height':h},device_scale_factor=1,has_touch=True,record_video_dir=str(folder/'video'),record_video_size={'width':w,'height':h})
        page=context.new_page();page.add_init_script(init)
        page.on('console',lambda m:messages.append({'kind':m.type,'text':m.text}))
        page.on('pageerror',lambda e:errors.append(str(e)))
        def snap(label):
            row={'stage':label,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'payload':page.evaluate(read),'input':page.evaluate('window.trace'),'canvas':page.locator('#canvas').evaluate('(c)=>({rect:c.getBoundingClientRect().toJSON(),width:c.width,height:c.height,dpr:devicePixelRatio})')}
            events.append(row);page.screenshot(path=str(folder/(label+'.png')),scale='css')
            (folder/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2),encoding='utf-8')
            (folder/'console.json').write_text(json.dumps(messages,ensure_ascii=False,indent=2),encoding='utf-8')
            print(json.dumps({'view':[w,h],'stage':label,'exploration':row['payload'].get('exploration') if row['payload'] else None,'console':messages[-5:]},ensure_ascii=False),flush=True)
        page.goto('http://127.0.0.1:8795/');page.wait_for_function('window.first',timeout=90000);page.wait_for_timeout(600);snap('title')
        page.touchscreen.tap(*({844:(423,195),390:(194,430)}[w]));page.wait_for_timeout(8000);snap('yard')
        point={844:(67,300),390:(76,610)}[w]
        page.touchscreen.tap(*point);page.wait_for_timeout(7000);snap('touch-entrance')
        if not (page.evaluate(read).get('exploration') or {}).get('session'):
            page.mouse.click(*point,delay=90);page.wait_for_timeout(7000);snap('mouse-entrance')
        print('TRACE_DIAGNOSTIC '+json.dumps({'view':[w,h],'errors':errors,'messages':messages},ensure_ascii=False),flush=True)
        context.close()
    browser.close()
