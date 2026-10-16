const {chromium}=require('C:/Users/Zengm/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const [url,profile,out,expected,baseline]=process.argv.slice(2);
(async()=>{
 await fs.mkdir(out,{recursive:true});let browser;
 const result={url,expected,started:new Date().toISOString(),fixtureWrites:false,errors:[],console:[]};
 try{
  browser=await chromium.launchPersistentContext(profile,{executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720}});
  const page=browser.pages()[0];page.on('pageerror',e=>result.errors.push(String(e)));page.on('console',m=>{if(['warning','error'].includes(m.type()))result.console.push({type:m.type(),text:m.text()});});
  await page.goto(url);await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,null,{timeout:180000});
  result.manifest=await page.evaluate(async()=>await(await fetch('game-release.json',{cache:'no-store'})).json());
  assert.equal(result.manifest.sourceCommit,expected);
  assert.equal(result.manifest.engineAssets.repairs[0].sha256,'fdab8cf15509d9042cd7f6f9f9eafb5201c85a59ed161d91346046b2a9268fe4');
  result.saved=await page.evaluate(async entry=>{const {openStore}=await import('./'+entry+'/store.mjs');const s=await openStore();try{const r=await s.recover();const d=JSON.parse(r.current.payload_bytes);return {verdict:r.verdict,generation:r.current.generation,payload_sha256:r.current.payload_sha256,day:d.holiday_day,rest:d.resident_rest,inventory:d.yard_inventory};}finally{s.close();}},result.manifest.storageModules.entry);
  const old=JSON.parse(await fs.readFile(baseline,'utf8'));assert.equal(result.saved.verdict,'clean');assert.deepEqual(result.saved.inventory,JSON.parse(old.payload_bytes).yard_inventory);if(old.expectedDay!==undefined)assert.equal(result.saved.day,old.expectedDay);if(old.expectedRestCause)assert.equal(result.saved.rest.cause,old.expectedRestCause);
  await page.mouse.click(640,370);await page.waitForTimeout(1200);await page.keyboard.press('Escape');await page.waitForTimeout(250);await page.mouse.click(731,110);await page.waitForTimeout(700);await page.screenshot({path:path.join(out,'reopen-notes.jpg'),type:'jpeg',quality:76});
  assert.equal(result.errors.length,0);assert.equal(result.console.filter(x=>/GL_INVALID|INVALID_OPERATION/.test(x.text)).length,0);
  result.pass=true;result.finished=new Date().toISOString();await fs.writeFile(path.join(out,'reopen.json'),JSON.stringify(result,null,2));console.log(JSON.stringify({pass:true,saved:result.saved,source:result.manifest.sourceCommit}));
 }finally{await browser?.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
