import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/hidpi321-observer-evidence');out.mkdir(exist_ok=True)
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory='/workspace/hidpi321-observer-web'));threading.Thread(target=srv.serve_forever,daemon=True).start()
rows=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,1),(844,390,2),(390,844,3)]:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h},device_scale_factor=dpr);errs=[]
  pg.on('pageerror',lambda e:errs.append(str(e)));pg.on('console',lambda m:errs.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)");pg.goto(f'http://127.0.0.1:{srv.server_port}/index.html');pg.wait_for_function('window.first',timeout=120000)
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(1800)
  def read():
   serial=pg.evaluate('window.observed?.serial||0');pg.evaluate('window.observeRequested=true');pg.wait_for_function('(n)=>(window.observed?.serial||0)>n',arg=serial,timeout=30000);return pg.evaluate('window.observed')
  before=read();attempts=[];success=False
  for attempt in range(6):
   obs=read(); choices=[(k,v) for k,v in obs['points'].items() if 30<v[0]<w-30 and 100<v[1]<h-150]
   assert choices,obs
   actor,point=next(((k,v) for k,v in choices if k.startswith('sheep')),choices[0]);pg.mouse.click(*point)
   pg.wait_for_timeout(2200);after=read();attempts.append({'actor':actor,'before':obs,'after':after})
   if after['last_notice'].startswith('notice.pet.'):
    success=True;break
  pg.screenshot(path=str(out/f'{w}-{h}-dpr{dpr}-pet.png'),scale='css');rows.append({'viewport':[w,h],'dpr':dpr,'success':success,'attempts':attempts,'errors':errs});(out/'result.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
  assert not errs,errs
  assert success,rows[-1]
  b.close()
srv.shutdown();print('PASS',len(rows))
