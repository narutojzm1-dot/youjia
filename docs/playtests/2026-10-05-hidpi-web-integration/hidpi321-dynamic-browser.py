import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/hidpi321-dynamic-evidence');out.mkdir(exist_ok=True)
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory='/workspace/hidpi321-web'));threading.Thread(target=srv.serve_forever,daemon=True).start()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 page=b.new_page(viewport={'width':390,'height':844},device_scale_factor=3);errs=[]
 page.on('pageerror',lambda e:errs.append(str(e)));page.on('console',lambda m:errs.append(m.text) if m.type=='error' else None)
 page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)");page.goto(f'http://127.0.0.1:{srv.server_port}/index.html');page.wait_for_function('window.first',timeout=120000)
 page.mouse.click(195,422);page.wait_for_timeout(5000)
 cdp=page.context.new_cdp_session(page);rows=[]
 for dpr in [3,2,1.75]:
  cdp.send('Emulation.setDeviceMetricsOverride',{'width':390,'height':844,'deviceScaleFactor':dpr,'mobile':False})
  page.wait_for_timeout(1800)
  canvas=page.evaluate("({dpr:devicePixelRatio,w:document.querySelector('canvas').width,h:document.querySelector('canvas').height})")
  page.mouse.click(310,44);page.wait_for_timeout(300);page.screenshot(path=str(out/f'dynamic-{dpr}.png'),scale='css');page.keyboard.press('Escape');rows.append(canvas)
 assert not errs,errs
 (out/'result.json').write_text(json.dumps({'rows':rows,'errors':errs,'scope':'CDP browser DPR changes in one live session, no game-state injection; not physical monitor hardware'},indent=2));b.close()
srv.shutdown()
