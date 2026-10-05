import json,sys,time,urllib.request
from pathlib import Path
from playwright.sync_api import sync_playwright
url,folder=sys.argv[1:3]
out=Path(folder);out.mkdir(parents=True,exist_ok=True)
records=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,3),(390,844,3)]:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h},device_scale_factor=dpr);errors=[]
  pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  pg.goto(url);pg.wait_for_function('window.first',timeout=120000)
  build=pg.locator('html').get_attribute('data-build')
  start=time.monotonic();key=f'{w}-{h}-dpr{dpr}'
  def snap(stage):
   path=f'{key}-{stage}.png';pg.screenshot(path=str(out/path),scale='css')
   records.append({'case':key,'stage':stage,'wall_seconds':round(time.monotonic()-start,3),'screenshot':path,'build':build,'errors':errors.copy()})
   (out/'events.json').write_text(json.dumps(records,ensure_ascii=False,indent=2))
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(350);snap('arrival')
  # Real Escape pauses through the normal input path, before the 4.5s timer.
  pg.keyboard.press('Escape');pg.wait_for_timeout(500);snap('pause-early')
  pg.wait_for_timeout(8000);snap('pause-after-timer')
  pg.keyboard.press('Escape');pg.wait_for_timeout(300);snap('resume')
  pg.wait_for_timeout(1600);snap('resume-readable')
  pg.wait_for_timeout(3500);snap('expired')
  assert not errors,errors
  b.close()
print(json.dumps(records,ensure_ascii=False))
