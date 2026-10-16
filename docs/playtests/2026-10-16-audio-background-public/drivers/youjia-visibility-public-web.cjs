// Tests only our isolated browser profile, on the normal public origin.
const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const [phase,expected]=process.argv.slice(2),dir='C:/Users/Zengm/AppData/Local/Temp/youjia-visibility-public-20261016';
const url='https://narutojzm1-dot.github.io/youjia/';
let context,page;const result={phase,expected,started:new Date().toISOString(),records:[],pageErrors:[],console:[]};
const save=()=>fs.writeFile(path.join(dir,phase+'-web.json'),JSON.stringify(result,null,2));
async function snapshot(){
 return page.evaluate(async()=>{const m=await (await fetch('game-release.json',{cache:'no-store'})).json();const {openStore}=await import('./'+m.storageModules.entry+'/store.mjs');const s=await openStore();const r=await s.recover();s.close();return r.current;});
}
async function shot(name){await page.screenshot({path:path.join(dir,phase+'-'+name+'.jpg'),type:'jpeg',quality:76});}
async function action(label,fn,count,frames){
 await page.locator('canvas').focus();const t=await page.evaluate(()=>performance.now());await fn();
 const events=await page.evaluate(t=>window.__ui704Probe.events.filter(e=>e.t>=t&&e.trusted),t);
 const anchor=events.find(e=>e.type==='pointerdown'||e.type==='keydown')?.t??t;
 await page.waitForFunction(t=>window.__ui704Probe.samples.at(-1)?.t>t+1400,anchor,{timeout:20000});
 const probe=await page.evaluate(()=>window.__ui704Probe),sources=probe.sources.filter(s=>s.t>=anchor&&s.t<anchor+1400),ui=sources.filter(s=>!s.loop&&s.frames<50000),samples=probe.samples.filter(s=>s.t>=anchor&&s.t<anchor+1400);
 const r={label,command_t:t,event_anchor:anchor,trusted_events:events,sources,ui_sources:ui,peak:Math.max(0,...samples.map(s=>s.peak)),samples:samples.length,expected:count};result.records.push(r);await save();
 assert(samples.length>10,label+' destination samples');assert.equal(ui.length,count,label+' UI source count');
 if(count===0)assert.equal(r.peak,0,label+' silence');else {assert(r.peak>0.00001,label+' real output');if(frames)assert.equal(ui[0].frames,frames);}
 r.passed=true;await save();console.log(JSON.stringify(r));
}
(async()=>{
 await fs.mkdir(dir,{recursive:true});
 context=await chromium.launchPersistentContext(path.join(dir,'profile'),{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720}});
 result.browser=context.browser()?.version();page=context.pages()[0]||await context.newPage();
 const source=await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-probe.js','utf8');
 await page.addInitScript(source.split("  addEventListener('DOMContentLoaded'")[0]+'})();');
 page.on('pageerror',e=>result.pageErrors.push(String(e)));
 page.on('console',m=>{if(['warning','error'].includes(m.type()))result.console.push({type:m.type(),text:m.text()});});
 result.responses=[];page.on('response',r=>{if(/game-[a-f0-9]+\.pck/.test(r.url()))result.responses.push({url:r.url(),status:r.status()});});
 await page.bringToFront();await page.goto(url,{timeout:90000});await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:180000});
 result.htmlBuild=await page.locator('html').getAttribute('data-build');assert.equal(result.htmlBuild,'game-'+expected.slice(0,7));
 await shot('title');
 if(phase==='release'){
   const baseline=JSON.parse(await fs.readFile(path.join(dir,'baseline-save.json'),'utf8'));
   const before=await snapshot();result.prePlaySave={generation:before?.generation,payload_sha256:before?.payload_sha256};
   if(before.payload_sha256!==baseline.payload_sha256){
     const first=JSON.parse(await fs.readFile(path.join(dir,'first-upgrade-receipt.json'),'utf8'));
     assert.equal(first.payload_sha256,baseline.payload_sha256,'first actual upgrade kept exact payload');
     assert.deepEqual(JSON.parse(before.payload_bytes).yard_inventory,JSON.parse(baseline.payload_bytes).yard_inventory,'retry keeps inventory');
     result.initialExactUpgradeProof='first-upgrade-receipt.json';
   } else {
     await fs.writeFile(path.join(dir,'first-upgrade-receipt.json'),JSON.stringify({expected,payload_sha256:before.payload_sha256,generation:before.generation,checked:new Date().toISOString()}));
   }
   result.preUpgradeSavePreserved=true;
 }
 await page.mouse.click(640,370);await page.waitForTimeout(1800);
 if(phase==='baseline'){
   await page.keyboard.press('Escape');await page.waitForTimeout(200);
   await page.mouse.click(640,335);await page.mouse.click(640,470);await page.waitForTimeout(1000);
   await shot('pause');const current=await snapshot();assert(current?.payload_sha256,'normal gameplay committed a save');
   await fs.writeFile(path.join(dir,'baseline-save.json'),JSON.stringify(current,null,2));
   const data=JSON.parse(current.payload_bytes);result.saved={generation:current.generation,payload_sha256:current.payload_sha256,keys:Object.keys(data)};
 } else {
   // Normal UI isolation: keep background music/ambience at zero regardless of
   // whether this browser restored their prior session switches.
   await page.keyboard.press('Escape');await page.waitForTimeout(250);
   await page.mouse.click(500,420);await page.keyboard.press('Home');
   await page.mouse.click(500,555);await page.keyboard.press('Home');
   await page.waitForTimeout(350);await shot('audio-isolated');
   await page.keyboard.press('Escape');await page.waitForTimeout(1000);
   await action('public basket open',()=>page.mouse.click(527,676),1,5271);await shot('basket');
   await action('public basket close',()=>page.keyboard.press('Escape'),1,4792);
   await action('public album open',()=>page.mouse.click(112,676),1,5271);
   await action('public empty album boundary',()=>page.keyboard.press('ArrowRight'),0);
   await action('public album close',()=>page.keyboard.press('Escape'),1,4792);
   await action('public pause open',()=>page.keyboard.press('Escape'),1,5271);await shot('pause');
   await page.mouse.click(731,110);await page.waitForTimeout(1000);await shot('notes');
   await page.keyboard.press('Escape');await page.waitForTimeout(300);await page.keyboard.press('Escape');await page.waitForTimeout(300);
   await action('public pause for mute',()=>page.keyboard.press('Escape'),1,5271);
   await action('public master mute',()=>page.mouse.click(640,605),0);
   await action('public muted resume',()=>page.keyboard.press('Escape'),0);
   await action('public muted basket open',()=>page.mouse.click(527,676),0);
   await action('public muted basket close',()=>page.keyboard.press('Escape'),0);
   await action('public muted pause',()=>page.keyboard.press('Escape'),0);
   await action('public unmute no queued cue',()=>page.mouse.click(640,605),0);
   await action('public unmuted resume',()=>page.keyboard.press('Escape'),1,4792);
   await page.keyboard.press('Escape');await page.waitForTimeout(500);
   await fs.writeFile(path.join(dir,'release-output-probe.json'),JSON.stringify(await page.evaluate(()=>window.__ui704Probe)));
 }
 assert.equal(result.pageErrors.length,0,'no page errors');result.finished=new Date().toISOString();result.passed=true;await save();console.log('UI704_PUBLIC_WEB_PASS '+phase);
})().catch(async e=>{result.error=String(e.stack||e);await save();console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();});
