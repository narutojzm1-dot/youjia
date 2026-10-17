from pathlib import Path
p=Path(__file__).parent
header=(p/'garden-web.cjs').read_text(encoding='utf8').split('(async()=>{\n await fs.mkdir(dir',1)[0]
body=r'''
(async()=>{
 await fs.mkdir(dir,{recursive:true});await new Promise(r=>server.listen(0,'127.0.0.1',r));url='http://127.0.0.1:'+server.address().port+'/';mod=new URL('save-'+source.slice(0,7)+'/store.mjs',url).href;
 await launch();await page.goto(new URL('game-release.json',url).href);const initial=JSON.parse(await fs.readFile(path.join(__dirname,'fixture.json'),'utf8'));initial.keepsakes={};result.initialFixture=initial;
 await page.evaluate(async({d,m})=>{const {openStore}=await import(m),s=await openStore();try{if((await s.recover()).verdict!=='empty')throw Error('fresh profile required');await s.initialize(JSON.stringify(d));}finally{s.close();}},{d:initial,m:mod});
 await boot();await page.mouse.click(100,600);await page.waitForTimeout(6500);
 let n=0;async function shot(){const image='source-ui-'+String(n++).padStart(2,'0')+'.jpg';await page.screenshot({path:path.join(dir,image),type:'jpeg',quality:90});const d=await read();const row={image,exploration:d.exploration,keepsakes:d.keepsakes,garden:d.yard_garden};result.samples.push(row);await save();console.log(JSON.stringify(row));}
 await shot();console.log('READY_FOR_INPUT');
 const rl=require('node:readline').createInterface({input:process.stdin,crlfDelay:Infinity});
 for await(const line of rl){if(!line.trim())continue;try{const q=JSON.parse(line);if(q.action==='close')break;if(q.action==='click')await page.mouse.click(q.x,q.y);if(q.action==='key')await page.keyboard.press(q.key);if(q.action==='hold'){await page.keyboard.down(q.key);await page.waitForTimeout(Math.min(q.ms,12000));await page.keyboard.up(q.key);}await page.waitForTimeout(Math.min(q.wait||600,15000));await shot();}catch(e){console.log('COMMAND_ERROR '+e.message);}}
 result.final=await read();result.pass=!result.errors.length;await save();
})().catch(async e=>{result.failure=String(e.stack||e);await save();console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();server.close();});
'''
(p/'garden-source-ui.cjs').write_text(header+body,encoding='utf8')
