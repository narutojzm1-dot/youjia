const {chromium}=require('C:/Users/jiangzengming/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright-core');
const fs=require('node:fs/promises'),p=require('node:path'),cp=require('node:child_process'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const dir=p.join(__dirname,process.argv[2]||'stream804-matrix'),cand=p.join(dir,'source/art/concepts/env_fx_stream_20261014');let ctx,server,log,summary;
(async()=>{
 const ident=JSON.parse(await fs.readFile(p.join(dir,'identity-base.json'),'utf8'));
 log=await fs.open(p.join(dir,'chrome_matrix.log'),'w');
 server=cp.spawn('python',['-X','utf8',p.join(cand,'web_probe_server.py'),'--directory',p.join(dir,'site'),'--port-file',p.join(dir,'server.port'),'--server-id',ident.server_id,'--upload-dir',p.join(dir,'uploads'),'--build-id',ident.build_id],{windowsHide:true,stdio:['ignore','pipe','pipe']});let serverText='';server.stdout.on('data',d=>serverText+=d);server.stderr.on('data',d=>serverText+=d);
 let port;for(let i=0;i<100;i++){try{port=(await fs.readFile(p.join(dir,'server.port'),'utf8')).trim();if(port)break;}catch{}await new Promise(r=>setTimeout(r,100));}assert(port);assert.equal(await (await fetch('http://127.0.0.1:'+port+'/__probe_server_id')).text(),ident.server_id);
 ident.served_pck_sha256=crypto.createHash('sha256').update(Buffer.from(await (await fetch('http://127.0.0.1:'+port+'/index.pck')).arrayBuffer())).digest('hex');assert.equal(ident.served_pck_sha256,ident.pck_sha256);ident.port=+port;
 ctx=await chromium.launchPersistentContext(p.join(dir,'owned-profile'),{headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',viewport:{width:1672,height:941},deviceScaleFactor:1,args:['--no-first-run','--no-default-browser-check']});
 ident.chrome_version=ctx.browser()?.version()||'Chrome persistent context';ident.chrome_gl_flags='default hardware backend';
 const page=ctx.pages()[0];let lines=[];page.on('console',m=>{lines.push(m.text());if(m.text().includes('WEBMATRIX {'))summary=m.text();});page.on('pageerror',e=>lines.push('PAGE_ERROR '+e));
 ident.url='http://127.0.0.1:'+port+'/index.html?matrix=1';await page.goto(ident.url);
 for(let i=0;i<2400&&!summary;i++){await page.waitForTimeout(500);if(i%20===0)await fs.writeFile(p.join(dir,'chrome_matrix.log'),lines.join('\n'));}
 assert(summary,'matrix did not complete');await fs.writeFile(p.join(dir,'chrome_matrix.log'),lines.join('\n'));await fs.writeFile(p.join(dir,'run_identity.json'),JSON.stringify(ident,null,2));await page.screenshot({path:p.join(dir,'matrix-final.png')});console.log(summary);
 await ctx.close();ctx=null;server.kill();await fs.writeFile(p.join(dir,'server.log'),serverText);
 const v=cp.spawnSync('python',['-X','utf8',p.join(cand,'web_matrix_20261017/web_matrix_verdict.py'),'--log',p.join(dir,'chrome_matrix.log'),'--uploads',p.join(dir,'uploads'),'--identity',p.join(dir,'run_identity.json'),'--out',p.join(dir,'verdict.json')],{encoding:'utf8',windowsHide:true});await fs.writeFile(p.join(dir,'verifier.log'),v.stdout+'\n'+v.stderr);console.log(v.stdout);assert.equal(v.status,0,v.stderr);
})().catch(async e=>{await fs.writeFile(p.join(dir,'failure.txt'),e.stack||String(e));console.error(e);process.exitCode=1;}).finally(async()=>{await ctx?.close();server?.kill();await log?.close();});
