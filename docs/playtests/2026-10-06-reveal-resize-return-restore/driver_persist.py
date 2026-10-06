from pathlib import Path
from playwright.sync_api import sync_playwright
import json, time

import sys
URL = sys.argv[1]; out = Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
q = out / 'command.json'; q.unlink(missing_ok=True)
events = []; errors = []; console = []
t0 = time.time()
READ = """async()=>{let a=await indexedDB.databases();let d=a.find(x=>x.name==='youjia-save-host-v1');if(!d)return {dbs:a};return await new Promise((ok)=>{let r=indexedDB.open(d.name);r.onsuccess=()=>{let db=r.result,t=db.transaction('records','readonly'),g=t.objectStore('records').get('current');g.onsuccess=()=>{let v=g.result;try{let pl=JSON.parse(v.payload_bytes);ok({generation:v.generation,keepsakes:pl.keepsakes,exploration:pl.exploration,serial:pl.exploration_committed_serial})}catch(e){ok({raw:v})}};t.oncomplete=()=>db.close()}})}"""

def stamp(kind, data):
    events.append({'t': round(time.time() - t0, 3), 'kind': kind, 'data': data})

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(sys.argv[3], executable_path='/usr/local/bin/google-chrome', headless=True, viewport={'width': int(sys.argv[4]), 'height': int(sys.argv[5])}, record_video_dir=str(out / 'video'), record_video_size={'width': 1280, 'height': 844},
                          args=['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--autoplay-policy=no-user-gesture-required'])
    pg = ctx.pages[0] if ctx.pages else ctx.new_page()
    pg.on('pageerror', lambda e: errors.append(str(e)))
    pg.on('console', lambda m: console.append(m.text) if m.type in ('error', 'warning') else None)
    pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
    pg.goto(URL + '/index.html?r=' + str(int(time.time())))
    (out / 'build.json').write_text(json.dumps(pg.evaluate("async()=>await(await fetch('game-release.json',{cache:'no-store'})).json()")))
    try:
        pg.wait_for_function('window.first', timeout=180000)
    except Exception as e:
        stamp('first-frame-timeout', str(e))
    stamp('loaded', pg.evaluate('location.href'))
    pg.screenshot(path=str(out / '00-loaded.png'))
    (out / 'done').write_text('00-loaded')
    while True:
        if not q.exists():
            pg.wait_for_timeout(200); continue
        cmd = json.loads(q.read_text()); q.unlink()
        for a in cmd.get('actions', []):
            stamp('input', a)
            if a[0] == 'click': pg.mouse.click(a[1], a[2])
            elif a[0] == 'key': pg.keyboard.press(a[1])
            elif a[0] == 'hold': pg.keyboard.down(a[1]); pg.wait_for_timeout(a[2]); pg.keyboard.up(a[1])
            elif a[0] == 'wait': pg.wait_for_timeout(a[1])
            elif a[0] == 'resize': pg.set_viewport_size({'width': a[1], 'height': a[2]})
            elif a[0] == 'read': (out / (a[1] + '.json')).write_text(json.dumps(pg.evaluate(READ), ensure_ascii=False, indent=1))
            elif a[0] == 'shot': pg.screenshot(path=str(out / (a[1] + '.png'))); stamp('shot', a[1])
        name = cmd['name']
        pg.screenshot(path=str(out / (name + '.png')))
        stamp('shot', name)
        (out / 'events.json').write_text(json.dumps(events, ensure_ascii=False, indent=1))
        (out / 'errors.json').write_text(json.dumps({'pageerror': errors, 'console': console[-50:]}, ensure_ascii=False, indent=1))
        (out / 'done').write_text(name)
        if cmd.get('exit'):
            break
    ctx.close()
