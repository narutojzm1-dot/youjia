// Real IndexedDB/Web Locks regression for #827. No IndexedDB mock or production
// test hooks. Every run uses a new loopback origin and an owned temporary profile.
const fs = require('node:fs'), path = require('node:path'), os = require('node:os');
const http = require('node:http'), crypto = require('node:crypto'), assert = require('node:assert/strict');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright-core');
const root = path.resolve(__dirname, '../..');
const out = process.argv[2] || fs.mkdtempSync(path.join(os.tmpdir(), 'youjia-photo-writer-'));
fs.mkdirSync(out, {recursive:true});
const old = path.join(__dirname, 'old-70de87a');
const oldHash = crypto.createHash('sha256').update(fs.readFileSync(path.join(old,'store.mjs'))).digest('hex');
assert.equal(oldHash, '2193b4397b8662a8ebc754dc4468e4d62964d209b4e1d0f0924a2ec81b409cbe');
const current = process.env.CURRENT_STORE_DIR || path.join(root,'web/save');
const files = new Map([['/', [Buffer.from('<!doctype html><title>Owned photo writer regression</title>'), 'text/html']]]);
for (const [prefix, dir] of [['current',current],['old',old]]) {
  for (const name of ['store.mjs','legacy_seal.mjs','budgets.mjs'])
    files.set(`/${prefix}/${name}`, [fs.readFileSync(path.join(dir,name)), 'text/javascript']);
}
for (const name of ['new-photo.json','old-clean-result.json'])
  files.set('/'+name, [fs.readFileSync(path.join(__dirname,name)), 'application/json']);
