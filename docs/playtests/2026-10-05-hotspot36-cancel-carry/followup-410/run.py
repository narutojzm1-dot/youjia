import json,time,io
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
from fish_image_classifier import label
out=Path(__file__).parent;source='82f902a0f22f50032bff9acbe542d0f1953ae684';url='https://narutojzm1-dot.github.io/youjia/';r={'source':source,'actions':[],'errors':[],'network':[]};cmd=out/'command.json'
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader']);c=b.new_context(viewport={'width':1280,'height':720});pg=c.new_page()
 pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None);pg.on('response',lambda z:r['network'].append({'url':z.url,'status':z.status}) if '.pck' in z.url else None)
 pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
 try:
  r['before']=pg.request.get(url+'game-release.json?t='+str(time.time())).json();assert r['before']['sourceCommit']==source
  pg.goto(url);r['html']=pg.locator('html').get_attribute('data-build');assert r['html']=='game-'+source[:7];pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1500);pg.mouse.click(640,368);pg.wait_for_timeout(2000);pg.screenshot(path=str(out/'initial.png'))
  while True:
   if not cmd.exists():pg.wait_for_timeout(200);continue
   v=json.loads(cmd.read_text());cmd.unlink()
   for a in v.get('actions',[]):
    r['actions'].append({'input':a,'time':time.monotonic()})
    if a[0]=='click':pg.mouse.click(a[1],a[2])
    elif a[0]=='key':pg.keyboard.press(a[1])
    elif a[0]=='wait':pg.wait_for_timeout(a[1])
    elif a[0]=='hold':pg.keyboard.down(a[1]);pg.wait_for_timeout(a[2]);pg.keyboard.up(a[1])
    elif a[0]=='reel-observe':
     t=time.monotonic();caught=False
     while time.monotonic()-t<35:
      im=Image.open(io.BytesIO(pg.screenshot()));lab=label(im)
      if lab=='reel':
       im.save(out/'real-reel-observed.png');r['actions'].append({'input':['click',1165,677],'reason':'screen-only-reel-label','time':time.monotonic()});pg.mouse.click(1165,677);caught=True;break
      pg.wait_for_timeout(120)
     r.setdefault('reel_attempts',[]).append({'clicked':caught,'time':time.monotonic()})
   for k in range(v.get('frames',1)):
    pg.screenshot(path=str(out/(v['name']+f'-{k:02}.png')));pg.wait_for_timeout(v.get('interval',200))
   (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));(out/'done').write_text(v['name'])
   if v.get('exit'):break
  r['after']=pg.request.get(url+'game-release.json?t='+str(time.time())).json();assert r['after']['sourceCommit']==source
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
