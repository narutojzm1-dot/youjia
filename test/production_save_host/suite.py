import argparse,functools,http.server,threading,json,shutil
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--web',required=True);p.add_argument('--out',required=True);a=p.parse_args()
shutil.copy(Path(__file__).with_name('suite.html'),Path(a.web)/'suite.html')
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
s=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=a.web));threading.Thread(target=s.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']);page=b.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
  page.goto(f'http://127.0.0.1:{s.server_port}/suite.html');page.wait_for_function('window.result!==undefined',timeout=60000);r=page.evaluate('window.result');r['browser']=b.version;r['pageerrors']=errors
  Path(a.out).write_text(json.dumps(r,indent=2)+'\n');print(r);assert r['status']=='PASS' and not errors;b.close()
finally:s.shutdown()
