"""Actual generated shell, delayed Host module and failed engine PCK fetch."""
import argparse,asyncio,functools,http.server,threading,json
from pathlib import Path
from playwright.async_api import async_playwright
p=argparse.ArgumentParser();p.add_argument('--web',required=True);p.add_argument('--out',required=True);args=p.parse_args()
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=args.web))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def run():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']);page=await browser.new_page()
  await page.add_init_script('''window.unhandled=[];window.addEventListener('unhandledrejection',e=>window.unhandled.push(String(e.reason)));
   let reject;Object.defineProperty(window,'rejectSaveRuntime',{get:()=>reject,set:f=>reject=e=>{window.engineRejected=String(e);window.failedBeforeModule=!window.moduleReleased;f(e);}});''')
  async def delayed(route):
   response=await route.fetch()
   await page.wait_for_function('window.engineRejected!==undefined',timeout=60000)
   await asyncio.sleep(.15) # Let unhandledrejection dispatch before module attachment.
   await page.evaluate('window.moduleReleased=true')
   await route.fulfill(response=response)
  await page.route('**/bridge.mjs',delayed)
  await page.route('**/index.pck',lambda route:route.fulfill(status=404,body='intentional engine failure'))
  await page.goto(f'http://127.0.0.1:{server.server_port}/index.html',wait_until='domcontentloaded')
  await page.wait_for_function('window.moduleReleased===true',timeout=60000)
  result=await page.evaluate('''async()=>{
   const m=await import('./bridge.mjs');
   let error='';try{await m.bridge.open('youjia-recovery-test-candidate-v1-early-failure','candidate-v1');}catch(e){error=String(e);}
   await new Promise(r=>setTimeout(r,50));
   return {failedBeforeModule,engineRejected,error,unhandled,databases:await indexedDB.databases(),captured:window.captureAfterRuntime===true};
  }''')
  assert result['failedBeforeModule'],result
  assert result['error']==result['engineRejected'] and result['error'],result
  assert not result['unhandled'] and not result['captured'],result
  assert not any(d['name'].startswith('youjia-recovery-test-') for d in result['databases']),result
  Path(args.out).write_text(json.dumps({'status':'PASS','checks':4,'browser':browser.version,'result':result,'scope':'real engine PCK load failure in generated shell before delayed bridge module; no Host database/capture'},indent=2)+'\n')
  print('PASS 4 runtime-before-module checks');await browser.close()
try:asyncio.run(run())
finally:server.shutdown()
