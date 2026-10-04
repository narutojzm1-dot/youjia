import functools,http.server,threading,json,re
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/tmp/262-browser');out.mkdir(exist_ok=True)
class Handler(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Handler,directory='/tmp/262-web'))
threading.Thread(target=server.serve_forever,daemon=True).start()
log=Path('/tmp/review262-3a-viewport.log').read_text()
results=[]
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  for w,h in [(1280,720),(390,844),(844,390)]:
   page=b.new_page(viewport={'width':w,'height':h},device_scale_factor=1)
   errors=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
   page.goto(f'http://127.0.0.1:{server.server_port}/index.html')
   page.wait_for_function('window.first',timeout=120000)
   def rect(key):
    match=re.search(r'\('+str(w)+', '+str(h)+r'\) positive '+key+r' \[P: \(([-.0-9]+), ([-.0-9]+)\), S: \(([-.0-9]+), ([-.0-9]+)\)',log)
    assert match,key
    return tuple(map(float,match.groups()))
   def click(key,ratio=.5):
    x,y,rw,rh=rect(key);page.mouse.click(x+rw*ratio,y+rh/2);page.wait_for_timeout(300)
   click('_play_button');page.wait_for_timeout(700);click('_pause_button')
   page.screenshot(path=str(out/f'{w}-pause.png'))
   click('_music_slider',.2);click('_ambience_slider',.7)
   page.screenshot(path=str(out/f'{w}-levels.png'))
   click('_mute_toggle');click('_mute_toggle');click('_resume_button')
   page.screenshot(path=str(out/f'{w}-resumed.png'))
   assert not errors,errors
   results.append({'viewport':[w,h],'page_errors':errors,'actions':'start/pause/music20%/ambience70%/mute twice/resume','scope':'actual Chromium canvas interactions; screenshots require visual review; no listening claim'})
   page.close()
  b.close()
 (out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
 print(json.dumps(results))
finally:server.shutdown()
