import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/notice311-public')
results=[]
with sync_playwright() as p:
 for w,h in [(844,390),(390,844)]:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h});errors=[]
  pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
  pg.goto('https://narutojzm1-dot.github.io/youjia/?verify=notice-d08f838');pg.wait_for_function('window.first',timeout=120000)
  assert pg.locator('html').get_attribute('data-build')=='game-d08f838'
  pg.screenshot(path=str(out/f'{w}-title.png'))
  pg.mouse.click(w/2,h/2)
  pg.wait_for_timeout(600)
  pg.screenshot(path=str(out/f'{w}-arrival.png'))
  pg.wait_for_timeout(4500)
  pg.screenshot(path=str(out/f'{w}-hint.png'))
  results.append({'viewport':[w,h],'errors':errors,'build':'game-d08f838','scope':'public Pages, natural play button and delayed first hint; no game state injection'})
  assert not errors,errors
  b.close()
(out/'result.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results)
