import base64, hashlib, json, sys, time, traceback
from pathlib import Path
from playwright.sync_api import sync_playwright

out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
width, height = map(int, sys.argv[2:4])
url = 'http://127.0.0.1:'+sys.argv[4]+'/' if len(sys.argv)>4 else 'http://127.0.0.1:8781/'
events, errors, requests = [], [], []
init = """window.first=false; window.addEventListener('youjia:first-frame',()=>window.first=true);
window.domInputTrace=[]; for(const k of ['pointerdown','pointerup','mousedown','mouseup','keydown','keyup'])
document.addEventListener(k,e=>domInputTrace.push({kind:k,trusted:e.isTrusted,x:e.clientX,y:e.clientY,key:e.key,t:performance.now()}),true);"""

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,
        args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--disable-http2'])
    context = browser.new_context(viewport={'width':width,'height':height},device_scale_factor=2,has_touch=True)
    page = context.new_page(); page.add_init_script(init)
    page.on('pageerror', lambda e:errors.append(str(e)))
    page.on('console', lambda m:errors.append(m.text) if m.type=='error' else None)
    cdp = context.new_cdp_session(page)
    cdp.send('Network.enable', {'maxTotalBufferSize':200000000,'maxResourceBufferSize':100000000})
    cdp.on('Network.responseReceived', lambda e:requests.append(e) if e['response']['url'].endswith(('.pck','.mjs')) else None)
    page.goto(url); page.wait_for_function('window.first', timeout=240000); page.wait_for_timeout(700)
    pck = [e for e in requests if e['response']['url'].endswith('.pck')]
    assert pck, 'no actual PCK request'
    received = cdp.send('Network.getResponseBody', {'requestId':pck[-1]['requestId']})
    blob = base64.b64decode(received['body']) if received.get('base64Encoded') else received['body'].encode()
    candidate = sys.argv[5] if len(sys.argv)>5 else 'nearby565-candidate'
    source = sys.argv[6] if len(sys.argv)>6 else 'c98d6d3ece1fa0ed89a7628c6db5652a3b7c2f39'
    expected = (out.parent / candidate / 'index.pck').read_bytes()
    assert blob == expected, 'actual browser bytes differ from exported PCK'
    modules = {}
    for response in requests:
        if not response['response']['url'].endswith('.mjs'): continue
        body = cdp.send('Network.getResponseBody', {'requestId':response['requestId']})
        raw = base64.b64decode(body['body']) if body.get('base64Encoded') else body['body'].encode()
        name = response['response']['url'].split('/')[-1]
        assert raw == (out.parent/candidate/'web/save'/name).read_bytes(), name+' actual module bytes differ'
        modules[name] = hashlib.sha256(raw).hexdigest()
    package = {'source':source,'url':pck[-1]['response']['url'],'loaded_storage_modules':modules,
        'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest(),'engine':'4.7.2.stable.official.ed1daf0bf','browser':browser.version,'viewport':[width,height,2]}
    (out / 'package.json').write_text(json.dumps(package,indent=2),encoding='utf-8')
    def snapshot(name):
        page.screenshot(path=str(out / (name+'.png')),scale='css')
        # Read existing IndexedDB rows; never create a DB, write a fixture, or change game state.
        data = page.evaluate("""async()=>{const all=[];for(const info of await indexedDB.databases()){
        const db=await new Promise((yes,no)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});
        const stores={};for(const name of db.objectStoreNames){stores[name]=await new Promise((yes,no)=>{
        const s=db.transaction(name,'readonly').objectStore(name),r=s.getAll();r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)})}
        all.push({name:info.name,stores});db.close()}return all}""")
        row = {'stage':name,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'errors':errors.copy(),
            'inputs':page.evaluate('window.domInputTrace'),'storage':data}
        events.append(row); (out/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2),encoding='utf-8')
        print(json.dumps({'snapshot':name,'errors':errors,'storage_names':[d['name'] for d in data]},ensure_ascii=False),flush=True)
    snapshot('title')
    print('READY',flush=True)
    queue = out / 'commands'; queue.mkdir(exist_ok=True)
    seen = set(); deadline = time.time()+1800
    while time.time() < deadline:
        ready = [f for f in sorted(queue.glob('*.json')) if f.name not in seen]
        if not ready:
            time.sleep(.2); continue
        command_file = ready[0]; seen.add(command_file.name)
        try:
            command=json.loads(command_file.read_text(encoding='utf-8-sig')); deadline=time.time()+1800
            if command.get('quit'):break
            if 'tap' in command:page.touchscreen.tap(*command['tap'])
            if 'click' in command:page.mouse.click(*command['click'],delay=90)
            if 'key' in command:page.keyboard.press(command['key'])
            if 'hold' in command:
                page.keyboard.down(command['hold']);page.wait_for_timeout(command.get('ms',1000));page.keyboard.up(command['hold'])
            if command.get('reload'):page.reload();page.wait_for_function('window.first',timeout=120000)
            page.wait_for_timeout(command.get('wait',800))
            if 'snap' in command:snapshot(command['snap'])
            else:print('OK',flush=True)
        except Exception:
            traceback.print_exc(); sys.stdout.flush()
    browser.close()
