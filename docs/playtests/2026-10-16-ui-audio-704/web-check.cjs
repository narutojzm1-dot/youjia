// Isolated automated browser test of the exported game. No user browser/profile.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const dir=process.argv[2] || 'ui704-output';
const records=[],errors=[];let browser,page;
const write=()=>fs.writeFile(path.join(dir,'web-automated-checks.json'),JSON.stringify({browser:browser?.version(),source:'ab26805fef668c030236b021776cf374f4bc47d3',records,errors},null,2));
async function shot(name){await page.screenshot({path:path.join(dir,name+'.jpg'),type:'jpeg',quality:72});}
async function action(label,act,count,frames){
  await page.locator('canvas').focus();const t=await page.evaluate(()=>performance.now());await act();
  await page.waitForFunction(t=>window.__ui704Probe.samples.at(-1)?.t>t+1100,t,{timeout:15000});
  const p=await page.evaluate(()=>window.__ui704Probe),sources=p.sources.filter(s=>s.t>=t),samples=p.samples.filter(s=>s.t>=t&&s.t<t+1100);
  const r={label,t,sources,peak:Math.max(0,...samples.map(s=>s.peak)),samples:samples.length,expected:count};records.push(r);await write();
  assert(samples.length>10,label+' has output samples');
  if(count!==null)assert.equal(sources.length,count,label+' source count');
  if(count===0)assert.equal(r.peak,0,label+' remains silent');
  if(count===1){assert(r.peak>0.00001,label+' has real destination output');if(frames)assert.equal(sources[0].frames,frames,label+' approved source mapping');}
  r.passed=true;await write();console.log(JSON.stringify({label,count:sources.length,peak:r.peak,passed:true}));
}
async function boot(){await page.goto('http://127.0.0.1:8174/');await page.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,{timeout:60000});}
async function isolate(){await page.keyboard.press('Escape');await page.waitForTimeout(200);await page.mouse.click(640,335);await page.mouse.click(640,470);await page.waitForTimeout(200);await shot('web-desktop-background-off');await page.keyboard.press('Escape');await page.waitForTimeout(1000);}
(async()=>{
  await fs.mkdir(dir,{recursive:true});browser=await chromium.launch({executablePath:process.env.CHROME_PATH,headless:true});
  const context=await browser.newContext({viewport:{width:1280,height:720}});page=await context.newPage();page.on('pageerror',e=>errors.push(String(e)));
  await page.route('**/ui704-probe.js',async route=>route.fulfill({contentType:'text/javascript',body:await fs.readFile(path.join(__dirname,'observer.js'),'utf8')}));
  await boot();await shot('web-desktop-title');await page.mouse.click(640,370);await page.waitForTimeout(1500);await isolate();
  await action('basket mouse open',()=>page.mouse.click(527,676),1,5271);await shot('web-desktop-basket');
  await action('basket Esc close',()=>page.keyboard.press('Escape'),1,4792);
  await action('album mouse open',()=>page.mouse.click(112,676),1,5271);await shot('web-desktop-empty-album');
  await action('empty album right boundary',()=>page.keyboard.press('ArrowRight'),0);
  await action('empty album left boundary',()=>page.keyboard.press('ArrowLeft'),0);
  await action('album Esc close',()=>page.keyboard.press('Escape'),1,4792);
  await action('pause Esc open',()=>page.keyboard.press('Escape'),1,5271);
  await action('pause mouse resume',()=>page.mouse.click(640,167),1,4792);
  await action('pause for mute',()=>page.keyboard.press('Escape'),1,5271);
  await action('master mute on',()=>page.mouse.click(640,605),0);await shot('web-desktop-muted');
  await action('muted pause close',()=>page.keyboard.press('Escape'),0);
  await action('muted basket open',()=>page.mouse.click(527,676),0);
  await action('muted basket close',()=>page.keyboard.press('Escape'),0);
  await action('muted pause open',()=>page.keyboard.press('Escape'),0);
  await action('master mute off',()=>page.mouse.click(640,605),0);
  await action('unmute no stale replay',()=>page.waitForTimeout(100),0);
  await action('unmuted pause close',()=>page.keyboard.press('Escape'),1,4792);
  await action('controlled context suspend',()=>page.getByRole('button',{name:'测试：挂起音频',exact:true}).click(),0);
  await action('first trusted gesture after suspend',()=>page.mouse.click(527,676),null);
  await action('resumed no delayed replay',()=>page.waitForTimeout(100),0);
  await action('unlocked basket close',()=>page.keyboard.press('Escape'),1,4792);
  await fs.writeFile(path.join(dir,'web-desktop-output-probe.json'),JSON.stringify(await page.evaluate(()=>window.__ui704Probe)));
  // Controlled four-photo fixture via production envelope/transaction functions,
  // with the game unloaded. This is not normal photo acquisition or a user save.
  await page.goto('http://127.0.0.1:8174/web/save/store.mjs');
  const seed=await page.evaluate(async()=>{const {openStore,envelope}=await import('/web/save/store.mjs');const store=await openStore();const old=await store.recover();const data=JSON.parse(old.current.payload_bytes);data.album=['pond_hen_ride','pond_goose_refused','goose_horse_mount','llama_overcast_goose_annoyed'];const next=await envelope(JSON.stringify(data),old.current);await store.submit(next);await store.acknowledge(next.request_id);const after=await store.recover();store.close();return {before:old.current,after:after.current,fixture:'four photos for UI page navigation only'};});
  await fs.writeFile(path.join(dir,'web-controlled-album-fixture.json'),JSON.stringify(seed,null,2));
  await boot();await page.mouse.click(640,370);await page.waitForTimeout(1500);await isolate();
  await action('fixture album open',()=>page.mouse.click(112,676),1,5271);
  await action('fixture first page boundary',()=>page.keyboard.press('ArrowLeft'),0);
  await action('fixture valid page right',()=>page.keyboard.press('ArrowRight'),1);await shot('web-desktop-valid-page');
  await action('fixture last page boundary',()=>page.keyboard.press('ArrowRight'),0);
  await action('fixture valid page left',()=>page.keyboard.press('ArrowLeft'),1);
  await action('fixture album close',()=>page.keyboard.press('Escape'),1,4792);
  await fs.writeFile(path.join(dir,'web-fixture-output-probe.json'),JSON.stringify(await page.evaluate(()=>window.__ui704Probe)));
  assert.equal(errors.length,0,'no page errors');await write();console.log('UI704_WEB_PASS '+records.length);
})().catch(async e=>{errors.push(String(e.stack||e));await write();console.error(e);process.exitCode=1;}).finally(async()=>{await browser?.close();});
