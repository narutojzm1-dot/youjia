from pathlib import Path
p=Path(__file__).parent
s=(p/'garden-web.cjs').read_text(encoding='utf8')
header=s.split('(async()=>{\n await fs.mkdir(dir',1)[0]
body=r'''
(async()=>{
 await fs.mkdir(dir,{recursive:true});await new Promise(r=>server.listen(0,'127.0.0.1',r));url='http://127.0.0.1:'+server.address().port+'/';mod=new URL('save-'+source.slice(0,7)+'/store.mjs',url).href;
 await launch();await page.goto(new URL('game-release.json',url).href);
 const initial=JSON.parse(await fs.readFile(path.join(__dirname,'web-actual-r2/result.json'),'utf8')).beforeClose;
 initial.holiday_day=4;initial.holiday_day_elapsed=160;initial.resident_rest={schema:1,day:4,cause:'sleep'};
 initial.world_weather={episode:0,remaining:500,seed:451862825,weather:process.argv[3]||'sun'};
 initial.album=['fish_first_catch'];initial.photo_moments={fish_first_catch:JSON.parse(await fs.readFile(path.join(__dirname,'garden-photo.json'),'utf8'))};
 result.controlledDay4BloomFixture=true;result.initialFixture=initial;
 await page.evaluate(async({d,m})=>{const {openStore}=await import(m),s=await openStore();try{assertNever=0;}catch{}try{if((await s.recover()).verdict!=='empty')throw Error('fresh profile required');await s.initialize(JSON.stringify(d));}finally{s.close();}},{d:initial,m:mod});
 result.bootMs=await boot();await page.waitForTimeout(5000);
 for(const v of [{width:1280,height:720},{width:390,height:844},{width:844,height:390}]){await page.setViewportSize(v);if(v.width===390){await page.keyboard.down('KeyW');await page.waitForTimeout(650);await page.keyboard.up('KeyW');await page.keyboard.down('KeyD');await page.waitForTimeout(3000);await page.keyboard.up('KeyD');}await page.waitForTimeout(700);await page.screenshot({path:path.join(dir,'bloom-'+v.width+'x'+v.height+'.jpg'),type:'jpeg',quality:92});}
 await page.setViewportSize({width:1280,height:720});await page.mouse.click(114,676);await page.waitForTimeout(400);await page.screenshot({path:path.join(dir,'album-young-bed-frozen.jpg'),type:'jpeg',quality:92});
 result.after=await read();assert.deepEqual(result.after.photo_moments.fish_first_catch,initial.photo_moments.fish_first_catch);assert.deepEqual(result.after.yard_garden,initial.yard_garden);assert.equal(result.errors.length,0);assert(!result.console.some(x=>/SCRIPT ERROR|WebGL|INVALID_OPERATION/.test(x)));result.pass=true;await save();console.log('BLOOM visual pass '+initial.world_weather.weather);
})().catch(async e=>{result.failure=String(e.stack||e);await save();console.error(e);process.exitCode=1;}).finally(async()=>{await context?.close();server.close();});
'''
# The fixture initializer uses only the public module; remove an inert diagnostic.
body=body.replace('try{assertNever=0;}catch{}','')
(p/'garden-bloom.cjs').write_text(header+body,encoding='utf8')
