import argparse,functools,http.server,threading,json,uuid
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--web',required=True);p.add_argument('--out',required=True);a=p.parse_args()
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
s=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=a.web));threading.Thread(target=s.serve_forever,daemon=True).start()
errors=[];checks=[]
def ok(value,label):
 assert value,label
 checks.append(label)
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  c=b.new_context();page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  base=f'http://127.0.0.1:{s.server_port}/index.html';store='youjia-recovery-test-candidate-v1-'+uuid.uuid4().hex
  page.goto(base+'?seed=1');page.wait_for_function('window.seedWritten===true')
  page.wait_for_function('''async()=>{for(const info of await indexedDB.databases()){
   const db=await new Promise((r,j)=>{const q=indexedDB.open(info.name);q.onsuccess=()=>r(q.result);q.onerror=j;});
   if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue;}
   const rows=await new Promise((r,j)=>{const tx=db.transaction('FILE_DATA');const q=tx.objectStore('FILE_DATA').getAll();q.onsuccess=()=>r(q.result);q.onerror=j;});db.close();
   if(rows.some(v=>v.contents&&new TextDecoder().decode(v.contents).includes('9007199254740993')))return true;
  }return false;}''',timeout=60000)
  ok(True,'seed file actually present in IndexedDB before reload')
  page.goto(base+'?store='+store);page.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
  result=page.evaluate('window.lifecycleResult');ok(result.get('done'),'Godot capture import and durable write completes')
  ok(page.evaluate('window.captureAfterRuntime===true'),'capture after engine.startGame completed')
  ok(page.evaluate('window.rawPreserved===true'),'raw legacy numeric lexeme preserved')
  ok(result['receipt']['status']=='cleared','verified receipt consumed before acknowledge')
  other=c.new_page();other.on('pageerror',lambda e:errors.append(str(e)));other.on('console',lambda m:errors.append(m.text) if m.type=='error' else None);other.goto(base+'?store='+store);other.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
  ok('writer_owned_by_another_page' in other.evaluate('window.lifecycleResult').get('error',''),'second page denied before source import/write')
  page.close();other.reload();other.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
  ok(other.evaluate('window.lifecycleResult').get('reloaded'),'page close releases writer; new page recovers durable payload')
  gates=other.evaluate('''async()=>{const {HostLifecycle}=await import('./lifecycle.mjs');
   let resolve;const gate=new HostLifecycle(new Promise(r=>resolve=r));const op=gate.open('close-before-ready').catch(e=>String(e));
   const waiting=gate.state==='waiting_runtime';await gate.close();resolve();const rejected=(await op).includes('closed before runtime ready');
   const broken=new HostLifecycle(Promise.reject(Error('engine startup failed')));let failed=false;try{await broken.open('failed-runtime');}catch(_){failed=broken.state==='blocked';}
   return {waiting,rejected,closed:gate.state==='closed',failed};}''')
  ok(all(gates.values()),'pending runtime close and engine failure remain nonwritable')
  ok(not errors,'no console or page errors')
  Path(a.out).write_text(json.dumps({'status':'PASS','checks':checks,'browser':b.version,'errors':errors,'scope':'actual Godot Web userfs reload -> capture -> real R1 IndexedDB -> durable receipt; no production SaveStore switch'},indent=2))
  print('PASS',len(checks));b.close()
finally:s.shutdown()
