const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('node:fs/promises'),assert=require('node:assert/strict');
const out=(process.argv[2]||'ui704-output')+'/';
let b;const results=[];
(async()=>{
 b=await chromium.launch({executablePath:process.env.CHROME_PATH,headless:true});const c=await b.newContext({viewport:{width:1280,height:720}}),p=await c.newPage();
 await p.route('**/ui704-probe.js',async r=>r.fulfill({contentType:'text/javascript',body:await fs.readFile(require('node:path').join(__dirname,'observer.js'),'utf8')}));
 await p.goto('http://127.0.0.1:8174/');await p.waitForFunction(()=>window.youjiaLoadTimings?.firstFrame>0,{timeout:60000});await p.mouse.click(640,370);await p.waitForTimeout(1200);await p.keyboard.press('Escape');await p.waitForTimeout(150);await p.mouse.click(640,335);await p.mouse.click(640,470);await p.keyboard.press('Escape');await p.waitForTimeout(500);
 async function check(label,act,count){const t=await p.evaluate(()=>performance.now());await act();await p.waitForFunction(t=>window.__ui704Probe.samples.at(-1)?.t>t+1000,t);const d=await p.evaluate(()=>window.__ui704Probe);const sources=d.sources.filter(s=>s.t>=t),events=d.events.filter(e=>e.t>=t),samples=d.samples.filter(s=>s.t>=t);const row={label,sources,events,peak:Math.max(0,...samples.map(s=>s.peak)),expected:count};results.push(row);await fs.writeFile(out+'web-rapid-checks.json',JSON.stringify({results},null,2));assert.equal(sources.length,count,label);assert(row.peak>0,label+' output');}
 await check('real mouse double click basket opens with one cue',()=>p.mouse.dblclick(527,676,{delay:0}),1);await p.screenshot({path:out+'web-rapid-doubleclick.jpg',type:'jpeg',quality:72});
 await check('close after double click',()=>p.keyboard.press('Escape'),1);
 await check('real rapid mouse-open plus Esc-close has no stacked or queued close cue',async()=>{await p.mouse.click(527,676);await p.keyboard.press('Escape');},1);await p.screenshot({path:out+'web-rapid-final-yard.jpg',type:'jpeg',quality:72});
 console.log('UI704_RAPID_PASS '+results.length);
})().catch(async e=>{await fs.writeFile(out+'web-rapid-error.txt',String(e.stack||e));console.error(e);process.exitCode=1;}).finally(async()=>b?.close());
