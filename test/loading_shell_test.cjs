const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const code=fs.readFileSync('web/loading.html','utf8').match(/<script>([\s\S]*?)<\/script>/)[1].replace('$GODOT_CONFIG','{"focusCanvas":true}').replace('$GODOT_THREADS_ENABLED','false').replace(/\bimport\(/g,'__import(');
const flush=()=>new Promise(setImmediate);
function setup(missing=[]){
 const nodes={},listeners={};let onProgress,resolve,reject,clock=0,interval,starts=0,constructed=0,runtime='uninstalled';
 const imports=new Map();
 const make=()=>({hidden:false,textContent:'',value:0,setAttribute(){},removeAttribute(k){delete this[k]},addEventListener(k,f){this[k]=f},focus(){this.focused=true}});
 const window={addEventListener(k,f){listeners[k]=f},removeEventListener(k){delete listeners[k]},location:{reload(){}}};
 const document={title:'悠长的假期',documentElement:{dataset:{}},getElementById(k){return nodes[k]??=make()},createElement:make,head:{appendChild(s){s.load()}}};
 class Engine{static getMissingFeatures(){return missing} constructor(o){constructed++;assert.equal(o.persistentPaths.length,0)} startGame(o){starts++;assert.equal(o.persistentPaths.length,0);onProgress=o.onProgress;return new Promise((r,j)=>{resolve=r;reject=j})}}
 const captureLegacy=()=>{};
 vm.runInNewContext(code,{window,document,Engine,performance:{now:()=>clock},console:{error(){},info(){}},setInterval(f){interval=f;return 1},clearInterval(){},__import(path){return new Promise((resolve,reject)=>imports.set(path,{resolve,reject}))}});
 const bridge={installSaveHost({runtimeReady,captureLegacy:capture}){assert.equal(capture,captureLegacy);runtime='pending';runtimeReady.then(()=>runtime='resolved',()=>runtime='rejected')}};
 return {nodes,window,get starts(){return starts},get constructed(){return constructed},get runtime(){return runtime},
  async modules(){imports.get('./web/save/bridge.mjs').resolve(bridge);await flush();assert.equal(starts,0,'reader must load before engine starts');imports.get('./web/save/idbfs_source.mjs').resolve({captureIdbfsSource:captureLegacy});await flush()},
  async moduleFailure(){imports.get('./web/save/bridge.mjs').reject(Error('module fetch failed'));await flush()},
  progress:(a,b)=>onProgress(a,b),resolve:()=>resolve(),reject:()=>reject(Error('engine start failed')),frame:()=>listeners['youjia:first-frame']?.(),blocked:()=>listeners['youjia:save-blocked']?.({detail:'quarantined'}),tick(t){clock=t;interval()}};
}
(async()=>{
 let t=setup();await flush();assert.equal(t.constructed,0,'bridge must finish before Engine is constructed');assert.equal(t.starts,0);await t.modules();assert.equal(t.starts,1);assert.equal(t.runtime,'pending','installing bridge does not resolve Host runtime');
 t.progress(5*1048576,10*1048576);assert.match(t.nodes['loading-status'].textContent,/50%.*5.0 \/ 10.0 MiB/);assert.match(t.nodes['loading-status'].textContent,/解压后/);
 t.progress(10*1048576,10*1048576);assert.equal(t.nodes.loading.hidden,false);assert.equal(t.window.youjiaLoadTimings.downloadComplete,0);
 t.resolve();await flush();assert.equal(t.runtime,'resolved','actual startGame completion unlocks Host');assert.equal(t.nodes.loading.hidden,false,'engine ready is not first frame');t.frame();assert.equal(t.nodes.loading.hidden,true);assert.equal(t.nodes.canvas.focused,true);
 t=setup();await t.modules();t.frame();assert.equal(t.nodes.loading.hidden,false);t.resolve();await flush();assert.equal(t.nodes.loading.hidden,true,'first frame may precede engine promise resolution');
 t=setup();await t.modules();t.progress(12,0);assert.equal(t.nodes['loading-progress'].value,undefined);t.tick(31000);assert.equal(t.nodes['loading-notice'].hidden,false);
 t=setup(['WebGL2']);await flush();assert.match(t.nodes['loading-status'].textContent,/WebGL2/);assert.equal(t.nodes['loading-retry'].hidden,false);assert.equal(t.nodes.loading.hidden,false);assert.equal(t.starts,0);
 t=setup();await t.moduleFailure();assert.equal(t.starts,0);assert.match(t.nodes['loading-detail'].textContent,/module fetch failed/);assert.equal(t.nodes['loading-retry'].hidden,false);assert.equal(t.nodes.loading.hidden,false);
 t=setup();await t.modules();t.reject();await flush();assert.equal(t.runtime,'rejected');assert.match(t.nodes['loading-detail'].textContent,/engine start failed/);t.frame();assert.equal(t.nodes.loading.hidden,false);
 t=setup();await t.modules();t.resolve();await flush();t.blocked();t.frame();assert.equal(t.nodes.loading.hidden,false,'save blocked must survive first-frame event');assert.match(t.nodes['loading-detail'].textContent,/quarantined/);assert.equal(t.nodes.canvas.focused,undefined);
 t=setup();await t.modules();t.blocked();t.resolve();await flush();t.frame();assert.equal(t.runtime,'rejected','blocked startup cannot unlock Host');assert.equal(t.nodes.loading.hidden,false);
 console.log('Loading shell PASS: module ordering, runtime readiness/rejection, persistentPaths isolation, save-blocked gate, bytes, unknown totals, stall and both first-frame orders');
})().catch(e=>{console.error(e);process.exitCode=1});