const server = http.createServer((req,res) => {
  const item=files.get(new URL(req.url,'http://127.0.0.1').pathname);
  res.writeHead(item?200:404, {'Content-Type':item?.[1] || 'text/plain','Cache-Control':'no-store'});
  res.end(item?.[0] || 'not found');
});
let context;
(async()=>{
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  const base=`http://127.0.0.1:${server.address().port}`;
  const profile=path.join(out,'owned-chrome-profile');
  const launch=()=>chromium.launchPersistentContext(profile,{headless:true,
    ...(process.env.CHROME_PATH ? {executablePath:process.env.CHROME_PATH} : {} )});
  context=await launch();
  const page=await context.newPage(); await page.goto(base);
  const result=await page.evaluate(async()=>{
    const newer=await import('/current/store.mjs'), older=await import('/old/store.mjs');
    const photo=await (await fetch('/new-photo.json')).json();
    const oldClean=await (await fetch('/old-clean-result.json')).json();
    const checks=[],failures=[],cases=[];
    const check=(v,label)=>{(v?checks:failures).push(label);};
    const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
    const namespace=newer.NAMESPACE;
    const request=r=>new Promise((yes,no)=>{r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error);});
    const rawOpen=(name,version,upgrade)=>new Promise((yes,no)=>{
      const r=indexedDB.open(name,version);
      r.onupgradeneeded=e=>upgrade?.(r.result,r.transaction,e);
      r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error);
    });
    const rawRead=async(name=namespace)=>{
      const db=await request(indexedDB.open(name));
      const tx=db.transaction([...db.objectStoreNames],'readonly');
      // Request success precedes transaction completion. Wait for the latter so
      // this diagnostic connection is not itself a close-pending v1 blocker.
      const completed=new Promise((yes,no)=>{tx.oncomplete=yes;tx.onabort=()=>no(tx.error);});
      const rows={};
      await Promise.all([...db.objectStoreNames].map(async n=>{
        const s=tx.objectStore(n);const [keys,values]=await Promise.all([request(s.getAllKeys()),request(s.getAll())]);
        rows[n]=keys.map((k,i)=>[k,values[i]]);
      }));
      await completed;
      const answer={version:db.version,rows};db.close();return answer;
    };
    const rawPut=async(db,values)=>new Promise((yes,no)=>{
      const tx=db.transaction('records','readwrite'),s=tx.objectStore('records');
      for(const [k,v] of Object.entries(values))s.put(v,k);
      tx.oncomplete=yes;tx.onabort=()=>no(tx.error);
    });
    const reset=async()=>request(indexedDB.deleteDatabase(namespace));
    const count=s=>Object.keys(JSON.parse(s.current.payload_bytes).photo_moments||{}).length;
    const payload=JSON.stringify({version:5,photo_album:['fish_first_catch'],photo_moments:{fish_first_catch:photo},
      untouched:'raw Unicode 灶台',integer_text:'9007199254740993',growth_production:{schema:2,revision:0}});
    check(oldClean.before_records===1 && oldClean.after_old_album_clean===0 && !oldClean.old_asset_available,
      'actual old-PCK forensic fixture records resource rejection');
    async function scenario(name,run){
      try{await reset();await run();cases.push({name,status:'completed'});}
      catch(e){failures.push(name+': '+String(e));cases.push({name,status:'failed',error:String(e)});}
    }
    await scenario('known old writer loses new photo without fence',async()=>{
      const s=await older.openStore(),parent=await s.initialize(payload);
      const bad=JSON.parse(payload);bad.photo_moments=oldClean.cleaned;
      await s.submit(await older.envelope(JSON.stringify(bad),parent));
      check(count(await s.snapshot())===0,'actual frozen old submit accepts the photo-cleaned payload');s.close();
    });
    await scenario('upgrade fences live and reopened old writers',async()=>{
      const oldStore=await older.openStore(),parent=await oldStore.initialize(payload);
      const before=await rawRead();const s=await newer.openStore();const after=await rawRead();
      check(after.version===2 && equal(before.rows,after.rows),'v1 to v2 preserves every raw record exactly');
      const bad=JSON.parse(payload);bad.photo_moments=oldClean.cleaned;
      let rejected=false;try{await oldStore.submit(await older.envelope(JSON.stringify(bad),parent));}catch(e){rejected=e.name==='InvalidStateError';}
      check(rejected,'live old connection is closed and cannot overwrite photos');oldStore.close();
      let reopened;try{reopened=await older.openStore();}catch(e){check(e.name==='VersionError','old reopen refuses higher writer epoch');}
      if(reopened){reopened.close();check(false,'old reopen must be refused');}
      check(count(await s.snapshot())===1 && equal((await s.snapshot()).current,parent),'failed old writes leave exact photo envelope intact');
      const next=await newer.envelope(payload,parent);await s.submit(next);await s.acknowledge(next.request_id);
      check(count(await s.snapshot())===1,'new writer still saves and acknowledges same photo');s.close();
      const again=await newer.openStore();check(count(await again.recover())===1,'new writer close/reopen retains photo');again.close();
    });
    for(const state of ['prepared','committed'])await scenario(state+' intent survives upgrade before recovery',async()=>{
      const s=await older.openStore(),parent=await s.initialize(payload);s.close();
      const candidate=await older.envelope(payload,parent),intent={state,request_id:candidate.request_id,parent,candidate};
      const db=await request(indexedDB.open(namespace));
      await rawPut(db,{current:state==='committed'?candidate:parent,intent,archive:[]});db.close();
      const before=await rawRead(),n=await newer.openStore(),after=await rawRead();
      check(equal(before.rows,after.rows),state+' records unchanged by upgrade');
      const recovered=await n.recover();
      check(recovered.verdict===(state==='prepared'?'restored_parent_intent_rejected':'restored_candidate') && count(recovered)===1,
        state+' uses existing recovery and retains photo');
      check(!recovered.present.intent && (state==='committed'||recovered.archive.length===1),state+' recovery resolves correct intent');n.close();
    });
    await scenario('legacy seal and source namespace remain exact',async()=>{
      const legacyName='/userfs';
      const source=await rawOpen(legacyName,21,db=>db.createObjectStore('FILE_DATA'));
      const tx=source.transaction('FILE_DATA','readwrite');tx.objectStore('FILE_DATA').put({contents:new Uint8Array([0,1,2,255])},'/sentinel');
      await new Promise((r,j)=>{tx.oncomplete=r;tx.onabort=j;});source.close();const legacyBefore=await rawRead(legacyName);
      const imported=JSON.stringify({schema:'youjia.legacy-v5-import/v1',selected:'primary',sources:{primary:{status:'present',text:payload},backup:{status:'absent'}}});
      const s=await older.openStore();await s.initialize(imported,{preserveLegacy:true});s.close();
      const before=await rawRead(),n=await newer.openStore();
      check(equal(before.rows,(await rawRead()).rows),'sealed import and legacy_sources remain byte exact');
      check((await n.recover()).verdict==='clean','existing legacy seal remains valid');n.close();
      check(equal(legacyBefore,await rawRead(legacyName)),'legacy source DB never upgraded or written');
    });
    await scenario('blocked upgrade is abandoned instead of applied late',async()=>{
      const s=await older.openStore();await s.initialize(payload);s.close();
      const blocker=await request(indexedDB.open(namespace,1));blocker.onversionchange=()=>{};
      const before=await rawRead();let error;
      try{const n=await newer.openStore();n.close();}catch(e){error=String(e);}
      check(error?.includes('database blocked'),'blocked upgrade reports failure');
      blocker.close();
      // A following open is queued behind the abandoned upgrade, so this verifies
      // its actual terminal state without guessing with a delay.
      const after=await rawRead();check(equal(before,after),'late blocked request aborts: version and records remain v1');
      const n=await newer.openStore();check(count(await n.recover())===1,'explicit retry can upgrade safely');n.close();
    });
    await scenario('malformed existing DB is not recreated',async()=>{
      const db=await rawOpen(namespace,1,d=>d.createObjectStore('other'));
      const tx=db.transaction('other','readwrite');tx.objectStore('other').put('keep','sentinel');
      await new Promise((r,j)=>{tx.oncomplete=r;tx.onabort=j;});db.close();const before=await rawRead();
      let error;try{const n=await newer.openStore();n.close();}catch(e){error=e.name;}
      check(error==='AbortError' && equal(before,await rawRead()),'missing records aborts upgrade without replacement or version change');
    });
    await scenario('future DB remains untouched',async()=>{
      const db=await rawOpen(namespace,3,d=>d.createObjectStore('records'));await rawPut(db,{current:{future:'retain'}});db.close();
      const before=await rawRead();let error;try{const n=await newer.openStore();n.close();}catch(e){error=e.name;}
      check(error==='VersionError' && equal(before,await rawRead()),'v3 refuses v2 client without changing data');
    });
    // Leave a valid upgraded save for a real browser process restart below.
    await reset();const final=await older.openStore();await final.initialize(payload);final.close();
    const n=await newer.openStore();window.restartEnvelope=(await n.snapshot()).current;n.close();
    return {checks,failures,cases,restartEnvelope:window.restartEnvelope,oldHash:'2193b4397b8662a8ebc754dc4468e4d62964d209b4e1d0f0924a2ec81b409cbe'};
  });
  await context.close();context=await launch();const reopened=await context.newPage();await reopened.goto(base);
  const after=await reopened.evaluate(async()=>{const m=await import('/current/store.mjs'),s=await m.openStore();const r=await s.recover();s.close();return {verdict:r.verdict,current:r.current};});
  if(after.verdict==='clean' && JSON.stringify(after.current)===JSON.stringify(result.restartEnvelope))result.checks.push('actual Chrome process restart retains exact envelope and photo');
  else result.failures.push('actual Chrome process restart changed saved photo');
  delete result.restartEnvelope;result.browser=context.browser()?.version();result.currentStoreSha256=crypto.createHash('sha256').update(files.get('/current/store.mjs')[0]).digest('hex');
  result.status=result.failures.length?'FAIL':'PASS';
  fs.writeFileSync(path.join(out,'result.json'),JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result,null,2));process.exitCode=result.failures.length?1:0;
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();server.close();});
