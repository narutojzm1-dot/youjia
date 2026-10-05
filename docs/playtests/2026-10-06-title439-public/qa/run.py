from pathlib import Path
import json,time,hashlib,subprocess,argparse
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--runtime',required=True);ap.add_argument('--entry',required=True);ap.add_argument('--pck',required=True);args=ap.parse_args()
out=Path('/tmp/title439-public-qa');out.mkdir(exist_ok=False);runtime=args.runtime;url='https://narutojzm1-dot.github.io/youjia/';r={'runtime':runtime,'actions':[],'errors':[],'sources':[],'popups':[],'console':[],'network':[]}
def source(stage):
 d=pg.request.get(url+'game-release.json?t='+str(time.time())).json();r['sources'].append({'stage':stage,'manifest':d});assert d['sourceCommit']==runtime,d
 if stage=='after':
  actual=pg.locator('html').get_attribute('data-build');assert actual==args.entry;v=pg.request.get(url+args.entry+'.pck');check={'stage':stage,'entry':actual,'bytes':len(v.body()),'sha256':hashlib.sha256(v.body()).hexdigest()};r['end_pck']=check;assert check['sha256']==args.pck
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader']);ctx=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=2);pg=ctx.new_page();pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)");ctx.on('response',lambda response:r['network'].append({'url':response.url,'status':response.status,'time':time.monotonic()}) if 'open-source-licenses.html' in response.url else None);pg.on('console',lambda m:r['console'].append({'type':m.type,'text':m.text,'time':time.monotonic()}));pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
 try:
  source('before');v=pg.request.get(url+args.entry+'.pck');r['pck']={'bytes':len(v.body()),'sha256':hashlib.sha256(v.body()).hexdigest()};assert r['pck']['sha256']==args.pck;pg.goto(url+"?qa="+str(time.time()));r['entry']=pg.locator('html').get_attribute('data-build');assert r['entry']==args.entry;pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1000);pg.screenshot(path=str(out/'initial.png'),scale='css')
  while True:
   f=out/'command.json'
   if not f.exists():pg.wait_for_timeout(250);continue
   c=json.loads(f.read_text());f.unlink();r['actions'].append({'time':time.monotonic(),'command':c})
   for a in c.get('actions',[]):
    if a[0]=='move':pg.mouse.move(a[1],a[2])
    elif a[0]=='down':pg.mouse.down()
    elif a[0]=='up':pg.mouse.up()
    elif a[0]=='key':pg.keyboard.press(a[1])
    elif a[0]=='viewport':pg.set_viewport_size({'width':a[1],'height':a[2]})
    elif a[0]=='wait':pg.wait_for_timeout(a[1])
    elif a[0]=='closepop':
     for pop in ctx.pages:
      if pop!=pg:
       pop.wait_for_load_state();rec={'url':pop.url,'title':pop.title(),'text':pop.locator('body').inner_text()};r['popups'].append(rec);pop.screenshot(path=str(out/(c['name']+'-license.png')),scale='css');pop.close()
     pg.bring_to_front()
   pg.wait_for_timeout(150);pg.screenshot(path=str(out/(c['name']+'.png')),scale='css');(out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));(out/'done').write_text(c['name'])
   if c.get('exit'):break
  source('after')
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
