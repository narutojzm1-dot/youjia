const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync('scripts/manus/browser_bgm_backend.gd','utf8').split('const SOURCE = """')[1].split('"""')[0];
let checks=0;const check=(value,label)=>{checks++;assert(value,label);};
function target(){const listeners=new Map();return {listeners,addEventListener(n,f){if(!listeners.has(n))listeners.set(n,new Set());listeners.get(n).add(f);},removeEventListener(n,f){listeners.get(n)?.delete(f);},emit(n,e={}){for(const f of [...(listeners.get(n)||[])])f(e);}};}
function fixture(hidden=false){
 const root=target(),document=Object.assign(target(),{visibilityState:hidden?'hidden':'visible'}),contexts=[];
 class Context {
  constructor(){this.state='running';this.currentTime=0;this.destination={};this.nodes=[];contexts.push(this);}
  advance(dt){if(this.state==='running')this.currentTime+=dt;}
  createGain(){return {gain:{setValueAtTime(){}},connect(){},disconnect(){}};}
  createBuffer(channels,length,sampleRate){const data=Array.from({length:channels},()=>new Float32Array(length));return {length,sampleRate,duration:length/sampleRate,getChannelData:n=>data[n]};}
  createBufferSource(){const n={playbackRate:{value:1,setValueAtTime(){}},connect(){},disconnect(){},start(...args){n.started=args;},stop(){n.stopped=true;}};this.nodes.push(n);return n;}
  suspend(){this.state='suspended';return Promise.resolve();}
  resume(){if(this.deferResume)return new Promise(resolve=>{this.finishResume=()=>{this.state='running';resolve();};});this.state='running';return Promise.resolve();}
  close(){this.state='closed';return Promise.resolve();}
 }
 const sandbox=Object.assign(root,{document,AudioContext:Context,atob:s=>Buffer.from(s,'base64').toString('binary')});vm.runInNewContext(source,sandbox);
 const backend=sandbox.__manusBgm;
 function buffer(key){check(backend.beginBuffer(key,8000,8000),'allocate real backend buffer');check(backend.appendBuffer(key,Buffer.alloc(8000*8).toString('base64'),0),'upload PCM');check(backend.finishBuffer(key,8000),'finish PCM');}
 function visibility(value){document.visibilityState=value?'hidden':'visible';document.emit('visibilitychange');}
 return {root,document,contexts,backend,buffer,visibility};
}
const drain=async()=>{for(let i=0;i<6;i++)await Promise.resolve();};
(async()=>{
 const f=fixture(),b=f.backend,loop=b.createPlayer('loop'),short=b.createPlayer('short');f.buffer('long');f.buffer('short');const c=f.contexts[0];
 check(loop.play('long',.1,true),'start loop');check(short.play('short'),'start one shot');c.advance(.25);const before=loop.position(),nodes=c.nodes.length;
 f.visibility(true);await drain();check(c.state==='suspended','real document hide suspends shared context');check(short.playing()===false,'hide discards an existing one shot');check(loop.playing()===true,'loop ownership retained');c.advance(30);check(Math.abs(loop.position()-before)<1e-8,'background consumes no audio clock');
 check(short.play('short')===true,'hidden short is intentional silence, not fallback failure');check(!short.playing()&&c.nodes.length===nodes,'hidden short neither queues nor allocates a source');check(b.releaseBuffer('short'),'discard releases PCM reference');
 f.visibility(false);await drain();check(c.state==='running','visible resumes existing context');check(Math.abs(loop.position()-before)<1e-8,'restore continues at retained offset');check(!short.playing()&&c.nodes.length===nodes,'return does not replay short or restart long');
 loop.setPaused(true);const paused=loop.position();f.visibility(true);await drain();f.visibility(false);await drain();c.advance(.3);check(loop.position()===paused,'explicit game pause survives visibility cycle');loop.setPaused(false);c.advance(.1);check(Math.abs(loop.position()-paused-.1)<1e-8,'explicit resume still works');
 c.deferResume=true;await c.suspend();b.resumeContext(9);f.visibility(true);c.finishResume();await drain();check(c.state==='suspended','late resume is re-suspended after hide');c.deferResume=false;f.visibility(false);await drain();
 f.root.emit('pagehide',{persisted:true});await drain();check(c.state==='suspended','BFCache suspends');f.visibility(false);await drain();check(c.state==='suspended','visible event cannot override cached page');f.visibility(true);f.root.emit('pageshow',{persisted:true});await drain();check(c.state==='suspended','cached return cannot override still-hidden document');f.visibility(false);await drain();check(c.state==='running','actual visible return resumes after BFCache');
 b.teardown();await drain();check(c.state==='closed','teardown closes context');check(f.document.listeners.get('visibilitychange').size===0,'teardown removes document listener');check([...f.root.listeners.values()].every(s=>s.size===0),'teardown removes page and gesture listeners');check(JSON.parse(b.diagnostics()).buffers===0,'teardown clears buffers');
 const late=b.createPlayer('new');check(f.document.listeners.get('visibilitychange').size===1,'new life installs exactly one visibility listener');late.dispose();b.teardown();
 const h=fixture(true),hl=h.backend.createPlayer('loop'),hs=h.backend.createPlayer('short');h.buffer('pcm');await drain();check(h.contexts[0].state==='suspended','context created in a hidden page stays suspended');check(hl.play('pcm',0,true)&&hs.play('pcm'),'hidden preparation is accepted safely');check(!hs.playing()&&hl.playing(),'initial hidden one shot discarded but loop retained');h.visibility(false);await drain();check(h.contexts[0].state==='running','initial hidden loop can resume on visibility');h.backend.teardown();
 console.log(`BROWSER_BGM_VISIBILITY checks=${checks} failures=0`);
})().catch(e=>{console.error(e);process.exitCode=1;});
