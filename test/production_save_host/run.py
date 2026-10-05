import argparse,functools,http.server,threading,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--web',required=True);p.add_argument('--out',required=True);a=p.parse_args()
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
s=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=a.web));threading.Thread(target=s.serve_forever,daemon=True).start()
checks=[];errors=[]
def ok(value,label):
 assert value,label
 checks.append(label)
def watch(page):
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']);c=b.new_context();page=c.new_page();watch(page)
  base=f'http://127.0.0.1:{s.server_port}/index.html'
  page.goto(base+'?seed=1');page.wait_for_function('window.seedWritten===true')
  page.wait_for_function('''async()=>{for(const info of await indexedDB.databases()){
   const db=await new Promise((r,j)=>{const q=indexedDB.open(info.name);q.onsuccess=()=>r(q.result);q.onerror=j;});
   if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue;}
   const rows=await new Promise((r,j)=>{const q=db.transaction('FILE_DATA').objectStore('FILE_DATA').getAll();q.onsuccess=()=>r(q.result);q.onerror=j;});db.close();
   if(rows.some(v=>v.contents&&new TextDecoder().decode(v.contents).includes('9007199254740993')))return true;
  }return false;}''',timeout=60000)
  ok(True,'actual Godot legacy file reaches IDBFS')
  page.goto(base);page.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
  result=page.evaluate('window.lifecycleResult');ok(result.get('done'),str(result))
  ok(page.evaluate('window.userfsPersistent===false'),'new Godot runtime has no persistent IDBFS mount')
  ok(page.evaluate('window.captureAfterRuntime===true && window.rawPreserved===true'),'engine ready then readonly legacy import preserves raw')
  ok(page.evaluate("Object.keys(window.YoujiaSaveHost).sort().join(',')==='acknowledge,close,initialize,open,prepare,resolve,submit' && window.YoujiaRecoveryProbe===undefined"),'production bridge has no test controls')
  records=page.evaluate('''async()=>{const db=await new Promise((r,j)=>{const q=indexedDB.open('youjia-save-host-v1');q.onsuccess=()=>r(q.result);q.onerror=j;});const result=await new Promise((r,j)=>{const q=db.transaction('records').objectStore('records').getAll();q.onsuccess=()=>r(q.result);q.onerror=j;});db.close();return result;}''')
  ok(any(v.get('schema')=='youjia.legacy-sources/v1' and '9007199254740993' in v['import_payload'] for v in records),'permanent raw survives production write and acknowledgement')
  other=c.new_page();watch(other);other.goto(base);other.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
  refused=other.evaluate('window.lifecycleResult');ok(refused.get('code')=='OPEN_FAILED' and 'writer_owned_by_another_page' in refused.get('cause',''),'second page production writer refused')
  page.close();other.reload();other.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
  ok(other.evaluate('window.lifecycleResult.reloaded===true'),'new page recovers committed production payload')
  ok(not errors,'no browser console or page errors')
  Path(a.out).write_text(json.dumps({'status':'PASS','checks':checks,'errors':errors,'browser':b.version,'scope':'real Godot Web legacy IDBFS seed; new runtime persistentPaths empty; real production Host import/write/ack and page ownership'},indent=2)+'\n');print('PASS',len(checks));b.close()
finally:s.shutdown()
