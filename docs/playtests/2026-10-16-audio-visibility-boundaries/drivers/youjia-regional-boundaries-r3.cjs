const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),crypto=require('node:crypto');
const out='C:/Users/Zengm/AppData/Local/Temp/youjia-regional-boundaries-r3';
const run={started:new Date().toISOString(),source:'2ca748c8e11c98340a4709cf1059d8fd2c2330d8',main:'48e51e37561810e55ad457b3c36cd016442fe297',mainRuntime:'9946b35f89b970c094f1a7ff68aef78c08550064',cases:[]};
const save=()=>fs.writeFile(path.join(out,'results.json'),JSON.stringify(run,null,2));
let context;
async function snapshot(page,label){return page.evaluate(label=>({label,t:performance.now(),hidden:document.hidden,visibility:document.visibilityState,focus:document.hasFocus(),diagnostics:window.__manusBgm?JSON.parse(window.__manusBgm.diagnostics()):null,events:window.__r3Events||[],probe:window.__ui704Probe?{sources:window.__ui704Probe.sources.slice(-16),recent:window.__ui704Probe.samples.filter(s=>s.t>performance.now()-1200),contexts:window.__ui704Probe.contexts}:null}),label);}
async function execute(label,url,observer,headful=false){
 const c={label,url,observer,headful,console:[],errors:[],snapshots:[],started:new Date().toISOString()};run.cases.push(c);await save();
 context=await chromium.launchPersistentContext(path.join(out,'profile-'+label),{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:!headful,viewport:{width:1280,height:720},args:headful?['--window-position=50,50']:[]});
 const page=context.pages()[0];c.browser=context.browser()?.version();
 page.on('console',m=>{if(['error','warning'].includes(m.type()))c.console.push({type:m.type(),text:m.text(),location:m.location()});});page.on('pageerror',e=>c.errors.push(String(e)));
 await page.addInitScript(()=>{window.__r3Events=[];for(const name of ['visibilitychange','focus','blur','pageshow','pagehide'])addEventListener(name,e=>window.__r3Events.push({name,t:performance.now(),hidden:document.hidden,visible:document.visibilityState,focus:document.hasFocus(),trusted:e.isTrusted}),true);});
 if(observer){const probe=await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-probe.js','utf8');await page.addInitScript(probe.split("  addEventListener('DOMContentLoaded'")[0]+'})();');}
 // Same legal, pre-load test fixture in each independent profile. No runtime clock/state commands.
 const baseline=JSON.parse(await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-public/baseline-save.json','utf8'));
 const data=JSON.parse(baseline.payload_bytes);data.holiday_day=2;data.holiday_day_elapsed=200;data.tutorial_version=1;data.yard_gate_open=true;data.yard_inventory.held='';data.yard_inventory.corn=2;data.resident_rest={cause:'sleep',day:2,schema:1};data.world_weather={episode:0,remaining:80,seed:451862825,weather:'rain'};
 let modulePath='web/save/store.mjs';
 if(!url.includes('127.0.0.1')){const manifest=await (await context.request.get(new URL('game-release.json',url).href)).json();c.publicManifest=manifest;modulePath=manifest.storageModules.entry+'/store.mjs';}
 await page.goto(new URL(modulePath,url).href);
 c.fixture=await page.evaluate(async d=>{const {openStore}=await import('./store.mjs');const s=await openStore();const before=await s.recover();if(before.verdict!=='empty')throw Error('profile not fresh');await s.initialize(JSON.stringify(d));const after=await s.recover();s.close();return {verdict:after.verdict,generation:after.current.generation,hash:after.current.payload_sha256};},data);
 await page.goto(url);await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:180000});
 c.snapshots.push(await snapshot(page,'before user entry'));await page.mouse.click(640,370);await page.waitForTimeout(6000);c.snapshots.push(await snapshot(page,'yard started'));
 await page.keyboard.down('ArrowDown');await page.waitForTimeout(2200);await page.keyboard.up('ArrowDown');await page.keyboard.press('Space');await page.waitForTimeout(6500);c.snapshots.push(await snapshot(page,'nearby attempt'));
 if(headful){
   const other=await context.newPage();await other.goto('about:blank');await other.bringToFront();await page.waitForTimeout(3500);c.snapshots.push(await snapshot(page,'other real tab foreground'));
   await page.bringToFront();await page.waitForTimeout(3500);c.snapshots.push(await snapshot(page,'return without extra input'));
   await page.mouse.click(800,600);await page.waitForTimeout(2000);c.snapshots.push(await snapshot(page,'trusted return input'));
   const client=await context.newCDPSession(page);const win=await client.send('Browser.getWindowForTarget');c.windowId=win.windowId;
   await client.send('Browser.setWindowBounds',{windowId:win.windowId,bounds:{windowState:'minimized'}});await page.waitForTimeout(3500);c.snapshots.push(await snapshot(page,'own Chrome window minimized'));
   await client.send('Browser.setWindowBounds',{windowId:win.windowId,bounds:{windowState:'normal'}});await page.bringToFront();await page.waitForTimeout(3500);c.snapshots.push(await snapshot(page,'own Chrome restored'));
   await page.mouse.click(800,600);await page.waitForTimeout(2000);c.snapshots.push(await snapshot(page,'restored trusted input'));
   // Controlled suspended-context case is explicitly separate from real tab/window hiding.
   if(observer){c.controlledSuspend=await page.evaluate(async()=>{let state=[];const old=AudioContext.prototype.suspend;/* installed contexts are obtained by connect hook below, never game controls */for(const x of window.__r3AudioContexts||[]) {await old.call(x);state.push(x.state);}return state;});}
   await other.close();await client.detach();
 }
 await page.waitForTimeout(30000);c.snapshots.push(await snapshot(page,'stable final'));
 await page.screenshot({path:path.join(out,label+'.jpg'),type:'jpeg',quality:70});
 c.warnCounts={};for(const m of c.console)c.warnCounts[m.text]=(c.warnCounts[m.text]||0)+1;
 c.finished=new Date().toISOString();c.complete=true;await save();console.log(JSON.stringify({label,errors:c.errors,warnings:c.console.length,hidden:c.snapshots.filter(s=>s.hidden).map(s=>s.label)}));
 await context.close();context=null;
}
(async()=>{await fs.mkdir(out,{recursive:true});const pack=await fs.readFile('C:/Users/Zengm/.codex/worktrees/ui-audio-704/youjia/dist/index.pck');run.pack={bytes:pack.length,sha256:crypto.createHash('sha256').update(pack).digest('hex')};
 await execute('main-no-observer','https://narutojzm1-dot.github.io/youjia/',false);
 await execute('candidate-no-observer','http://127.0.0.1:8175/',false);
 await execute('main-observer','https://narutojzm1-dot.github.io/youjia/',true);
 await execute('candidate-observer','http://127.0.0.1:8175/',true);
 await execute('candidate-headed','http://127.0.0.1:8175/',true,true);
 run.finished=new Date().toISOString();run.driverExit=0;await save();
})().catch(async e=>{run.failure=String(e.stack||e);run.driverExit=1;await save();console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();});
