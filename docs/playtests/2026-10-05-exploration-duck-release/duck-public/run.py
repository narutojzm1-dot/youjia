from playwright.sync_api import sync_playwright
from pathlib import Path
import json,time
out=Path('/workspace/duck-public-a936');url='https://narutojzm1-dot.github.io/youjia/';sha='a936bea68bfb37eea47b00c09e3767af74c72b61'
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=b.new_page(viewport={'width':1280,'height':720});errors=[];console=[]
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:console.append(m.text) if m.type=='error' else None)
 for attempt in range(80):
  r=page.request.get(url+'game-release.json?check='+str(time.time()));manifest=r.json()
  if manifest.get('sourceCommit')==sha:break
  time.sleep(10)
 else:raise RuntimeError('target not published')
 page.goto(url+'?verify=a936bea');assert page.locator('html').get_attribute('data-build')=='game-a936bea';assert manifest['entry']=='game-a936bea'
 (out/'manifest.json').write_text(json.dumps(manifest,indent=2));page.wait_for_function('document.querySelector("#loading").hidden',timeout=120000)
 page.mouse.click(640,368);page.wait_for_timeout(1500);page.screenshot(path=str(out/'arrival.png'))
 page.mouse.click(651,503);page.wait_for_timeout(3000)
 for i in range(24):
  page.keyboard.press('Space');page.wait_for_timeout(550);page.screenshot(path=str(out/f'natural-{i:02}.png'))
 page.mouse.click(114,675);page.wait_for_timeout(700);page.screenshot(path=str(out/'album.png'))
 (out/'result.json').write_text(json.dumps({'sourceCommit':sha,'data_build':page.locator('html').get_attribute('data-build'),'pageerrors':errors,'consoleerrors':console,'browser':b.version,'scope':'ordinary pointer and Space only; screenshots require visual verification'},indent=2));print('CAPTURED',errors,console,flush=True);b.close()
