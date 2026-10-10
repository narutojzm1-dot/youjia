import functools, hashlib, http.server, importlib.util, json, re, shutil, subprocess, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

REPO=Path(r'D:\games\youjia-test\assistant')
ROOT=Path(__file__).parent
DIST=ROOT/'loading-web'
WEB=ROOT/'loading-stage'
OUT=ROOT/'loading-browser'
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()
game='game-'+source[:7]
for path in [WEB,OUT]:path.mkdir(exist_ok=True)
for p in DIST.glob('index.*'):shutil.copy2(p,WEB/p.name)
shutil.copy2(DIST/'index.pck',WEB/(game+'.pck'))
shutil.copytree(REPO/'web',WEB/'web',dirs_exist_ok=True)
spec=importlib.util.spec_from_file_location('stage',REPO/'tools/stage_web_engine.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
engine=m.stage(DIST,WEB,game)
record={'source':source,'pck':{'bytes':(DIST/'index.pck').stat().st_size,'sha256':hashlib.sha256((DIST/'index.pck').read_bytes()).hexdigest()},'engine':engine,'requests':[]}

class Handler(http.server.SimpleHTTPRequestHandler):
 protocol_version='HTTP/1.1'
 stalled=False
 invalid=False
 def log_message(self,*args):pass
 def handle(self):
  try:super().handle()
  except (BrokenPipeError,ConnectionResetError,ConnectionAbortedError):pass
 def do_GET(self):
  if self.path.startswith('/'+game+'.pck'):
   data=(WEB/(game+'.pck')).read_bytes()
   start=int(re.search(r'bytes=(\d+)-',self.headers.get('Range','bytes=0-'))[1])
   ranged='Range' in self.headers
   self.send_response(206 if ranged else 200)
   self.send_header('Content-Type','application/octet-stream');self.send_header('Content-Length',str(len(data)-start))
   self.send_header('Cache-Control','max-age=600');self.send_header('ETag','"candidate"')
   if ranged:self.send_header('Content-Range',f'bytes {start-1 if Handler.invalid else start}-{len(data)-1}/{len(data)}')
   self.end_headers()
   record['requests'].append({'range':self.headers.get('Range'),'offset':start,'bytes':len(data)-start})
   try:
    if Handler.invalid and not ranged:
     self.wfile.write(data[:1048576]);self.wfile.flush();time.sleep(24);self.close_connection=True;return
    if not Handler.stalled:
     Handler.stalled=True;self.wfile.write(data[:1048576]);self.wfile.flush();time.sleep(24)
    self.wfile.write(data[start:])
   except (BrokenPipeError,ConnectionResetError,ConnectionAbortedError):pass
   return
  super().do_GET()
 def end_headers(self):
  if not self.path.endswith('.pck'):self.send_header('Cache-Control','max-age=600')
  super().end_headers()
server=http.server.ThreadingHTTPServer(('127.0.0.1',8786),functools.partial(Handler,directory=str(WEB)))
threading.Thread(target=server.serve_forever,daemon=True).start()
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
 context=browser.new_context(viewport={'width':1280,'height':720})
 page=context.new_page();errors=[];console=[];network=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda msg:console.append({'type':msg.type,'text':msg.text}))
 cdp=context.new_cdp_session(page);cdp.send('Network.enable')
 cdp.on('Network.responseReceived',lambda e:network.append({k:e['response'].get(k) for k in ['url','status','fromDiskCache']}))
 page.goto('http://127.0.0.1:8786/',wait_until='domcontentloaded')
 page.wait_for_function("document.querySelector('#loading').hidden",timeout=60000)
 record['cold']=page.evaluate('({build:document.documentElement.dataset.build,timings:window.youjiaLoadTimings})')
 page.screenshot(path=str(OUT/'cold-title.png'))
 assert record['cold']['timings'].get('downloadRetry') is not None, 'forced idle recovery was not exercised'
 assert record['requests'][1]['offset']==1048576
 page.mouse.click(640,368);page.wait_for_timeout(2000)
 page.screenshot(path=str(OUT/'yard.png'))
 read='''async()=>{const db=await new Promise((y,n)=>{const r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)});const v=await new Promise((y,n)=>{const r=db.transaction('records','readonly').objectStore('records').get('current');r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)});db.close();return v?.payload_bytes?JSON.parse(v.payload_bytes):null}'''
 def wait_payload(predicate):
  for _ in range(100):
   value=page.evaluate(read)
   if value and predicate(value):return value
   page.wait_for_timeout(300)
  raise AssertionError('ordinary saved state did not reach expected condition')
 page.mouse.click(128,600)
 wait_payload(lambda v:((v.get('exploration') or {}).get('session') or {}).get('state')=='active')
 page.wait_for_timeout(700);page.screenshot(path=str(OUT/'ordinary-outing.png'))
 page.mouse.click(1190,43)
 wait_payload(lambda v:(v.get('exploration') or {}).get('session') is None and v.get('exploration_committed_serial',0)>0)
 record['saveBefore']=page.evaluate(read)
 assert record['saveBefore'] is not None
 page.reload(wait_until='domcontentloaded');page.wait_for_function("document.querySelector('#loading').hidden",timeout=30000)
 record['reload']=page.evaluate('window.youjiaLoadTimings')
 page.mouse.click(640,368);page.wait_for_timeout(1500)
 record['saveAfter']=page.evaluate(read)
 (OUT/'saved-trip-before-assert.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
 assert record['saveAfter']['keepsakes']==record['saveBefore']['keepsakes']
 assert record['saveAfter'] is not None
 assert record['saveAfter']['exploration_committed_serial']==record['saveBefore']['exploration_committed_serial']>0
 assert record['saveAfter']['version']==record['saveBefore']['version']
 page.screenshot(path=str(OUT/'reload-yard.png'))
 page.reload(wait_until='domcontentloaded');page.wait_for_function("document.querySelector('#loading').hidden",timeout=30000)
 record['warm']=page.evaluate('window.youjiaLoadTimings')
 assert len(record['requests'])==2,'recovered complete PCK should survive reload in the asset cache'
 record.update(errors=errors,console=console,network=network,browser=browser.version)
 (OUT/'result.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
 assert not errors,errors
 print(json.dumps({'requests':record['requests'],'cold':record['cold'],'reload':record['reload'],'warm':record['warm'],'errors':errors},ensure_ascii=False),flush=True)
 context.close()
 Handler.invalid=True
 negative=browser.new_context(viewport={'width':1280,'height':720});page=negative.new_page()
 page.goto('http://127.0.0.1:8786/',wait_until='domcontentloaded')
 page.wait_for_function("window.youjiaLoadTimings?.failed !== undefined",timeout=30000)
 record['invalidRange']=page.evaluate("({hidden:document.querySelector('#loading').hidden,detail:document.querySelector('#loading-detail').innerText,timings:window.youjiaLoadTimings})")
 (OUT/'invalid-range-before-assert.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
 assert not record['invalidRange']['hidden'];assert '断点响应不正确' in record['invalidRange']['detail'];assert 'firstFrame' not in record['invalidRange']['timings']
 page.screenshot(path=str(OUT/'invalid-range-blocked.png'))
 (OUT/'result.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
 print('NEGATIVE '+json.dumps(record['invalidRange'],ensure_ascii=False),flush=True)
 browser.close()
server.shutdown()
