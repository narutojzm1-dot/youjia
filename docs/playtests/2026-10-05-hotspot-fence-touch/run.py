import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/hotspot36-remaining-public');errors=[];actions=[]
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl']);ctx=b.new_context(viewport={'width':390,'height':844},device_scale_factor=2,is_mobile=True,has_touch=True);pg=ctx.new_page()
 pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 r=pg.goto('https://narutojzm1-dot.github.io/youjia/');html=r.text();m=pg.evaluate("fetch('game-release.json',{cache:'no-store'}).then(r=>r.json())");assert m['sourceCommit']=='4fa150819c304b03fb6a36a149e71d4bcd911000';assert 'game-4fa1508' in html
 pg.wait_for_function('window.first',timeout=120000);pg.touchscreen.tap(195,425);pg.wait_for_timeout(6000);pg.screenshot(path=str(out/'initial.png'),scale='css')
 (out/'manifest-before.json').write_text(json.dumps(m,indent=2));(out/'html-source.html').write_text(html)
 for n in range(40):
  f=out/'command.json'
  while not f.exists():time.sleep(.1)
  c=json.loads(f.read_text());f.unlink();actions.append(c)
  if c.get('quit'):break
  if 'key' in c:pg.keyboard.press(c['key'])
  if 'batch' in c:
   for step in c['batch']:
    actions.append({'actual_step':step,'monotonic':time.monotonic()});pg.touchscreen.tap(*step['tap']);pg.wait_for_timeout(step.get('wait',0))
  if 'tap' in c:
   c['input_start']=time.monotonic();pg.touchscreen.tap(*c['tap']);c['input_return']=time.monotonic()
  pg.wait_for_timeout(c.get('wait',100))
  for i in range(c.get('frames',1)):
   pg.screenshot(path=str(out/(c['name']+(f'-{i:02}' if c.get('frames',1)>1 else '')+'.png')),scale='css');pg.wait_for_timeout(c.get('interval',100))
  (out/'last-done').write_text(c.get('name','unnamed'))
 (out/'manifest-after.json').write_text(json.dumps(pg.evaluate("fetch('game-release.json',{cache:'no-store'}).then(r=>r.json())"),indent=2))
 (out/'result.json').write_text(json.dumps({'manifest':m,'html_build':'game-4fa1508','viewport':[390,844],'dpr':2,'mobile':True,'has_touch':True,'actions':actions,'errors':errors},indent=2));b.close()
