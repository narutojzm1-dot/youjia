import functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
root=Path(__file__).resolve().parents[2]
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
s=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=str(root)));threading.Thread(target=s.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']);page=b.new_page(viewport={'width':1320,'height':1120});errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
  page.goto(f'http://127.0.0.1:{s.server_port}/test/walk_calibration/index.html');page.wait_for_function('window.calibrationReady===true')
  for candidate in ['current','door_lower','left_bank','fence_front']:
   page.select_option('#pick',candidate)
   assert candidate in page.locator('#details').inner_text()
  page.select_option('#pick','left_bank');page.screenshot(path=str(root/'test/walk_calibration/overlay.png'))
  box=page.locator('#map').bounding_box();page.mouse.move(box['x']+box['width']/2,box['y']+box['height']/2);assert '640' in page.locator('#details').inner_text()
  page.select_option('#weather','overcast');page.click('#toggle');page.click('#toggle');assert not errors
  (root/'test/walk_calibration/browser-evidence.json').write_text(json.dumps({'browser':b.version,'status':'PASS','errors':errors,'checks':['four candidate switches','sunny/overcast decode','1280x720 world mapping center','overlay toggle'],'scope':'isolated calibration visualizer, not game runtime'},indent=2)+'\n');b.close()
finally:s.shutdown()
