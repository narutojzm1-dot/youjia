import {createHost,SaveHostError} from './host.mjs';
const METHODS=['open','initialize','prepare','submit','resolve','acknowledge','close'];
const COUNTS={open:0,initialize:2,prepare:3,submit:2,resolve:2,acknowledge:2,close:0};
// Install once from the production shell; all callbacks are serialized JSON.
export function installSaveHost({runtimeReady,captureLegacy}){
 if(Object.hasOwn(window,'YoujiaSaveHost'))throw new SaveHostError('BRIDGE_ALREADY_INSTALLED');
 const host=createHost({runtimeReady,captureLegacy});
 const bridge=Object.fromEntries(METHODS.map(method=>[method,(...args)=>{
  const callback=args.pop();if(typeof callback!=='function')throw new SaveHostError('CALLBACK_REQUIRED');
  Promise.resolve().then(()=>{
   if(args.length!==COUNTS[method])throw new SaveHostError('INVALID_ARGUMENT_COUNT');
   if(method==='initialize'){
    if(typeof args[1]!=='string'||args[1].length>8192)throw new SaveHostError('INVALID_PATH_ARGUMENT');
    let paths;try{paths=JSON.parse(args[1]);}catch(_){throw new SaveHostError('INVALID_PATH_ARGUMENT');}
    if(!paths||typeof paths!=='object'||Array.isArray(paths)||Object.keys(paths).sort().join(',')!=='backupPath,primaryPath')throw new SaveHostError('INVALID_PATH_ARGUMENT');
    args[1]=paths;
   }
   return host[method](...args);
  }).then(value=>callback(JSON.stringify(value??{schema:'youjia.save-close/v1',status:'closed'})),error=>callback(JSON.stringify({schema:'youjia.save-error/v1',code:error.code||'HOST_ERROR',cause:error.cause||String(error)})));
 }]));
 Object.defineProperty(window,'YoujiaSaveHost',{value:Object.freeze(bridge),writable:false,configurable:false});
 return window.YoujiaSaveHost;
}
