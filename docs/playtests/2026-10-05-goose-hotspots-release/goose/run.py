from playwright.sync_api import sync_playwright
from pathlib import Path
import json,sys
out=Path('/workspace/goose-feed-public'); errors=[]; console=[]
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=b.new_page(viewport={'width':1280,'height':720});page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:console.append(m.text) if m.type=='error' else None)
 sha='a067ce9b6674d5c1b35cdc2410f3d507f0f4d6a0'; url='https://narutojzm1-dot.github.io/youjia/'; manifest=page.request.get(url+'game-release.json').json(); assert manifest['sourceCommit']==sha,manifest; page.goto(url+'?goose-public=a067ce9'); assert page.locator('html').get_attribute('data-build')=='game-a067ce9'; (out/'manifest.json').write_text(json.dumps(manifest,indent=2));page.wait_for_function('document.querySelector("#loading").hidden',timeout=120000)
 page.mouse.click(640,368);page.wait_for_timeout(1500);page.screenshot(path=str(out/'arrival.png'));print('READY',flush=True)
 for line in sys.stdin:
  try:
   cmd=json.loads(line);act=cmd[0]
   with (out/'commands.jsonl').open('a') as log: log.write(json.dumps(cmd)+'\n')
   if act=='click':page.mouse.click(cmd[1],cmd[2])
   elif act=='key':page.keyboard.press(cmd[1])
   elif act=='hold':page.keyboard.down(cmd[1]);page.wait_for_timeout(cmd[2]);page.keyboard.up(cmd[1])
   elif act=='size':page.set_viewport_size({'width':cmd[1],'height':cmd[2]})
   elif act=='wait':page.wait_for_timeout(cmd[1])
   elif act=='shot':page.screenshot(path=str(out/cmd[1]))
   elif act=='quit':break
   print('DONE',cmd,flush=True)
  except Exception as e:print('ERR',str(e),flush=True)
 (out/'errors.json').write_text(json.dumps({'pageerrors':errors,'consoleerrors':console}));b.close()
