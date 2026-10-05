import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/confirm373-public');source='e0d699b8cbaecfabc24a70d2144a7188b5808880';url='https://narutojzm1-dot.github.io/youjia/'
r={'source':source,'input':'mouse CSS coordinates, not touch','cases':[],'errors':[]}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 for w,h,d in [(390,844,2),(390,844,3),(360,640,2),(360,640,3)]:
  c=b.new_context(viewport={'width':w,'height':h},device_scale_factor=d,is_mobile=True,has_touch=True);pg=c.new_page();tag=f'{w}x{h}-dpr{d}';case={'tag':tag,'actions':[]};r['cases'].append(case)
  pg.on('pageerror',lambda e:r['errors'].append(str(e)))
  pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  manifest=pg.request.get(url+'game-release.json?t='+str(time.time())).json();assert manifest['sourceCommit']==source,manifest
  pg.goto(url+'?confirm373='+tag,wait_until='domcontentloaded');build=pg.locator('html').get_attribute('data-build');assert build=='game-'+source[:7],build
  case.update(manifest=manifest,html=build);pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(2000)
  def shot(label):pg.screenshot(path=str(out/f'{tag}-{label}.png'))
  def click(x,y,label):case['actions'].append({'mouse':[x,y],'label':label,'time':time.time()});pg.mouse.click(x,y);pg.wait_for_timeout(2300)
  click(w/2,h/2+8,'enter');click(w-80,44,'pause');click(w/2,h/2-82,'return-confirm');shot('confirm')
  click(w/2,h/2+68,'cancel');shot('cancel-pause');click(w/2,h/2-194,'resume');shot('yard')
  if w==390 and d==2:
   click(w-80,44,'pause-again');click(w/2,h/2-82,'confirm-again');pg.set_viewport_size({'width':844,'height':390});case['actions'].append({'resize':[844,390]});pg.wait_for_timeout(2200);shot('rotate-confirm')
  c.close();(out/'results.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(tag,flush=True)
 b.close()
