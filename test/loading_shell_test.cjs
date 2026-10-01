const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const code=fs.readFileSync('web/loading.html','utf8').match(/<script>([\s\S]*?)<\/script>/)[1].replace('$GODOT_CONFIG','{"focusCanvas":true}').replace('$GODOT_THREADS_ENABLED','false');
function setup(missing=[]){
 const nodes={},listeners={};let onProgress,resolve,clock=0,interval;
 const make=()=>({hidden:false,textContent:'',value:0,setAttribute(){},removeAttribute(k){delete this[k]},addEventListener(k,f){this[k]=f},focus(){this.focused=true}});
 const window={addEventListener(k,f){listeners[k]=f},removeEventListener(k){delete listeners[k]},location:{reload(){}}};
 const document={title:'悠长的假期',documentElement:{},getElementById(k){return nodes[k]??=make()},createElement:make,head:{appendChild(s){s.load()}}};
 class Engine{static getMissingFeatures(){return missing} startGame(o){onProgress=o.onProgress;return new Promise(r=>resolve=r)}}
 vm.runInNewContext(code,{window,document,Engine,performance:{now:()=>clock},console:{error(){},info(){}},setInterval(f){interval=f;return 1},clearInterval(){}});
 return {nodes,window,progress:(a,b)=>onProgress(a,b),resolve:()=>resolve(),frame:()=>listeners['youjia:first-frame']?.(),tick(t){clock=t;interval()}};
}
(async()=>{
 let t=setup();t.progress(5*1048576,10*1048576);assert.match(t.nodes['loading-status'].textContent,/50%.*5.0 \/ 10.0 MiB/);assert.match(t.nodes['loading-status'].textContent,/解压后/);
 t.progress(10*1048576,10*1048576);assert.equal(t.nodes.loading.hidden,false);assert.equal(t.window.youjiaLoadTimings.downloadComplete,0);
 t.resolve();await new Promise(setImmediate);assert.equal(t.nodes.loading.hidden,false,'engine ready is not first frame');t.frame();assert.equal(t.nodes.loading.hidden,true);assert.equal(t.nodes.canvas.focused,true);
 t=setup();t.frame();assert.equal(t.nodes.loading.hidden,false);t.resolve();await new Promise(setImmediate);assert.equal(t.nodes.loading.hidden,true,'first-frame event may precede promise resolution');
 t=setup();t.progress(12,0);assert.equal(t.nodes['loading-progress'].value,undefined);t.tick(31000);assert.equal(t.nodes['loading-notice'].hidden,false);
 t=setup(['WebGL2']);assert.match(t.nodes['loading-status'].textContent,/WebGL2/);assert.equal(t.nodes['loading-retry'].hidden,false);assert.equal(t.nodes.loading.hidden,false);
 console.log('Loading shell: bytes, unknown totals, stall notice, first-frame ordering and error checks PASS');
})().catch(e=>{console.error(e);process.exitCode=1});
