import asyncio,json,sys
from pathlib import Path
from playwright.async_api import async_playwright
async def main():
 async with async_playwright() as p:
  b=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
  page=await b.new_page(viewport={'width':1280,'height':720})
  errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda e: errors.append(e.text) if e.type=='error' else None)
  await page.goto('http://127.0.0.1:8820/index.html')
  await page.wait_for_function('window.skyReport !== undefined',timeout=120000)
  await page.evaluate("window.dispatchEvent(new Event('youjia:first-frame'))")
  await page.wait_for_timeout(300)
  reports=[]
  for i in range(4):
   await page.evaluate('(i)=>window.skyStage(i)',i)
   await page.wait_for_timeout(200)
   reports.append(await page.evaluate('window.skyReport'))
   await page.screenshot(path=f'/workspace/quiet-sky-evidence/{sys.argv[1]}/stage-{i:02}.png')
  Path(f'/workspace/quiet-sky-evidence/{sys.argv[1]}/results.json').write_text(json.dumps({'source_sha':'c12a3d4750c974a4a34f42c78a2ded89bffefe6b','controlled':True,'reports':reports,'errors':errors},indent=2))
  await b.close()
asyncio.run(main())
