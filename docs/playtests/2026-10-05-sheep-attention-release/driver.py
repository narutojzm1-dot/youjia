import argparse,json,time,datetime,subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--url',required=True);ap.add_argument('--width',type=int,default=1280);ap.add_argument('--height',type=int,default=800);args=ap.parse_args();out=Path('/workspace/sheep-attention-public')
logs=[];actions=[];requests=[]
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
with sync_playwright() as p:
 browser=p.chromium.launch_persistent_context(str(out/'isolated-profile'),executable_path='/usr/bin/chromium',headless=True,viewport={'width':args.width,'height':args.height},device_scale_factor=1,args=['--no-sandbox'])
 page=browser.pages[0];page.on('console',lambda m:logs.append({'utc':now(),'type':m.type,'text':m.text}));page.on('pageerror',lambda e:logs.append({'utc':now(),'type':'pageerror','text':str(e)}));page.on('response',lambda r:requests.append({'utc':now(),'url':r.url,'status':r.status}))
 (out/'manifest-before.json').write_text(subprocess.check_output(['curl','-fsSL',args.url+'game-release.json']).decode());page.goto(args.url);page.wait_for_timeout(15000);page.screenshot(path=str(out/'initial.png'))
 for i in range(100):
  f=out/f'cmd{i}.json'
  while not f.exists():time.sleep(.2)
  v=json.loads(f.read_text());actions.append({'utc':now(),**v})
  if v['type']=='stop':break
  if v['type']=='click':page.mouse.click(v['x'],v['y'])
  if v['type']=='key':page.keyboard.press(v['key'])
  if v['type']=='resize':page.set_viewport_size(v['size'])
  if v['type']=='reload':page.reload()
  page.wait_for_timeout(v.get('wait_ms',1500));page.screenshot(path=str(out/f'step{i}.png'))
  for name,data in [('logs',logs),('actions',actions),('responses',requests)]: (out/f'{name}.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
 (out/'manifest-after.json').write_text(subprocess.check_output(['curl','-fsSL',args.url+'game-release.json']).decode())
 browser.close()
