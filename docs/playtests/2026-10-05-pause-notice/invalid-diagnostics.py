import json,sys,time
from pathlib import Path
from playwright.sync_api import sync_playwright
url,folder=sys.argv[1:3];out=Path(folder);out.mkdir(parents=True,exist_ok=True)
events=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,3),(390,844,3)]:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h},device_scale_factor=dpr);errors=[]
  pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  pg.goto(url);pg.wait_for_function('window.first',timeout=120000)
  def snap(stage):
   backend=pg.evaluate("window.__manusBgm?JSON.parse(window.__manusBgm.diagnostics()):null")
   f=f'{w}-{h}-dpr{dpr}-{stage}.png';pg.screenshot(path=str(out/f),scale='css')
   e={'stage':stage,'view':[w,h,dpr],'build':pg.locator('html').get_attribute('data-build'),'backend':backend,'errors':errors.copy(),'screenshot':f}
   events.append(e);(out/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2));return backend
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(350);pg.keyboard.press('Escape');pg.wait_for_timeout(8500)
  snap('paused-before-controls')
  music=(590,194) if w==844 else (190,480)
  ambience=(590,291) if w==844 else (190,616)
  pg.mouse.click(*music,delay=80);pg.wait_for_timeout(500);m=snap('music-half')
  assert 0.40<m['music_volume']<0.60,m
  pg.mouse.click(*ambience,delay=80);pg.wait_for_timeout(500);a=snap('ambience-half')
  assert 0.40<a['ambience_volume']<0.60,a
  mute=(252,297) if w==844 else (190,666)
  pg.mouse.click(*mute,delay=80);pg.wait_for_timeout(500);m=snap('muted')
  assert m['master_mute'],m
  pg.mouse.click(*mute,delay=80);pg.wait_for_timeout(500);m=snap('unmuted')
  assert not m['master_mute'],m
  pg.keyboard.press('Escape');pg.wait_for_timeout(300);snap('resume-first-hint')
  # Existing visible first-hint route; pause again and keep it unread for 5s.
  pg.keyboard.press('Escape');pg.wait_for_timeout(5500);snap('paused-visible-hint')
  pg.keyboard.press('Escape');pg.wait_for_timeout(300);snap('resume-preserved-hint')
  assert not errors,errors
  b.close()
print(json.dumps(events,ensure_ascii=False))
