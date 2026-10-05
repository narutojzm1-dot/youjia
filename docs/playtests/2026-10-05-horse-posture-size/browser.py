import asyncio,json
from pathlib import Path
from playwright.async_api import async_playwright
async def main():
 async with async_playwright() as p:
  b=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
  page=await b.new_page(viewport={'width':1280,'height':720})
  errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda e: errors.append(e.text) if e.type=='error' else None)
  await page.goto('http://127.0.0.1:8818/index.html')
  await page.wait_for_function('window.horseReport !== undefined',timeout=120000)
  await page.evaluate("window.dispatchEvent(new Event('youjia:first-frame'))")
  await page.wait_for_timeout(300)
  reports=[]
  for i in range(12):
   await page.evaluate('(i)=>window.horseStage(i)',i)
   await page.wait_for_timeout(200)
   reports.append(await page.evaluate('window.horseReport'))
   await page.screenshot(path=f'/workspace/horse180-evidence/stage-{i:02}.png')
  Path('/workspace/horse180-evidence/results.json').write_text(json.dumps({'source_sha':'ba3bb72f9d78ddd2740403fb66a4a380c481e84e','controlled':True,'reports':reports,'errors':errors},indent=2))
  await b.close()
asyncio.run(main())
