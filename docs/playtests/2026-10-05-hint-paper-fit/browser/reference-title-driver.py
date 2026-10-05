import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/title354-public')
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory='/workspace/title354-export'))
threading.Thread(target=srv.serve_forever,daemon=True).start(); results=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,2),(390,844,2),(844,390,3),(390,844,3)]:
  key=f'{w}-{h}-dpr{dpr}';errors=[]
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  ctx=b.new_context(viewport={'width':w,'height':h},device_scale_factor=dpr);pg=ctx.new_page()
  pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  response=pg.goto('https://narutojzm1-dot.github.io/youjia/');html=response.text();manifest=pg.evaluate("fetch('game-release.json',{cache:'no-store'}).then(r=>r.json())");assert manifest['sourceCommit']=='7c1608c7e826f458eaae979d48727b0e6e2bdf58';assert 'game-7c1608c' in html;pg.wait_for_function('window.first',timeout=120000);pg.wait_for_timeout(750)
  pg.screenshot(path=str(out/f'{key}-title.png'),scale='css')
  canvas=pg.evaluate("({dpr:devicePixelRatio,width:document.querySelector('canvas').width,height:document.querySelector('canvas').height})")
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(5500)
  pg.screenshot(path=str(out/f'{key}-yard.png'),scale='css')
  results.append({'case':key,'sourceCommit':manifest['sourceCommit'],'entry':manifest['entry'],'html_build':'game-7c1608c','canvas':canvas,'errors':errors,'action':'real mouse click center title entry; no game state injection'});b.close()
(out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
