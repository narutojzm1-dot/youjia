import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/title392-web');r={'runtime':'95925950d795b39a5444e9cad911644171442627','input':'mouse; CSS viewport simulation, not hardware URL bar','actions':[],'errors':[],'popups':[]}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 c=None;pg=None;idx=0
 while not (out/'stop').exists():
  f=out/f'cmd{idx}.json'
  if not f.exists():time.sleep(.2);continue
  cmd=json.loads(f.read_text());idx+=1;r['actions'].append(cmd)
  if 'new' in cmd:
   if c:c.close()
   w,h,d=cmd['new'];c=b.new_context(viewport={'width':w,'height':h},device_scale_factor=d,is_mobile=True,has_touch=True);pg=c.new_page();pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
   pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
   pg.goto('http://127.0.0.1:8195/',wait_until='domcontentloaded');pg.wait_for_function('window.first',timeout=120000);pg.wait_for_timeout(1600)
  if 'click' in cmd:pg.mouse.click(*cmd['click']);pg.wait_for_timeout(1500)
  if 'key' in cmd:pg.keyboard.press(cmd['key']);pg.wait_for_timeout(1500)
  if 'resize' in cmd:w,h=cmd['resize'];pg.set_viewport_size({'width':w,'height':h});pg.wait_for_timeout(1800)
  for other in list(c.pages):
   if other!=pg:
    other.wait_for_load_state();r['popups'].append({'url':other.url,'title':other.title(),'text':other.locator('body').inner_text()[:150]});other.screenshot(path=str(out/(cmd.get('shot','popup')+'-popup.png')));other.close()
  if 'shot' in cmd:pg.screenshot(path=str(out/(cmd['shot']+'.png')))
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));(out/f'done{idx-1}').write_text('ok')
 b.close()
