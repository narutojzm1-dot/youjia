import json,os
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/hint362-candidate');results=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,2),(390,844,2),(844,390,3),(390,844,3)]:
  key=f'{w}-{h}-dpr{dpr}';errors=[];actions=[]
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  ctx=b.new_context(viewport={'width':w,'height':h},device_scale_factor=dpr);pg=ctx.new_page()
  pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  r=pg.goto('http://127.0.0.1:8193/');html=r.text();pg.wait_for_function('window.first',timeout=120000);pg.wait_for_timeout(700)
  def shot(name):pg.screenshot(path=str(out/f'{key}-{name}.png'),scale='css')
  shot('title');pg.mouse.click(w/2,h/2);pg.wait_for_timeout(6500);shot('yard')
  # Real mouse targets in visible yard; no game/node/string injection.
  points=[(w*.57,h*.57),(w*.70,h*.61)] if w>h else [(250,530),(300,580)]
  for i,(x,y) in enumerate(points):
   pg.mouse.click(x,y);actions.append({'click':[x,y]});pg.wait_for_timeout(1800);shot('target'+str(i))
  pg.set_viewport_size({'width':h,'height':w});pg.wait_for_timeout(1800);shot('rotated')
  pg.mouse.click(80,w-42 if h>w else w-78);pg.wait_for_timeout(900);shot('album-probe')
  pg.keyboard.press('Escape');pg.wait_for_timeout(400)
  results.append({'case':key,'source':'8f30ab84d2762fbad809f91b43cda5781258a72c','pck_sha256':'7925e4e0fb187fe056a4918ca4ca8265f0d33c91c9228d593674cef53d5e466d','html_sha256':__import__('hashlib').sha256(html.encode()).hexdigest(),'actions':actions,'errors':errors});b.close()
(out/'result.json').write_text(json.dumps(results,indent=2))
