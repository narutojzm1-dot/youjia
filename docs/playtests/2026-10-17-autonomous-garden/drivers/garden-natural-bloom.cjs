const {chromium}=require('C:/Users/jiangzengming/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright-core');
const fs=require('node:fs/promises'),rawfs=require('node:fs'),path=require('node:path'),http=require('node:http'),assert=require('node:assert/strict'),cp=require('node:child_process');
const dir=path.resolve(__dirname,process.argv[2]||'web-actual'),root=path.join(__dirname,'web-versioned'),source='1ab59c1113dd0a1c7d55ca9e34cf3f89ab152814';
const profile=path.join(dir,'owned-profile');let context,page,url,mod,streamFile,queue=Promise.resolve();
const result={source,controlled_legal_start_only:true,no_post_start_fixture_writes:true,no_direct_game_calls:true,no_http_substitution:true,errors:[],console:[],samples:[]};
const server=http.createServer((req,res)=>{let p=path.join(root,decodeURIComponent(new URL(req.url,'http://local').pathname));if(p===root+path.sep)p=path.join(root,'index.html');if(!p.startsWith(root+path.sep)){res.writeHead(403);return res.end();}try{const st=rawfs.statSync(p);res.setHeader('Content-Type',p.endsWith('.mjs')||p.endsWith('.js')?'text/javascript':p.endsWith('.wasm')?'application/wasm':p.endsWith('.html')?'text/html':p.endsWith('.json')?'application/json':p.endsWith('.png')?'image/png':'application/octet-stream');res.setHeader('Cache-Control','no-store');res.setHeader('Content-Length',st.size);rawfs.createReadStream(p).pipe(res);}catch{res.writeHead(404);res.end();}});
async function save(){await fs.writeFile(path.join(dir,'result.json'),JSON.stringify(result,null,2));}
async function launch(){context=await chromium.launchPersistentContext(profile,{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720},args:['--no-first-run','--no-default-browser-check']});page=context.pages()[0];page.on('pageerror',e=>result.errors.push(String(e)));page.on('console',m=>{if(['error','warning'].includes(m.type()))result.console.push(m.text());});}
async function read(){return page.evaluate(async m=>{const {openStore}=await import(m);const s=await openStore();try{return JSON.parse((await s.snapshot()).current.payload_bytes);}finally{s.close();}},mod);}
async function raw(){return page.evaluate(async()=>{const req=r=>new Promise((y,n)=>{r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)});const db=await req(indexedDB.open('youjia-save-host-v1'));const t=db.transaction('records','readonly'),done=new Promise((y,n)=>{t.oncomplete=y;t.onabort=()=>n(t.error)});const keys=await req(t.objectStore('records').getAllKeys()),rows=await req(t.objectStore('records').getAll());await done;const r={version:db.version,keys,rows};db.close();return r;});}
function pids(){const target=profile.replace(/\\/g,'/').replace(/'/g,"''");const s=cp.execFileSync('powershell.exe',['-NoProfile','-Command',`$t='${target}'; @(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'chrome.exe' -and ($_.CommandLine -replace '\\\\','/').Contains($t) } | Select-Object -ExpandProperty ProcessId) | ConvertTo-Json -Compress`],{encoding:'utf8',windowsHide:true}).trim();return s?[].concat(JSON.parse(s)):[];}
async function boot(start=true){const t=Date.now();await page.goto(url);await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:120000});assert.equal(await page.locator('html').getAttribute('data-build'),'game-'+source.slice(0,7));if(start){await page.mouse.click(640,370);await page.waitForTimeout(1000);}return Date.now()-t;}

(async()=>{
 await fs.mkdir(dir,{recursive:true});await new Promise(r=>server.listen(0,'127.0.0.1',r));url='http://127.0.0.1:'+server.address().port+'/';mod=new URL('save-'+source.slice(0,7)+'/store.mjs',url).href;
 await launch();await page.goto(new URL('game-release.json',url).href);
 const initial=JSON.parse(await fs.readFile(path.join(__dirname,'web-source-ui-r3/result.json'),'utf8')).final;
 result.actualSourceChainSnapshotImportedAsStart=true;result.noTimeAdvanceOrFutureDateFixture=true;result.initialFixture=initial;
 assert.equal(initial.holiday_day,1);assert.equal(initial.yard_garden.receipts[0].day,1);
 await page.evaluate(async({d,m})=>{const {openStore}=await import(m),s=await openStore();try{if((await s.recover()).verdict!=='empty')throw Error('fresh profile required');await s.initialize(JSON.stringify(d));}finally{s.close();}},{d:initial,m:mod});
 result.bootMs=await boot();
 const began=Date.now();let prior=0;
 while(Date.now()-began<1700000){
  await page.waitForTimeout(15000);
  const d=await read(),row={seconds:(Date.now()-began)/1000,day:d.holiday_day,elapsed:d.holiday_day_elapsed,garden:d.yard_garden};
  result.samples.push(row);assert.deepEqual(d.yard_garden,initial.yard_garden);
  if(d.holiday_day!==prior){prior=d.holiday_day;await page.screenshot({path:path.join(dir,'natural-day-'+prior+'.jpg'),type:'jpeg',quality:93});console.log(JSON.stringify(row));}
  await save();
  if(d.holiday_day>=4){result.final=d;result.naturalWallClockSeconds=row.seconds;await page.screenshot({path:path.join(dir,'natural-bloom-day4.jpg'),type:'jpeg',quality:94});break;}
 }
 assert.equal(result.final?.holiday_day,4);assert.equal(result.errors.length,0);assert(!result.console.some(x=>/SCRIPT ERROR|WebGL|INVALID_OPERATION/.test(x)));
 result.pass=true;await save();console.log('NATURAL_BLOOM_PASS '+result.naturalWallClockSeconds);
})().catch(async e=>{result.failure=String(e.stack||e);await save();console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();server.close();});
