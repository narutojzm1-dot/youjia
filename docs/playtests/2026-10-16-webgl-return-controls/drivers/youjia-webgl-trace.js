// Diagnostic observer only. Preserve every WebGL call and return value;
// no gl.getError(), buffer substitution, catch-and-hide or game commands.
(()=>{
 const p=globalThis.__glTargetTrace={conflicts:[],count:0,created:0,deleted:0};
 const ids=new WeakMap();
 const proto=WebGL2RenderingContext.prototype;
 const create=proto.createBuffer,bind=proto.bindBuffer,remove=proto.deleteBuffer;
 proto.createBuffer=function(...args){const b=create.apply(this,args);if(b)ids.set(b,{id:++p.created,first:null,deleted:false});return b;};
 proto.bindBuffer=function(target,buffer){
   if(buffer){let b=ids.get(buffer);if(!b){b={id:++p.created,first:null,deleted:false};ids.set(buffer,b);}
     if(b.first===null&&target!==36662&&target!==36663){b.first=target;if(target===34963)b.firstStack=new Error().stack;}
     const conflict=b.first===34963&&target!==34963&&target!==36662&&target!==36663;
     if(conflict){p.count++;if(p.conflicts.length<40)p.conflicts.push({t:performance.now(),target,emscriptenName:buffer.name,...b,stack:new Error().stack});}
   }
   return bind.call(this,target,buffer);
 };
 proto.deleteBuffer=function(buffer){const b=buffer&&ids.get(buffer);if(b){b.deleted=true;b.deletedAt=performance.now();p.deleted++;}return remove.call(this,buffer);};
})();
