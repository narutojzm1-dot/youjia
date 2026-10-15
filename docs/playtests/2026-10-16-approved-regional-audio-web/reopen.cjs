const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const dir='C:/Users/Zengm/AppData/Local/Temp/youjia-regional-535-validation';
(async()=>{
 const c=await chromium.launchPersistentContext(path.join(dir,'web-profile-r2'),{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720}});
 try {const p=c.pages()[0];await p.goto('http://127.0.0.1:8175/web/save/store.mjs');const state=await p.evaluate(async()=>{const {openStore}=await import('/web/save/store.mjs');const s=await openStore();const r=await s.snapshot();s.close();const d=JSON.parse(r.current.payload_bytes);return {generation:r.current.generation,payload_sha256:r.current.payload_sha256,day:d.holiday_day,elapsed:d.holiday_day_elapsed,rest:d.resident_rest,inventory:d.yard_inventory,exploration_serial:d.exploration_committed_serial};});
 assert(state.day>=3,'normal house action committed following day');assert(['sleep','awake'].includes(state.rest.cause),'valid rest provenance persisted');
 await p.goto('http://127.0.0.1:8175/');await p.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:90000});await p.mouse.click(640,370);await p.waitForTimeout(1200);await p.keyboard.press('Escape');await p.waitForTimeout(300);await p.screenshot({path:path.join(dir,'web-r2-reopened.jpg'),type:'jpeg',quality:75});await fs.writeFile(path.join(dir,'web-r2-reopen.json'),JSON.stringify({source:'2ca748c8e11c98340a4709cf1059d8fd2c2330d8',state,normal_reopen_to_play_then_pause:true},null,2));console.log(JSON.stringify(state));
 }finally{await c.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
