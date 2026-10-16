// Local validation observer only. No game commands, saves or audio substitution.
(() => {
  const p = {started:Date.now(),events:[],samples:[],sources:[],contexts:[]};
  Object.defineProperty(globalThis,'__ui704Probe',{get:()=>p});
  const ctxs=new Map(), taps=new Map();
  const connect=AudioNode.prototype.connect;
  AudioNode.prototype.connect=function(...args) {
    const value=connect.apply(this,args);
    if(args[0] instanceof AudioDestinationNode && !taps.has(this)) {
      const analyser=this.context.createAnalyser();analyser.fftSize=2048;
      connect.call(this,analyser);taps.set(this,{analyser,buf:new Float32Array(2048)});
    }
    if(!ctxs.has(this.context)) {
      const context=this.context,id=ctxs.size;ctxs.set(context,id);
      p.contexts.push({id,rate:context.sampleRate,state:context.state});
      context.addEventListener('statechange',()=>p.events.push({t:performance.now(),type:'context',id,state:context.state}));
    }
    return value;
  };
  const start=AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start=function(...args) {
    const b=this.buffer;
    const entry={t:performance.now(),context:ctxs.get(this.context),state:this.context.state,frames:b?.length,channels:b?.numberOfChannels,rate:b?.sampleRate,loop:this.loop,gainConnectionOnly:true};
    p.sources.push(entry);
    if(b){const a=b.getChannelData(0);entry.sourcePeak=a.reduce((v,s)=>Math.max(v,Math.abs(s)),0);crypto.subtle.digest('SHA-256',a.buffer.slice(a.byteOffset,a.byteOffset+a.byteLength)).then(hash=>entry.channel0FloatSha256=Array.from(new Uint8Array(hash),n=>n.toString(16).padStart(2,'0')).join(''));}
    return start.apply(this,args);
  };
  for(const type of ['pointerdown','pointerup','keydown','keyup'])addEventListener(type,e=>p.events.push({t:performance.now(),type,x:e.clientX,y:e.clientY,key:e.key,trusted:e.isTrusted,target:e.target.tagName}),true);
  setInterval(()=>{
    let peak=0,sum=0,n=0;
    for(const {analyser,buf} of taps.values()){analyser.getFloatTimeDomainData(buf);for(const s of buf){peak=Math.max(peak,Math.abs(s));sum+=s*s;n++;}}
    p.samples.push({t:performance.now(),peak,rms:Math.sqrt(sum/(n||1))});
  },20);
  addEventListener('DOMContentLoaded',()=>{
    const panel=document.createElement('div');panel.style='position:fixed;bottom:0;right:0;z-index:99999;background:#fff8ed;color:#433;padding:4px;font:12px sans-serif';
    const mark=document.createElement('button');mark.textContent='记录UI验证片段';
    const status=document.createElement('output');status.id='ui704-status';
    mark.onclick=async()=>{p.events.push({t:performance.now(),type:'manual-mark'});await fetch('/__probe',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});status.textContent='已保存 '+p.sources.length+' 源播放，'+p.samples.length+' 输出采样';};
    const suspend=document.createElement('button');suspend.textContent='测试：挂起音频';suspend.onclick=()=>{for(const context of ctxs.keys())context.suspend();};
    panel.append(mark,suspend,status);document.body.append(panel);
  });
})();
