import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/yard-hotspots-touch-public');errors=[];actions=[]
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl']);ctx=b.new_context(viewport={'width':390,'height':844},device_scale_factor=2,is_mobile=True,has_touch=True);pg=ctx.new_page()
 pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 r=pg.goto('https://narutojzm1-dot.github.io/youjia/');html=r.text();m=pg.evaluate("fetch('game-release.json',{cache:'no-store'}).then(r=>r.json())");assert m['sourceCommit']=='a067ce9b6674d5c1b35cdc2410f3d507f0f4d6a0';assert 'game-a067ce9' in html
 pg.wait_for_function('window.first',timeout=120000);pg.touchscreen.tap(195,425);pg.wait_for_timeout(6000);pg.screenshot(path=str(out/'initial.png'),scale='css')
 for n in range(10):
  f=out/'command.json'
  while not f.exists():time.sleep(.1)
  c=json.loads(f.read_text());f.unlink();actions.append(c)
  if c.get('quit'):break
  if 'tap' in c:
   c['input_start']=time.monotonic();pg.touchscreen.tap(*c['tap']);c['input_return']=time.monotonic()
  pg.wait_for_timeout(c.get('wait',100))
  for i in range(c.get('frames',1)):
   pg.screenshot(path=str(out/(c['name']+(f'-{i:02}' if c.get('frames',1)>1 else '')+'.png')),scale='css');pg.wait_for_timeout(c.get('interval',100))
 (out/'result.json').write_text(json.dumps({'manifest':m,'html_build':'game-a067ce9','viewport':[390,844],'dpr':2,'mobile':True,'has_touch':True,'actions':actions,'errors':errors},indent=2));b.close()
