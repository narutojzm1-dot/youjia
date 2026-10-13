from pathlib import Path
import json, base64, hashlib, time
from playwright.sync_api import sync_playwright

r=Path(r'D:\games\youjia-test\assistant-recovery')
out=r/'nearby-audio-web-proof-oct11/probe'
out.mkdir(parents=True,exist_ok=True)
export=r/'nearby-audio-combination-web'
source=json.loads((export/'candidate-source.json').read_text(encoding='utf-8-sig'))['source']
observer=(r/'nearby-web-audio-observer-oct11.js').read_text(encoding='utf-8')
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,args=['--use-gl=angle','--use-angle=d3d11','--enable-precise-memory-info'])
    context=browser.new_context(viewport={'width':1280,'height':720},has_touch=True,device_scale_factor=1)
    page=context.new_page();page.add_init_script(observer)
    page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda e:errors.append(e.text) if e.type=='error' else None)
    page.goto('http://127.0.0.1:8797/',wait_until='domcontentloaded')
    page.wait_for_function('window.first',timeout=120000)
    before=page.evaluate('audioObservation.diagnostics()')
    page.screenshot(path=str(out/'title.png'))
    page.mouse.click(640,368,delay=90)
    page.wait_for_timeout(3000)
    yard=page.evaluate('audioObservation.diagnostics()')
    page.screenshot(path=str(out/'yard.png'))
    page.keyboard.press('Escape');page.wait_for_timeout(600)
    page.screenshot(path=str(out/'pause.png'))
    recordings=page.evaluate('audioObservation.finishRecordings()')
    for item in recordings:
        binary=base64.b64decode(item.pop('base64'))
        assert len(binary)==item['bytes']
        path=out/f"context-{item['context']}.webm"
        path.write_bytes(binary);item.update(path=path.name,sha256=hashlib.sha256(binary).hexdigest())
    (out/'result.json').write_bytes((json.dumps({'source':source,'initial':before,'yard':yard,'errors':errors,'recordings':recordings,'purpose':'Preflight observer and ordinary pause layout; not 10-minute validation or listening'},indent=2)+'\n').encode())
    browser.close()
print(json.dumps({'source':source,'errors':errors,'yardBackend':yard['backend'],'signal':[{'rms':v['rms'],'context':v['context']} for v in yard['signal']]}))
