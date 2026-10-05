import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/pet30-evidence');out.mkdir(exist_ok=True)
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory='/workspace/pet30-harness-web'))
threading.Thread(target=srv.serve_forever,daemon=True).start()
results=[]
with sync_playwright() as p:
 for w,h in [(1280,720)]:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h});errors=[];pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None);pg.goto(f'http://127.0.0.1:{srv.server_port}/index.html');pg.wait_for_function('window.petReady',timeout=120000)
  for stage in range(8):
   pg.evaluate('(s)=>window.petStage=s',stage);pg.wait_for_function('(s)=>window.petResult.stage===s',arg=stage);pg.wait_for_timeout(200)
   r=pg.evaluate('window.petResult');assert r['pose'] in ['glance','idle'],r
   assert r['heart']=={} and r['remaining']>0 and r['facing']==1 and r['turn_pause']>0.5,r
   pg.screenshot(path=str(out/f'{w}-{h}-{stage}.png'));results.append(dict(r,viewport=[w,h],page_errors=list(errors)))
  (out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
  (out/f'{w}-{h}-errors.json').write_text(json.dumps(errors,indent=2))
  assert not errors,errors
  pg.close()
  b.close()
srv.shutdown();(out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results)
