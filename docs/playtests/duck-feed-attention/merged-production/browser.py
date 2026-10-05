from playwright.sync_api import sync_playwright
import http.server,threading,functools,json,sys
from pathlib import Path
class Q(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Q,directory='/workspace/youjia-duck-attention/dist'));threading.Thread(target=srv.serve_forever,daemon=True).start()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']);pg=b.new_page(viewport={'width':1280,'height':720});errs=[];pg.on('pageerror',lambda e:errs.append(str(e)));pg.goto(f'http://127.0.0.1:{srv.server_port}/');pg.wait_for_function("document.querySelector('#loading').hidden",timeout=90000);print('READY',flush=True)
 pg.mouse.click(640,368);pg.wait_for_timeout(1500)
 pg.mouse.click(651,503);pg.wait_for_timeout(3000)
 for i in range(16):
  pg.keyboard.press('Space');pg.wait_for_timeout(700)
  pg.screenshot(path=str(Path('/workspace/duck-merged-checks')/f'duck-natural-{i:02}.png'))
 pg.mouse.click(114,675);pg.wait_for_timeout(700);pg.screenshot(path='/workspace/duck-merged-checks/album.png')
 print('NATURAL COMPLETE',errs,flush=True)
 b.close()
