import argparse,functools,http.server,json,threading
from pathlib import Path
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser();parser.add_argument('--web',required=True);parser.add_argument('--out',required=True);args=parser.parse_args()
class Handler(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Handler,directory=args.web));threading.Thread(target=server.serve_forever,daemon=True).start()
result={'status':'FAIL','cases':[],'errors':[],'host_sha':'1319bffb7ef69619d03a25ff9d8695e8928b032b'}
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
  for legacy in [False,True]:
   context=browser.new_context();page=context.new_page()
   page.on('pageerror',lambda e:result['errors'].append(str(e)))
   page.on('console',lambda m:result['errors'].append(m.text) if m.type=='error' else None)
   url=f'http://127.0.0.1:{server.server_port}/index.html'+('?legacy=1' if legacy else '')
   page.goto(url);page.wait_for_function('window.godotBridgeResult!==undefined',timeout=180000)
   first=page.evaluate('window.godotBridgeResult');result['cases'].append({'legacy':legacy,'reload':False,**first})
   page.reload();page.wait_for_function('window.godotBridgeResult!==undefined',timeout=180000)
   again=page.evaluate('window.godotBridgeResult');result['cases'].append({'legacy':legacy,'reload':True,**again})
   context.close()
  result['browser']=browser.version;browser.close()
 result['status']='PASS' if not result['errors'] and all(c['status']=='PASS' for c in result['cases']) else 'FAIL'
finally:
 Path(args.out).write_text(json.dumps(result,ensure_ascii=False,indent=2));server.shutdown()
print(result['status'],sum(len(c['checks']) for c in result['cases']),result['errors'])
if result['status']!='PASS':raise SystemExit(1)
