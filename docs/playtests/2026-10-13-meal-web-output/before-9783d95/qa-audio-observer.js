// QA-only output observer, adapted from PR774 94a71da8 nearby-find-audio-observer-oct12.js.
// Existing connect/start calls are forwarded unchanged. No game/save/time/backend access.
(() => {
  'use strict';
  const nativeConnect=AudioNode.prototype.connect, nativeStart=AudioBufferSourceNode.prototype.start;
  const ids=new WeakMap(), buffers=new WeakMap(), taps=new Map(), contexts=new Map();
  let serial=0, bufferSerial=0, recordingWanted=false, session=0, stopped=false, panel;
  const sources=[], failures=[], signal_windows=[], records=[], marks=[];
  const id=n=>{if(!ids.has(n))ids.set(n,++serial);return ids.get(n);};
  const bid=b=>{if(!buffers.has(b))buffers.set(b,++bufferSerial);return buffers.get(b);};
  function startRecorder(c){
    if(c.recorder?.state==='recording')return;
    const mime=MediaRecorder.isTypeSupported('audio/webm;codecs=opus')?'audio/webm;codecs=opus':'audio/webm';
    const chunks=[];
    c.recorder=new MediaRecorder(c.mix.stream,{mimeType:mime,audioBitsPerSecond:128000});
    c.chunks=chunks;c.session=session;c.startedAtMs=performance.now();
    c.recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data);};
    c.recorder.start(500);
  }
  AudioNode.prototype.connect=function(...args){
    const result=Reflect.apply(nativeConnect,this,args);
    try{
      if(args[0]===this.context.destination){
        const output=Number.isInteger(args[1])?args[1]:0;
        const key=id(this)+':'+output;
        if(!taps.has(key)){
          let c=contexts.get(this.context);
          if(!c){c={id:contexts.size+1,context:this.context,mix:this.context.createMediaStreamDestination()};contexts.set(this.context,c);if(recordingWanted)startRecorder(c);}
          const analyser=this.context.createAnalyser();analyser.fftSize=4096;analyser.smoothingTimeConstant=0;
          Reflect.apply(nativeConnect,this,[analyser,output,0]);
          Reflect.apply(nativeConnect,this,[c.mix,output,0]);
          taps.set(key,{id:id(this),output,node:this,analyser,samples:new Float32Array(4096),contextId:c.id});
        }
      }
    }catch(e){failures.push({atMs:performance.now(),phase:'tap',error:String(e)});}
    return result;
  };
  AudioBufferSourceNode.prototype.start=function(...args){
    const result=Reflect.apply(nativeStart,this,args);
    try{
      const b=this.buffer;let shortPeak=null;
      if(b&&b.duration<2){shortPeak=0;for(let c=0;c<b.numberOfChannels;c++)for(const x of b.getChannelData(c))shortPeak=Math.max(shortPeak,Math.abs(x));}
      sources.push({wallMs:performance.now(),node:id(this),context:contexts.get(this.context)?.id??null,contextState:this.context.state,audioTime:this.context.currentTime,buffer:b?bid(b):null,frames:b?.length,channels:b?.numberOfChannels,sampleRate:b?.sampleRate,duration:b?.duration,shortPeak,loop:this.loop,loopStart:this.loopStart,loopEnd:this.loopEnd,startArgs:args});
    }catch(e){failures.push({atMs:performance.now(),phase:'source',error:String(e)});}
    return result;
  };
  function snapshot(){
    const signal=[];
    for(const t of taps.values()){
      t.analyser.getFloatTimeDomainData(t.samples);let sum=0,peak=0,nonFinite=0;
      for(const v of t.samples){if(!Number.isFinite(v)){nonFinite++;continue;}sum+=v*v;peak=Math.max(peak,Math.abs(v));}
      signal.push({node:t.id,output:t.output,context:t.contextId,type:t.node.constructor.name,contextState:t.node.context.state,audioTime:t.node.context.currentTime,sampleRate:t.node.context.sampleRate,rms:Math.sqrt(sum/t.samples.length),peak,nonFinite});
    }
    return {wallMs:performance.now(),signal,sourceCount:sources.length};
  }
  function diagnostics(){return {schema:'youjia.qa.destination-audio/v1',fixture:'audio-check.html; instrumented ordinary entry, not unobserved release or human/hardware hearing',build:document.documentElement.dataset.build,observer:'parallel destination taps; original connect/start forwarded; no game/save/time/backend access',sampleEveryMs:100,windowMs:10000,contexts:[...contexts.values()].map(c=>({id:c.id,state:c.context.state,sampleRate:c.context.sampleRate,recording:c.recorder?.state??'not-started'})),sources,failures,marks,signal_windows,recordings:records.map(r=>({context:r.context,session:r.session,bytes:r.bytes,mime:r.mime,startedAtMs:r.startedAtMs,endedAtMs:r.endedAtMs,filename:r.filename}))};}
  function addLink(blob,name,label){const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=name;a.textContent=label;a.style.cssText='display:block;color:#b7e4ff;margin:5px 0';panel.querySelector('[data-downloads]').append(a);return a;}
  function exportJson(){addLink(new Blob([JSON.stringify(diagnostics(),null,2)],{type:'application/json'}),'qa-audio-diagnostics-'+Date.now()+'.json','下载诊断 JSON（含连续 10 秒窗口）');}
  async function stopRecording(){
    recordingWanted=false;marks.push({atMs:performance.now(),label:'recording stop'});
    for(const c of contexts.values()){
      if(c.recorder?.state==='recording'){
        await new Promise(resolve=>{c.recorder.onstop=resolve;c.recorder.stop();});
        const blob=new Blob(c.chunks,{type:c.recorder.mimeType});
        const filename='qa-audio-context-'+c.id+'-session-'+c.session+'.webm';
        records.push({context:c.id,session:c.session,bytes:blob.size,mime:blob.type,startedAtMs:c.startedAtMs,endedAtMs:performance.now(),filename});
        addLink(blob,filename,'下载 context '+c.id+' 录音（'+blob.size+' B）');
      }
    }
    exportJson();render();
  }
  function render(){if(!panel)return;const s=snapshot();let lines=['build '+document.documentElement.dataset.build,'录音 '+(recordingWanted?'进行中':'未录 / 已结束')+'；source '+sources.length+'；窗口 '+signal_windows.length];
    for(const c of contexts.values())lines.push('Context '+c.id+' '+c.context.state+' '+c.context.sampleRate+' Hz');
    for(const t of s.signal)lines.push('目的端 C'+t.context+' N'+t.node+' RMS '+t.rms.toExponential(3)+' peak '+t.peak.toExponential(3));
    if(!s.signal.length)lines.push('尚未观察到目的端连接');
    lines.push('失败 '+failures.length);panel.querySelector('[data-summary]').textContent=lines.join('\n');
    panel.querySelector('[data-json]').textContent=JSON.stringify({latest:s,sources:sources.slice(-8),marks:marks.slice(-6),failures},null,2);
  }
  function setup(){
    const toggle=document.createElement('button');toggle.textContent='QA 音频 ▾';toggle.style.cssText='position:fixed;z-index:2147483647;left:8px;top:8px;padding:7px 12px;font:14px sans-serif';document.body.append(toggle);
    panel=document.createElement('section');panel.setAttribute('aria-label','QA音频观察');panel.style.cssText='position:fixed;z-index:2147483646;left:8px;top:47px;width:362px;max-height:640px;box-sizing:border-box;overflow:auto;background:rgba(18,23,27,.96);color:#fff;border:1px solid #abc;padding:10px;font:12px/1.4 monospace';
    panel.innerHTML='<strong>仅 QA：当前页面软件音频观察</strong><div>原入口 / 同存档；非人耳或硬件听验</div><div style="display:flex;gap:8px;margin:8px 0"><button data-start>开始录音</button><button data-stop>结束录音</button><button data-export>导出诊断</button></div><div style="display:flex;gap:6px"><input data-label aria-label="观察标签" placeholder="例如 cook / pause / mute" style="width:235px"><button data-mark>记标记</button></div><pre data-summary style="white-space:pre-wrap"></pre><div data-downloads></div><details><summary>诊断 JSON（最近源 / 输出）</summary><pre data-json style="white-space:pre-wrap;word-break:break-all;max-height:230px;overflow:auto"></pre></details>';
    document.body.append(panel);toggle.onclick=()=>{panel.hidden=!panel.hidden;toggle.textContent=panel.hidden?'QA 音频 ▸':'QA 音频 ▾';};
    panel.querySelector('[data-start]').onclick=()=>{if(recordingWanted)return;recordingWanted=true;session++;marks.push({atMs:performance.now(),label:'recording start '+session});for(const c of contexts.values())try{startRecorder(c);}catch(e){failures.push({atMs:performance.now(),phase:'record',error:String(e)});}render();};
    panel.querySelector('[data-stop]').onclick=()=>stopRecording().catch(e=>failures.push({atMs:performance.now(),phase:'stop',error:String(e)}));
    panel.querySelector('[data-export]').onclick=exportJson;
    panel.querySelector('[data-mark]').onclick=()=>{marks.push({atMs:performance.now(),label:panel.querySelector('[data-label]').value.slice(0,120)});render();};
    for(const kind of ['keydown','keyup','pointerdown','pointerup','click','wheel'])panel.addEventListener(kind,e=>e.stopPropagation());
    render();
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',setup,{once:true});else setup();
  const beginning=performance.now();
  setInterval(()=>{if(stopped)return;const row=snapshot();const index=Math.floor((row.wallMs-beginning)/10000);let w=signal_windows.at(-1);if(!w||w.index!==index){w={index,startMs:beginning+index*10000,samples:[]};signal_windows.push(w);}w.samples.push(row);if(signal_windows.length>720){stopped=true;failures.push({atMs:performance.now(),phase:'sampling',error:'2 hour bounded sampler reached; capture stopped'});}render();},100);
})();
