import json,time,hashlib,os
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/tmp/gate399-instrumented');r={'console':[],'events':[],'errors':[],'navigation':[],'diagnostic':True}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=2,has_touch=True,is_mobile=True);pg=c.new_page()
 pg.on('console',lambda m:r['console'].append({'t':time.monotonic(),'type':m.type,'text':m.text}))
 pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('framenavigated',lambda f:r['navigation'].append(f.url))
 pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
 try:
  pg.goto('http://127.0.0.1:8199/');pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1200)
  for x,y,wait,name in [(640,368,1500,'yard'),(329,563,8500,'outside'),(706,500,3500,'walked')]:
   r['events'].append({'t':time.monotonic(),'touchscreen.tap':[x,y]});pg.touchscreen.tap(x,y);pg.wait_for_timeout(wait);pg.screenshot(path=str(out/(name+'.png')),scale='css')
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
