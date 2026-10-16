const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const dir='C:/Users/Zengm/AppData/Local/Temp/youjia-regional-wind17-20261016',url='http://127.0.0.1:8178/',source='7a4bc8a8d47e13e9fbb571e860f0050b9d0bdf76';
async function snapshot(p){return p.evaluate(async()=>{const {openStore}=await import('/web/save/store.mjs');const s=await openStore();try{const r=await s.snapshot(),d=JSON.parse(r.current.payload_bytes);return {generation:r.current.generation,payload_sha256:r.current.payload_sha256,day:d.holiday_day,elapsed:d.holiday_day_elapsed,rest:d.resident_rest,inventory:d.yard_inventory,exploration_serial:d.exploration_committed_serial};}finally{s.close();}});}
(async()=>{
 const c=await chromium.launchPersistentContext(path.join(dir,'web-profile-r17'),{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720}});
 const result={source,actual_close_then_same_profile_reopen:true,pageErrors:[],console:[],no_save_fixture_write:true};
 try{
  await c.addInitScript((await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-ui704-probe.js','utf8')).split("  addEventListener('DOMContentLoaded'")[0]+'})();');
  await c.addInitScript(await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-wind17-key-observer.js','utf8'));
  const p=c.pages()[0];p.on('pageerror',e=>result.pageErrors.push(String(e)));p.on('console',m=>{if(['warning','error'].includes(m.type()))result.console.push(m.text());});
  await p.goto(url+'web/save/store.mjs');result.before=await snapshot(p);assert(result.before.day>=3);assert(['sleep','awake'].includes(result.before.rest.cause));
  await p.goto(url);await p.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:90000});result.htmlBuild=await p.locator('html').getAttribute('data-build');assert.equal(result.htmlBuild,'game-'+source.slice(0,7));
  await p.mouse.click(640,370);await p.waitForTimeout(2000);
  result.observation=await p.evaluate(()=>({keys:window.__windKeyAudit.plays,sources:window.__ui704Probe.sources,diagnostics:JSON.parse(window.__manusBgm.diagnostics())}));
  const wind=result.observation.sources.filter(x=>x.observedRuntimeBufferKey==='file:res://assets/holiday/audio/bed_yard_gust.ogg');
  assert(wind.length>0,'actual Web source started from approved17 resource key');assert(!result.observation.keys.some(x=>x.key==='file:res://assets/holiday/audio/bed_yard_env.ogg'),'old04 not dispatched');
  const long=JSON.parse(await fs.readFile(path.join(dir,'web-long-checks-r17.json'),'utf8'));result.windLongRouteMatchedByActualPCM=wind.some(w=>w.channel0FloatSha256&&long.records.at(-1).sources.some(x=>x.channel0FloatSha256===w.channel0FloatSha256));assert(result.windLongRouteMatchedByActualPCM);
  result.sameDurationNotSoleIdentityEvidence=true;
  await p.keyboard.press('Escape');await p.waitForTimeout(300);await p.screenshot({path:path.join(dir,'web-r17-reopened.jpg'),type:'jpeg',quality:75});result.after=await snapshot(p);assert.equal(result.after.day,result.before.day);assert.equal(result.after.exploration_serial,result.before.exploration_serial);assert.deepEqual(result.after.inventory,result.before.inventory);assert.equal(result.pageErrors.length,0);assert(!result.console.some(x=>/WebGL|INVALID_OPERATION/.test(x)));
  result.pass=true;await fs.writeFile(path.join(dir,'web-r17-reopen.json'),JSON.stringify(result,null,2));console.log(JSON.stringify({pass:true,day:result.after.day,windKey:wind[0].observedRuntimeBufferKey,windPcm:wind[0].channel0FloatSha256,matchedLongRoute:true,old04Dispatched:false,inventory:result.after.inventory}));
 }catch(e){result.failure=String(e.stack||e);await fs.writeFile(path.join(dir,'web-r17-reopen.json'),JSON.stringify(result,null,2));throw e;}finally{await c.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
