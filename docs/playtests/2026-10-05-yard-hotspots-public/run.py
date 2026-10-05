import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/yard-hotspots-public');errors=[];actions=[]
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 ctx=b.new_context(viewport={'width':1280,'height':720});pg=ctx.new_page();pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 r=pg.goto('https://narutojzm1-dot.github.io/youjia/');html=r.text();m=pg.evaluate("fetch('game-release.json',{cache:'no-store'}).then(r=>r.json())");assert m['sourceCommit']=='1a3842c63558fa68a68ca41c2da58f4c5a254929';assert 'game-1a3842c' in html
 pg.wait_for_function('window.first',timeout=120000);pg.mouse.click(640,360);pg.wait_for_timeout(11000);pg.screenshot(path=str(out/'initial.png'))
 for n in range(100):
  f=out/'command.json'
  while not f.exists():time.sleep(.2)
  cmd=json.loads(f.read_text());f.unlink();actions.append(cmd)
  if cmd.get('quit'):break
  if 'click' in cmd:pg.mouse.click(*cmd['click'])
  if 'key' in cmd:pg.keyboard.press(cmd['key'])
  pg.wait_for_timeout(cmd.get('wait',500))
  for i in range(cmd.get('frames',1)):
   pg.screenshot(path=str(out/(cmd['name']+(f'-{i:02}' if cmd.get('frames',1)>1 else '')+'.png')));pg.wait_for_timeout(cmd.get('interval',100))
  (out/'last-done').write_text(cmd['name'])
 (out/'result.json').write_text(json.dumps({'manifest':m,'errors':errors,'actions':actions},indent=2));b.close()
