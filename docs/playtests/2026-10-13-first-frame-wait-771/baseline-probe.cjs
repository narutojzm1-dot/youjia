const fs=require('node:fs'),vm=require('node:vm');
const fixture=fs.readFileSync('test/loading_shell_test.cjs','utf8').split('(async()=>{')[0];
const probe=`(async()=>{
 const t=setup(); await t.modules(); t.resolve(); await flush(); t.tick(96000);
 console.log(JSON.stringify({fixture:'actual loading.html with mocked Engine/startGame and clock; not a browser reproduction',atMs:96000,hidden:t.nodes.loading.hidden,status:t.nodes['loading-status'].textContent,detail:t.nodes['loading-detail'].textContent,notice:t.nodes['loading-notice'].textContent,retryHidden:t.nodes['loading-retry'].hidden,runtime:t.runtime,timings:t.window.youjiaLoadTimings},null,2));
})().catch(e=>{console.error(e);process.exitCode=1});`;
vm.runInNewContext(fixture+probe,{require,console,setImmediate,setTimeout,clearTimeout,URL,AbortController,process});
