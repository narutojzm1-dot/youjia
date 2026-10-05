import json,time,io
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
from fish_image_classifier import label
out=Path(__file__).parent; source='0c7f5d7283cdfd2412205b53653468c59ba3b544';url='https://narutojzm1-dot.github.io/youjia/';r={'source':source,'actions':[],'errors':[],'network':[]}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader']);c=b.new_context(viewport={'width':1280,'height':720});pg=c.new_page()
 pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None);pg.on('response',lambda z:r['network'].append({'url':z.url,'status':z.status}) if '.pck' in z.url else None)
 pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
 def shot(n):
  r.setdefault('screens',[]).append({'name':n,'time':time.monotonic()});pg.screenshot(path=str(out/(n+'.png')))
 def click(x,y):
  r['actions'].append({'click':[x,y],'time':time.monotonic()});pg.mouse.click(x,y)
 def key(k):
  r['actions'].append({'key':k,'time':time.monotonic()});pg.keyboard.press(k)
 try:
  r['before']=pg.request.get(url+'game-release.json?t='+str(time.time())).json();assert r['before']['sourceCommit']==source
  pg.goto(url);r['html']=pg.locator('html').get_attribute('data-build');assert r['html']=='game-'+source[:7];pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1500);click(640,368);pg.wait_for_timeout(2000);shot('00-yard')
  click(750,540);pg.wait_for_timeout(4500);key('Space');pg.wait_for_timeout(150);shot('01-cast')
  start=time.monotonic();r['reel_clicked']=False
  while time.monotonic()-start<30:
   im=Image.open(io.BytesIO(pg.screenshot()));lab=label(im)
   if lab=='reel':
    im.save(out/'02-reel.png');click(1165,677);r['reel_clicked']=True;r['reel_at']=time.monotonic();break
   pg.wait_for_timeout(100)
  if r['reel_clicked']:
   pg.wait_for_timeout(500);shot('03-after-reel');click(520,510);shot('04-after-shore');key('Space');pg.wait_for_timeout(400);shot('05-after-space');r['chain_seconds']=time.monotonic()-r['reel_at'];pg.wait_for_timeout(2000);shot('06-later')
  else:shot('02-no-reel')
  r['after']=pg.request.get(url+'game-release.json?t='+str(time.time())).json();assert r['after']['sourceCommit']==source
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
