import argparse,functools,http.server,threading,json,time,hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--web',required=True);p.add_argument('--out',required=True);a=p.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=a.web));threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for width,height in [(1280,720),(390,844)]:
   context=browser.new_context(viewport={'width':width,'height':height});page=context.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
   page.goto(f'http://127.0.0.1:{server.server_port}/');page.wait_for_function('window.duckTitle!==undefined && document.querySelector("#loading").hidden',timeout=90000);page.mouse.click(*page.evaluate('window.duckTitle'));page.wait_for_function('window.duckReadback!==undefined');page.wait_for_timeout(1000)
   for n in range(8):
    r=page.evaluate('window.duckReadback');x,y=r['pond']
    if 15<x<width-15:break
    key='ArrowRight' if x>=width-15 else 'ArrowLeft';page.keyboard.down(key);page.wait_for_timeout(1000);page.keyboard.up(key)
   caught=False
   for attempt in range(5):
    r=page.evaluate('window.duckReadback');page.mouse.click(*r['pond'])
    deadline=time.monotonic()+24
    while time.monotonic()<deadline:
     page.wait_for_timeout(100);r=page.evaluate('window.duckReadback')
     if r['carry']:caught=True;break
     if r['fish_state']==2:page.keyboard.press('Space')
    if caught:break
   assert caught, f'{width}: natural catch absent after five attempts'
   page.screenshot(path=str(out/f'{width}-catch.png'))
   # Select a concrete visible duck through ordinary pointer input, never mutate actors/carry/timers.
   r=page.evaluate('window.duckReadback');duck=min(r['ducks'],key=lambda d:abs(d['click'][0]-width/2));recipient=duck['id'];page.mouse.click(*duck['click'])
   page.wait_for_function('(id)=>window.duckReadback.ducks.some(d=>d.id===id && d.posture==="attend" && d.ack_left>0)',arg=recipient,timeout=12000)
   first=page.evaluate('window.duckReadback');page.wait_for_timeout(120);observed=page.evaluate('window.duckReadback');actual=next(d for d in observed['ducks'] if d['id']==recipient)
   assert actual['posture']=='attend' and actual['texture'].endswith('duck_attend.png') and actual['ack_left']>0 and actual['foot_error']<.01,actual
   assert not observed['carry'] and not observed['heart'],observed
   assert all(d['posture']!='attend' for d in observed['ducks'] if d['id']!=recipient)
   page.screenshot(path=str(out/f'{width}-attention.png'))
   (out/f'{width}-readback.json').write_text(json.dumps({'width':width,'height':height,'recipient':recipient,'first':first,'after_120ms':observed,'errors':errors,'browser':browser.version,'scope':'test-only readonly observation; production Main/YardWorld with natural pointer+keyboard; no timer/carry/random/position mutations'},ensure_ascii=False,indent=2)+'\n')
   assert not errors
   print('PASS',width,recipient,actual,flush=True);context.close()
  browser.close()
finally:server.shutdown()
