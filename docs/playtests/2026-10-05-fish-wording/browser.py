import http.server,functools,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/tmp/fish-wording-browser');out.mkdir(exist_ok=True)
class Handler(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Handler,directory='/tmp/fish-wording-web'));threading.Thread(target=server.serve_forever,daemon=True).start()
results=[]
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  for lang in ['zh-CN','en']:
   page=b.new_page(viewport={'width':1280,'height':720});errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
   page.add_init_script('window.testLocale='+json.dumps(lang))
   page.goto(f'http://127.0.0.1:{server.server_port}/index.html');page.wait_for_function('window.fishProbe',timeout=120000)
   r=page.evaluate('window.fishProbe');assert r['carry']=='odd' and r['key']=='notice.fishing.caught.odd',r
   assert r['notice']==({'zh-CN':'钓到一条奇怪的鱼。','en':'Caught a peculiar fish.'}[lang]),r
   assert not errors,errors
   page.screenshot(path=str(out/(lang+'.png')));results.append(dict(r,page_errors=errors));page.close()
  b.close()
 (out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results)
finally:server.shutdown()
