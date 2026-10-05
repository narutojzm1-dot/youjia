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
   const unhandled=[];const onUnhandled=e=>unhandled.push(String(e.reason));window.addEventListener('unhandledrejection',onUnhandled);
   const broken=new HostLifecycle(Promise.reject(Error('engine startup failed before open')));
   await new Promise(r=>setTimeout(r,50));const blockedBeforeOpen=broken.state==='blocked';
   let failed=false;try{await broken.open('failed-runtime');}catch(e){failed=String(e).includes('engine startup failed before open');}
   await new Promise(r=>setTimeout(r,50));window.removeEventListener('unhandledrejection',onUnhandled);
   return {waiting,rejected,closed:gate.state==='closed',failed,blockedBeforeOpen,noUnhandled:unhandled.length===0};}''')
  ok(all(gates.values()),'runtime failure before open is observed, blocked and propagated without unhandled rejection')
  other.close()
  for fault in ['candidate_and_observed','write_id','schema','termination_type']:
   bad=c.new_page();bad.on('pageerror',lambda e:errors.append(str(e)));bad.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
   bad.add_init_script('''(() => {
    let host;window.ackCalls=0;
    Object.defineProperty(window,'YoujiaRecoveryHostBridge',{configurable:true,get:()=>host,set:value=>{
     const submit=value.submit,ack=value.acknowledge;
     value.acknowledge=(...args)=>{window.ackCalls++;return ack(...args);};
     value.submit=(...args)=>{const cb=args.pop();return submit(...args,raw=>{
      const receipt=JSON.parse(raw);window.actualReceipt=receipt;
      const changed={...receipt};const fault=FAULT;
      if(fault==='candidate_and_observed')changed.candidate_token=changed.observed_token='f'.repeat(32);
      if(fault==='write_id')changed.write_id='2';
      if(fault==='schema')changed.schema='forged/v1';
      if(fault==='termination_type')changed.old_write_terminated='true';
      cb(JSON.stringify(changed));
     });};host=value;
    }});
   })();'''.replace('FAULT',json.dumps(fault)))
   bad.goto(base+'?store=youjia-recovery-test-candidate-v1-'+uuid.uuid4().hex)
   bad.wait_for_function('window.lifecycleResult!==undefined',timeout=60000)
   ok(bad.evaluate("window.lifecycleResult.error==='unverified receipt' && window.ackCalls===0"),fault+' rejected without acknowledgement')
   actual=bad.evaluate('async()=>({receipt:window.actualReceipt,snapshot:await window.YoujiaRecoveryProbe.snapshot()})')
   ok(actual['snapshot']['intent']['state']=='committed' and actual['snapshot']['current']['commit_id']==actual['receipt']['candidate_token'],fault+' real durable evidence retained')
   bad.close()
  ok(not errors,'no console or page errors')
  Path(a.out).write_text(json.dumps({'status':'PASS','checks':checks,'browser':b.version,'errors':errors,'scope':'actual Godot Web userfs reload -> capture -> real R1 IndexedDB -> durable receipt; no production SaveStore switch'},indent=2))
  print('PASS',len(checks));b.close()
finally:s.shutdown()
