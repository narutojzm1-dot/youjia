// Matched, sequential normal-input controls. No game/engine method calls.
// A fresh isolated profile receives the same legal save before game load only.
const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const {spawn}=require('node:child_process');
const [label,port,pack,source,storePath,observerFlag]=process.argv.slice(2);
assert(label&&port&&pack&&source&&storePath);
const base='C:/Users/Zengm/AppData/Local/Temp/youjia-webgl-matched-20261016';
const dir=path.join(base,label),url='http://127.0.0.1:'+port+'/',observer=observerFlag==='observer';
const result={label,source,observer,normal_input_only:true,fresh_controlled_start:true,started:new Date().toISOString(),records:[],console:[],errors:[],input:[],screenshots:[]};
let browser,context,page,child,start;
const save=()=>fs.writeFile(path.join(dir,'result.json'),JSON.stringify(result,null,2));
function elapsed(){return start?(Date.now()-start)/1000:null;}
async function record(label){
 const r=await page.evaluate(()=>{const p=window.__ui704Probe;const f=window.__matchedFrames;return {visibility:document.visibilityState,frames:f?.n,lastFrame:f?.last,diagnostics:window.__manusBgm?JSON.parse(window.__manusBgm.diagnostics()):null,sourceCount:p?.sources?.length,loopSources:p?.sources?.filter(s=>s.frames>200000).map(s=>({frames:s.frames,loop:s.loop}))};});
 result.records.push({label,elapsed:elapsed(),...r});await save();return r;
}
async function shot(name){
 const row={name,before:elapsed()};result.screenshots.push(row);await save();
 await page.screenshot({path:path.join(dir,name+'.jpg'),type:'jpeg',quality:72});row.after=elapsed();await save();
}
async function until(seconds){while(elapsed()<seconds){await page.waitForTimeout(Math.min(5000,(seconds-elapsed())*1000));await record('continuous');}}
async function input(name,fn){result.input.push({name,elapsed:elapsed()});await save();await fn();}
(async()=>{
 await fs.mkdir(dir,{recursive:true});const profile=path.join(dir,'profile');await fs.mkdir(profile); // Never reuse a fixture/profile.
 const bytes=await fs.readFile(pack);result.pack={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')};await save();
 child=spawn('C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless=new','--remote-debugging-port=0','--remote-debugging-address=127.0.0.1','--user-data-dir='+profile,'--no-first-run','--no-default-browser-check','--window-size=1280,720','about:blank'],{windowsHide:true,stdio:'ignore'});result.chromePid=child.pid;
 let cdpPort;for(let i=0;i<100;i++){try{cdpPort=(await fs.readFile(path.join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];break;}catch{await new Promise(r=>setTimeout(r,200));}}assert(cdpPort,'fresh own Chrome port');
 browser=await chromium.connectOverCDP('http://127.0.0.1:'+cdpPort,{noDefaults:true,isLocal:true});context=browser.contexts()[0];page=context.pages()[0]||await context.newPage();await page.setViewportSize({width:1280,height:720});result.browser=browser.version();
 page.on('pageerror',e=>result.errors.push({elapsed:elapsed(),text:String(e)}));
 page.on('console',m=>{if(['warning','error'].includes(m.type())){result.console.push({elapsed:elapsed(),type:m.type(),text:m.text(),location:m.location()});save().catch(()=>{});}});
 await page.addInitScript(()=>{window.__matchedFrames={n:0,last:0,visibility:[]};function frame(t){window.__matchedFrames.n++;window.__matchedFrames.last=t;requestAnimationFrame(frame);}requestAnimationFrame(frame);addEventListener('visibilitychange',()=>window.__matchedFrames.visibility.push({t:performance.now(),state:document.visibilityState}));});
 if(observer){const p=await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-probe.js','utf8');await page.addInitScript(p.split("  addEventListener('DOMContentLoaded'")[0]+'})();');}
 const baseline=JSON.parse(await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-public/baseline-save.json','utf8'));
 const d=JSON.parse(baseline.payload_bytes);d.holiday_day=2;d.holiday_day_elapsed=320;d.tutorial_version=1;d.yard_gate_open=true;d.yard_inventory.held='';d.yard_inventory.corn=2;d.world_weather={episode:0,remaining:80,seed:451862825,weather:'rain'};d.resident_rest={cause:'sleep',day:2,schema:1};
 await page.goto(url+storePath);
 result.fixture=await page.evaluate(async({d,storePath})=>{const {openStore}=await import('/'+storePath);const s=await openStore();try{const b=await s.recover();if(b.verdict!=='empty')throw Error('fresh profile required');await s.initialize(JSON.stringify(d));const a=await s.recover();return {verdict:a.verdict,generation:a.current.generation,payload_sha256:a.current.payload_sha256};}finally{s.close();}},{d,storePath});await save();
 await page.goto(url);await page.bringToFront();await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:180000});await page.mouse.click(640,370);await page.waitForTimeout(2000);start=Date.now();await record('yard start');await shot('01-yard-start');
 await input('Down2.2s Space leave yard',async()=>{await page.keyboard.down('ArrowDown');await page.waitForTimeout(2200);await page.keyboard.up('ArrowDown');await page.keyboard.press('Space');});await page.waitForTimeout(6500);await record('near entry');await shot('02-near-entry');
 await until(115);await shot('03-night-before-return');
 // Identical unconditional return: no predicate depends on audio/probe state.
 await input('top-right return',async()=>page.mouse.click(1190,43));await page.waitForTimeout(6500);await record('returned');await shot('04-returned');
 await input('Up1.9s Space house',async()=>{await page.keyboard.down('ArrowUp');await page.waitForTimeout(1900);await page.keyboard.up('ArrowUp');await page.keyboard.press('Space');});await page.waitForTimeout(10000);await record('sleep attempt');await shot('05-sleep');
 await until(250);await input('pause master mute',async()=>{await page.keyboard.press('Escape');await page.waitForTimeout(300);await page.mouse.click(640,605);});await page.waitForTimeout(2000);await record('muted');await shot('06-muted');
 await input('master unmute return',async()=>{await page.mouse.click(640,605);await page.keyboard.press('Escape');});await page.waitForTimeout(2500);await record('unmuted');
 await until(400);await input('other tab foreground',async()=>{const other=await context.newPage();await other.goto('about:blank');await other.bringToFront();await page.waitForTimeout(2000);const h=await record('hidden');result.actualHidden=h.visibility==='hidden';await page.bringToFront();await other.close();await page.mouse.click(800,600);});await page.waitForTimeout(2000);await record('trusted return');
 await until(620);await shot('07-long-final');await record('long complete');
 result.visibilityEvents=await page.evaluate(()=>window.__matchedFrames.visibility);
 if(observer)await fs.writeFile(path.join(dir,'audio-observer.json'),JSON.stringify(await page.evaluate(()=>window.__ui704Probe)));
 result.finalSave=await page.evaluate(async storePath=>{const {openStore}=await import('/'+storePath);const s=await openStore();try{const r=await s.snapshot();const d=JSON.parse(r.current.payload_bytes);return {generation:r.current.generation,payload_sha256:r.current.payload_sha256,day:d.holiday_day,elapsed:d.holiday_day_elapsed,rest:d.resident_rest,inventory:d.yard_inventory,exploration_serial:d.exploration_committed_serial};}finally{s.close();}},storePath);
 result.seconds=elapsed();result.webgl=result.console.filter(m=>/WebGL|GL_INVALID/.test(m.text));result.finished=new Date().toISOString();assert(result.actualHidden,'document actually hidden');assert.equal(result.errors.length,0,'page errors');result.exit=0;await save();console.log(JSON.stringify({label,seconds:result.seconds,webgl:result.webgl.length,first:result.webgl[0],save:result.finalSave}));
})().catch(async e=>{result.failure=String(e.stack||e);result.exit=1;await save();console.error(e);process.exitCode=1;}).finally(async()=>{
 // The default CDP context cannot reliably be disposed as a created context.
 // Close only this owned browser, with a bounded process fallback after results.
 const cleanup={started:new Date().toISOString(),pid:child?.pid};
 try{await Promise.race([(async()=>{const c=await browser.newBrowserCDPSession();await c.send('Browser.close');cleanup.browserCloseSent=true;})(),new Promise(r=>setTimeout(r,2500))]);}catch(e){cleanup.closeResult=String(e);}
 try{child?.kill();cleanup.ownedProcessFallback=true;}catch(e){cleanup.fallbackResult=String(e);}
 try{await browser?.close();}catch{}
 await fs.writeFile(path.join(dir,'cleanup.json'),JSON.stringify(cleanup,null,2));
});
