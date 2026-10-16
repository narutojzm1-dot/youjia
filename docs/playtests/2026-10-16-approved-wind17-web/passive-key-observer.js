// Passive QA observer: retain original methods, sources and audio samples.
(()=>{
 let api,activeKey=null;
 globalThis.__windKeyAudit={plays:[]};
 const start=AudioBufferSourceNode.prototype.start;
 AudioBufferSourceNode.prototype.start=function(...args){
  const key=activeKey;const result=start.apply(this,args);
  const row=globalThis.__ui704Probe?.sources.at(-1);
  if(row&&key)row.observedRuntimeBufferKey=key;
  return result;
 };
 Object.defineProperty(globalThis,'__manusBgm',{configurable:true,get:()=>api,set:value=>{
  api=value;const create=value.createPlayer;
  value.createPlayer=function(...args){
   const player=create.apply(this,args),play=player.play;
   player.play=function(key,...rest){
    globalThis.__windKeyAudit.plays.push({key:String(key),t:performance.now()});
    const previous=activeKey;activeKey=String(key);
    try{return play.call(this,key,...rest);}finally{activeKey=previous;}
   };
   return player;
  };
 }});
})();
