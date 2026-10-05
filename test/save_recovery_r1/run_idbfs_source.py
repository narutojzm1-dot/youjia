"""Isolated real Chromium + exported Godot IDBFS integration. No user profile."""
import argparse,functools,http.server,json,threading,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--engine',required=True);p.add_argument('--out',required=True);args=p.parse_args()
root=Path(__file__).resolve().parent;engine=Path(args.engine).resolve()
class Handler(http.server.SimpleHTTPRequestHandler):
 def translate_path(self,path):
  if path.split('?')[0].startswith('/engine/'):
   return str(engine/path.split('?')[0].removeprefix('/engine/'))
  return super().translate_path(path)
 def log_message(self,*a):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Handler,directory=str(root)))
threading.Thread(target=server.serve_forever,daemon=True).start();base=f'http://127.0.0.1:{server.server_port}'
result={'status':'FAIL','checks':[],'errors':[]}
def check(ok,label):
 result['checks'].append({'ok':ok,'label':label})
 if not ok:raise AssertionError(label)
def instrument(page):
 page.on('pageerror',lambda e:result['errors'].append(str(e)))
 page.on('console',lambda m:result['errors'].append(m.text) if m.type=='error' else None)
def cap(page,paths):return page.evaluate('(p)=>window.capture(p)',paths)
def wait_pair(page,paths,primary,backup):
 import base64
 expected=[base64.b64encode(x.encode()).decode() for x in [primary,backup]]
 end=time.monotonic()+30
 while time.monotonic()<end:
  pair=cap(page,paths)
  if [pair['primary'].get('base64'),pair['backup'].get('base64')]==expected:return pair
  page.wait_for_timeout(100)
 raw=page.evaluate('''(p)=>new Promise(resolve=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>{const db=r.result,tx=db.transaction('FILE_DATA','readonly'),q=tx.objectStore('FILE_DATA').get(p.primaryPath);q.onsuccess=()=>{const v=q.result;resolve({keys:Object.keys(v||{}),mode:v?.mode,type:Object.prototype.toString.call(v?.contents),timestampType:Object.prototype.toString.call(v?.timestamp),length:v?.contents?.length})};tx.oncomplete=()=>db.close()}})''',paths)
 raise AssertionError('IDBFS sync wait: '+str(pair)+' record '+str(raw))
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
  context=browser.new_context();old=context.new_page();instrument(old)
  old.goto(base+'/engine/index.html');old.wait_for_function('window.godotSourcePaths',timeout=120000)
  paths=old.evaluate('window.godotSourcePaths');result['godotPaths']=paths
  check(paths['persistent'],'old engine mounts persistent IDBFS')
  probe=context.new_page();instrument(probe);probe.goto(base+'/idbfs_source_suite.html');probe.wait_for_function("typeof window.capture === 'function'")
  old.evaluate("window.writeGodotPair('old-primary-1','old-backup-1')")
  wait_pair(probe,paths,'old-primary-1','old-backup-1')
  first=cap(probe,paths);check(first['primary']['base64']=='b2xkLXByaW1hcnktMQ==','actual Godot FileAccess and IDBFS sync captured')
  # New engine disables persistence. Writes its MEMFS only; must not touch old DB.
  new=context.new_page();instrument(new);new.goto(base+'/engine/index.html?no-persist=1');new.wait_for_function('window.godotSourcePaths',timeout=120000)
  check(not new.evaluate('window.godotSourcePaths.persistent'),'new engine persistentPaths empty is not persistent')
  new.evaluate("window.writeGodotPair('new-memory-primary','new-memory-backup')")
  new.wait_for_timeout(2500)
  check(cap(probe,paths)==first,'new engine memory writes do not overwrite legacy IDBFS')
  old.evaluate("window.writeGodotPair('old-primary-2','old-backup-2')")
  wait_pair(probe,paths,'old-primary-2','old-backup-2')
  check(first['primary']['base64']=='b2xkLXByaW1hcnktMQ==','frozen first snapshot unchanged by old page later sync')
  second=cap(probe,paths);check(second!=first,'legacy page can still independently write after read-only capture')
  result['first']=first;result['second']=second
  context.close()
  # No persistence engine alone in a fresh origin/profile cannot create /userfs.
  clean=browser.new_context();isolated=clean.new_page();instrument(isolated);isolated.goto(base+'/engine/index.html?no-persist=1');isolated.wait_for_function('window.godotSourcePaths',timeout=120000)
  isolated.evaluate("window.writeGodotPair('memory-only','memory-only')");isolated.wait_for_timeout(1500)
  check(not isolated.evaluate('(async()=> (await indexedDB.databases()).some(x=>x.name==="/userfs"))()'),'new engine on fresh profile creates no legacy database')
  clean.close()
  schema=browser.new_context();page=schema.new_page();instrument(page);page.goto(base+'/idbfs_source_suite.html');page.wait_for_function("typeof window.runSchemaTests === 'function'");result['schema']=page.evaluate('window.runSchemaTests()');schema.close()
  result['browser']=browser.version;browser.close()
 check(not result['errors'],'browser console and page errors zero')
 result['status']='PASS'
finally:
 Path(args.out).write_text(json.dumps(result,ensure_ascii=False,indent=2));server.shutdown()
print(result['status'],len(result['checks']),result.get('schema',{}).get('checks'))
