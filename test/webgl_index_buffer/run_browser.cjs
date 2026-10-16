// Standalone QA fixture; never connects to a user's browser or game save.
// PLAYWRIGHT_MODULE may name an installed module; CHROME may select Chrome.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('node:fs/promises'),path=require('node:path');
const [url,out]=process.argv.slice(2);
(async()=>{
 await fs.mkdir(out,{recursive:true});
 const result={url,started:new Date().toISOString(),console:[],errors:[]};
 const browser=await chromium.launch({executablePath:process.env.CHROME || undefined,headless:true});
 try{
  const page=await browser.newPage({viewport:{width:800,height:600}});result.browser=browser.version();
  page.on('console',m=>result.console.push({type:m.type(),text:m.text()}));
  page.on('pageerror',e=>result.errors.push(String(e)));
  await page.goto(url);
  await page.waitForFunction(()=>window.__minimalDone===true,null,{timeout:45000});
  await page.screenshot({path:path.join(out,'geometry.png')});
  result.renderer=await page.evaluate(()=>{
    const gl=document.querySelector('canvas').getContext('webgl2');
    const ext=gl.getExtension('WEBGL_debug_renderer_info');
    return {version:gl.getParameter(gl.VERSION),renderer:ext?gl.getParameter(ext.UNMASKED_RENDERER_WEBGL):gl.getParameter(gl.RENDERER)};
  });
  result.wasmValid=await page.evaluate(async()=>WebAssembly.validate(await (await fetch('index.wasm')).arrayBuffer()));
  result.finished=new Date().toISOString();
  result.invalidOperations=result.console.filter(x=>/GL_INVALID|INVALID_OPERATION/.test(x.text)).length;
  await fs.writeFile(path.join(out,'result.json'),JSON.stringify(result,null,2));
  console.log(JSON.stringify({out,errors:result.errors,invalidOperations:result.invalidOperations,wasmValid:result.wasmValid,renderer:result.renderer}));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
