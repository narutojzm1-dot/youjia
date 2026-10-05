import os,time,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/confirm373-touch-supplement/public')
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
 c=b.new_context(viewport={'width':390,'height':844},device_scale_factor=2,is_mobile=True,has_touch=True)
 page=c.new_page();logs=[];page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}));page.on('pageerror',lambda e:logs.append({'type':'pageerror','text':str(e)}));page.goto('https://narutojzm1-dot.github.io/youjia/');page.wait_for_timeout(15000);page.screenshot(path=str(out/'initial.png'))
 (out/'ready').write_text('ready')
 for i in range(30):
  cmd=out/f'cmd{i}.json'
  while not cmd.exists():time.sleep(.2)
  v=json.loads(cmd.read_text())
  if v['type']=='stop':break
  if v['type']=='tap':page.touchscreen.tap(v['x'],v['y'])
  if v['type']=='resize':page.set_viewport_size(v['size'])
  page.wait_for_timeout(2500);(out/'logs.json').write_text(json.dumps(logs));page.screenshot(path=str(out/f'step{i}.png'))
 b.close()
