// Existing isolated QA profile, normal public origin; read only, no fixture writes.
const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const dir='C:/Users/Zengm/AppData/Local/Temp/youjia-index-target-public-20261016';
(async()=>{await fs.mkdir(dir,{recursive:true});let c;
 try{
  c=await chromium.launchPersistentContext('C:/Users/Zengm/AppData/Local/Temp/youjia-visibility-public-20261016/profile',{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720}});
  const p=c.pages()[0];await p.goto('https://narutojzm1-dot.github.io/youjia/');await p.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:180000});
  const d=await p.evaluate(async()=>{const m=await(await fetch('game-release.json',{cache:'no-store'})).json();const {openStore}=await import('./'+m.storageModules.entry+'/store.mjs');const s=await openStore();try{const r=await s.recover();return {manifest:m,current:r.current,verdict:r.verdict};}finally{s.close();}});
  assert.equal(d.manifest.sourceCommit,'49230855694b58ed95e10d56abd214dece0c64ed');assert.equal(d.verdict,'clean');
  const old=JSON.parse(await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-visibility-public-20261016/baseline-save.json','utf8'));assert.equal(d.current.payload_sha256,old.payload_sha256,'same original pre-upgrade save');
  await fs.writeFile(path.join(dir,'baseline-save.json'),JSON.stringify(d.current,null,2));await fs.writeFile(path.join(dir,'baseline-progress.json'),JSON.stringify({checked:new Date().toISOString(),source:d.manifest.sourceCommit,originalPayloadUnchanged:true,generation:d.current.generation,payload_sha256:d.current.payload_sha256,fixtureWrites:false,inventory:JSON.parse(d.current.payload_bytes).yard_inventory},null,2));
  console.log('ACTUAL_OLD_PUBLIC_BASELINE '+d.current.payload_sha256);
 }finally{await c?.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
