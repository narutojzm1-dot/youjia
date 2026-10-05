import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/daylabel-artifacts')
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory='/workspace/daylabel-web'))
threading.Thread(target=srv.serve_forever,daemon=True).start()
results=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,2),(390,844,2),(844,390,3),(390,844,3)]:
  key=f'{w}-{h}-dpr{dpr}'
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h},device_scale_factor=dpr);errors=[]
  pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  pg.goto(f'http://127.0.0.1:{srv.server_port}/index.html');pg.wait_for_function('window.first',timeout=120000)
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(5200)
  pg.screenshot(path=str(out/f'{key}-yard.png'),scale='css')
  canvas=pg.evaluate("({dpr:devicePixelRatio,width:document.querySelector('canvas').width,height:document.querySelector('canvas').height,css:document.querySelector('canvas').getBoundingClientRect().toJSON()})")
  pg.mouse.click(w-75,44);pg.wait_for_timeout(500)
  pg.screenshot(path=str(out/f'{key}-pause.png'),scale='css')
  # Keyboard Escape resumes through the production input path.
  pg.keyboard.press('Escape');pg.wait_for_timeout(400)
  if w==844:pg.mouse.click(351,182)
  elif w==390:pg.mouse.click(306,575)
  else:pg.mouse.click(503,390)
  pg.wait_for_timeout(1400)
  pg.screenshot(path=str(out/f'{key}-animal.png'),scale='css')
  pg.set_viewport_size({'width':h,'height':w});pg.wait_for_timeout(1000)
  pg.screenshot(path=str(out/f'{key}-resize.png'),scale='css')
  results.append({'case':key,'canvas':canvas,'errors':errors,'scope':'natural title/play, pause/Escape, animal-coordinate click and viewport rotation; screenshots need visual verification; no game state injection'})
  (out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
  assert not errors,errors
  b.close()
srv.shutdown();print(results)
