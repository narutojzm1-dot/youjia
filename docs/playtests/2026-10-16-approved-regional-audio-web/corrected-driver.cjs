const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const dir='C:/Users/Zengm/AppData/Local/Temp/youjia-regional-535-validation';
const result={source:'2ca748c8e11c98340a4709cf1059d8fd2c2330d8',controlled_start:true,records:[],errors:[],console:[],input:[]};
let context,page,start;
const save=()=>fs.writeFile(path.join(dir,'web-long-checks-r2.json'),JSON.stringify(result,null,2));
async function record(label){
 const r=await page.evaluate(()=>{const p=window.__ui704Probe;return {t:performance.now(),visibility:document.visibilityState,diagnostics:window.__manusBgm?JSON.parse(window.__manusBgm.diagnostics()):null,sources:p?.sources||[],recent:p?.samples?.filter(s=>s.t>(p.samples.at(-1)?.t||0)-1000)||[]};});
 const row={label,elapsed:(Date.now()-start)/1000,visibility:r.visibility,diagnostics:r.diagnostics,sources:r.sources,peak:Math.max(0,...r.recent.map(s=>s.peak)),samples:r.recent.length};result.records.push(row);await save();return row;
}
async function shot(name){await page.screenshot({path:path.join(dir,'web-r2-'+name+'.jpg'),type:'jpeg',quality:72});}
async function waitUntil(seconds){while((Date.now()-start)/1000<seconds){await page.waitForTimeout(2000);await record('continuous');}}
async function boot(){await page.goto('http://127.0.0.1:8175/');await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,{timeout:90000});await page.mouse.click(640,370);await page.waitForTimeout(2000);}
(async()=>{
 const bytes=await fs.readFile('C:/Users/Zengm/.codex/worktrees/ui-audio-704/youjia/dist/index.pck');result.pack={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
 context=await chromium.launchPersistentContext(path.join(dir,'web-profile-r2'),{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720}});
 page=context.pages()[0]||await context.newPage();result.browser=context.browser()?.version();page.on('pageerror',e=>result.errors.push(String(e)));page.on('console',m=>{if(['error','warning'].includes(m.type()))result.console.push({type:m.type(),text:m.text()});});
 const probe=await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-probe.js','utf8');await page.addInitScript(probe.split("  addEventListener('DOMContentLoaded'")[0]+'})();');
 const baseline=JSON.parse(await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-public/baseline-save.json','utf8'));
 const data=JSON.parse(baseline.payload_bytes);data.holiday_day=2;data.holiday_day_elapsed=320;data.tutorial_version=1;data.yard_gate_open=true;data.yard_inventory.held='';data.yard_inventory.corn=2;data.world_weather={episode:0,remaining:80,seed:451862825,weather:'rain'};data.resident_rest={cause:'sleep',day:2,schema:1};
 await page.goto('http://127.0.0.1:8175/web/save/store.mjs');
 result.fixture=await page.evaluate(async d=>{const {openStore}=await import('/web/save/store.mjs');const s=await openStore();const before=await s.recover();if(before.verdict!=='empty')throw Error('expected fresh isolated profile');await s.initialize(JSON.stringify(d));const after=await s.recover();s.close();return {verdict:after.verdict,generation:after.current.generation,payload_sha256:after.current.payload_sha256};},data);await save();
 await boot();start=Date.now();await shot('yard-start');await record('day rain yard');
 await page.keyboard.down('ArrowDown');await page.waitForTimeout(2200);await page.keyboard.up('ArrowDown');await page.keyboard.press('Space');result.input.push('normal Down 2.2s then Space to leave yard');await page.waitForTimeout(6500);await shot('nearby-attempt');
 const near=await record('nearby entry attempt');result.nearbyDistinctSource=near.sources.some(s=>Math.abs(s.frames-3686400)<=2);
 // Continue even if navigation was not reached: screenshots and a false flag
 // preserve that coverage gap without inventing a route or driving Main.
 await waitUntil(115);await shot('night');
 if(result.nearbyDistinctSource){await page.mouse.click(1190,43);await page.waitForTimeout(6500);result.input.push('normal top-right return');}
 await shot('returned-or-yard');await record('night return');
 await page.keyboard.down('ArrowUp');await page.waitForTimeout(1900);await page.keyboard.up('ArrowUp');await page.keyboard.press('Space');result.input.push('normal Up then Space to approach house');await page.waitForTimeout(10000);await shot('sleep-attempt');await record('sleep attempt');
 await waitUntil(250);
 await page.keyboard.press('Escape');await page.waitForTimeout(300);await page.mouse.click(640,605);await page.waitForTimeout(2000);const muted=await record('master muted');result.masterMutedZero=muted.peak===0;await shot('muted');
 await page.mouse.click(640,605);await page.keyboard.press('Escape');await page.waitForTimeout(2500);await record('unmuted');
 await waitUntil(400);
 const other=await context.newPage();await other.goto('about:blank');await other.bringToFront();await page.waitForTimeout(2000);const hidden=await record('other tab foreground');result.actualHidden=hidden.visibility==='hidden';await page.bringToFront();await other.close();await page.mouse.click(800,600);await page.waitForTimeout(2000);await record('trusted return input');
 await waitUntil(620);await shot('long-final');const final=await record('long complete');
 await fs.writeFile(path.join(dir,'web-long-output-probe-r2.json'),JSON.stringify(await page.evaluate(()=>window.__ui704Probe)));
 result.softwareNonzero=result.records.some(r=>r.peak>0.00001);result.maxBuffers=Math.max(0,...result.records.map(r=>r.diagnostics?.buffers||0));result.maxCacheBytes=Math.max(0,...result.records.map(r=>r.diagnostics?.bytes||0));
 result.allSourcesLoop=final.sources.filter(s=>s.frames>200000).every(s=>s.loop);result.sleepSourceObserved=final.sources.some(s=>Math.abs(s.frames-230400)<=2);result.longSeconds=final.elapsed;
 assert(result.softwareNonzero,'actual output observed');assert(result.masterMutedZero,'actual mute zero');assert.equal(result.errors.length,0,'no page errors');
 result.finished=new Date().toISOString();result.driverExit=0;await save();console.log(JSON.stringify({longSeconds:result.longSeconds,nonzero:result.softwareNonzero,nearby:result.nearbyDistinctSource,sleep:result.sleepSourceObserved,maxBuffers:result.maxBuffers,maxBytes:result.maxCacheBytes,actualHidden:result.actualHidden,pageErrors:result.errors}));
})().catch(async e=>{result.failure=String(e.stack||e);result.driverExit=1;await save();console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();});
