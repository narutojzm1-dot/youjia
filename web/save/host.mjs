import {inspectSnapshot} from './legacy_inspection.mjs';
import {openStore,envelope,NAMESPACE} from './store.mjs';
import {HostLifecycle} from './lifecycle.mjs';
import {PRODUCTION_BUDGET} from './budgets.mjs';
import {decodeSourceSnapshot} from './source_decode.mjs';
import {prepareLegacyV5} from './legacy_v5.mjs';
let created=false;
const clone=v=>structuredClone(v);
const ID=/^[0-9a-f]{32}$/;
export class SaveHostError extends Error {
 constructor(code,cause){super(code);this.code=code;if(cause)this.cause=String(cause);}
}
function writeId(value){if(typeof value!=='string'||!/^[1-9][0-9]{0,18}$/.test(value)||BigInt(value)>9223372036854775807n)throw new SaveHostError('INVALID_WRITE_ID');}
function business(payload){
 if(typeof payload!=='string')throw new SaveHostError('INVALID_PAYLOAD');
 let value;try{value=JSON.parse(payload);}catch(e){throw new SaveHostError('INVALID_PAYLOAD',e);}
 if(!value||typeof value!=='object'||Array.isArray(value)||value.version!==5)throw new SaveHostError('UNSUPPORTED_PAYLOAD');
}
const trusted=r=>['clean','restored_candidate','restored_parent_intent_rejected'].includes(r.verdict);
// One instance per page/module. No caller-controlled DB, fault hooks or deletion API.
export function createHost({runtimeReady,captureLegacy}={}){
 if(created)throw new SaveHostError('HOST_ALREADY_CREATED');
 if(!runtimeReady||typeof runtimeReady.then!=='function'||typeof captureLegacy!=='function')throw new SaveHostError('INVALID_BOOTSTRAP');
 created=true;
 const lifecycle=new HostLifecycle(runtimeReady);
 let store=null,state='new',preparing=false,pending=null;
 function ready(){lifecycle.assertReady();if(!store||state!=='ready')throw new SaveHostError('HOST_NOT_READY');}
 function owned(requestId,writeIdentity){
  ready();writeId(writeIdentity);
  if(!pending||pending.request_id!==requestId||pending.write_id!==writeIdentity)throw new SaveHostError('STALE_REQUEST');
  return pending;
 }
 function opened(r){
  const result={schema:'youjia.host-open/v1',status:'blocked',code:r.verdict,current_payload:'',current_token:'',current_envelope:null};
  if(r.verdict==='empty'){state='empty';result.status='empty';return result;}
  if(trusted(r)){
   const value=JSON.parse(r.current.payload_bytes);
   if(value?.schema!=='youjia.legacy-v5-import/v1')business(r.current.payload_bytes);
   else if(r.current.generation!=='1'||r.current.schema!=='youjia.save-envelope/v2')throw new SaveHostError('UNSEALED_IMPORT');
   state='ready';return {...result,status:'ready',current_payload:r.current.payload_bytes,current_token:r.current.commit_id,current_envelope:clone(r.current)};
  }
  state='blocked';return result;
 }
 function receipt(e,current,outcome){
  return {schema:'youjia.save-receipt/v2',namespace:NAMESPACE,write_id:e.write_id,request_id:e.request_id,
   store_id:e.candidate.store_id,candidate_token:e.candidate.commit_id,parent_token:e.candidate.parent_commit_id,
   observed_token:current.commit_id,payload_sha256:e.candidate.payload_sha256,generation:e.candidate.generation,
   outcome,transaction_state:outcome==='confirmed'?'complete':'terminated',readback_verified:true,old_write_terminated:true};
 }
 return Object.freeze({
  async open(){
   if(state!=='new')throw new SaveHostError('HOST_ALREADY_OPENED');
   state='opening';
   try{await lifecycle.open(NAMESPACE);store=await openStore();return opened(await store.recover());}
   catch(e){state='blocked';store?.close();store=null;await lifecycle.close();throw new SaveHostError('OPEN_FAILED',e);}
  },
  async initialize(defaultPayload,paths){
   lifecycle.assertReady();if(!store||state!=='empty')throw new SaveHostError('INITIALIZE_REQUIRES_EMPTY');
   business(defaultPayload);const frozenPaths=clone(paths);state='initializing';
   try{
    const snapshot=await captureLegacy({...frozenPaths,budget:PRODUCTION_BUDGET});
    const decoded=decodeSourceSnapshot(snapshot,PRODUCTION_BUDGET);
    const missing=decoded.primary.status==='absent'&&decoded.backup.status==='absent';
    const payload=missing?defaultPayload:prepareLegacyV5(decoded,PRODUCTION_BUDGET);
    await store.initialize(payload,{preserveLegacy:!missing});
    return opened(await store.recover());
   }catch(e){state='blocked';throw new SaveHostError('INITIALIZE_FAILED',e);}
  },
  async prepare(payload,parentToken,writeIdentity){
   ready();writeId(writeIdentity);business(payload);
   if(typeof parentToken!=='string'||!ID.test(parentToken))throw new SaveHostError('INVALID_PARENT');
   if(preparing||(pending&&!pending.done))throw new SaveHostError('WRITE_PENDING');
   preparing=true;
   try{
    const r=await store.recover();
    if(!trusted(r)||r.current.commit_id!==parentToken)throw new SaveHostError('RECOVERY_OR_PARENT_CONFLICT');
    const candidate=await envelope(payload,r.current,PRODUCTION_BUDGET);
    pending={request_id:candidate.request_id,write_id:writeIdentity,candidate,operation:null,started:false,done:false,confirmed:false};
    return {schema:'youjia.save-prepared/v1',namespace:NAMESPACE,store_id:candidate.store_id,write_id:writeIdentity,
     request_id:candidate.request_id,candidate_token:candidate.commit_id,parent_token:candidate.parent_commit_id,
     payload_sha256:candidate.payload_sha256,generation:candidate.generation};
   }finally{preparing=false;}
  },
  async submit(requestId,writeIdentity){
   const e=owned(requestId,writeIdentity);if(e.started)throw new SaveHostError('ALREADY_SUBMITTED');
   e.started=true;e.operation=store.submit(e.candidate);
   try{const current=await e.operation;e.confirmed=true;return receipt(e,current,'confirmed');}
   catch(error){throw new SaveHostError('WRITE_UNKNOWN_RESOLVE_REQUIRED',error);}
  },
  async resolve(requestId,writeIdentity){
   const e=owned(requestId,writeIdentity);if(!e.started)throw new SaveHostError('NOT_SUBMITTED');
   try{await e.operation;}catch(_){}
   const r=await store.recover();
   if(!trusted(r))throw new SaveHostError('RECOVERY_BLOCKED');
   if(r.current.commit_id===e.candidate.commit_id){e.confirmed=true;return receipt(e,r.current,'confirmed');}
   if(r.current.commit_id===e.candidate.parent_commit_id&&!r.present.intent){e.done=true;return receipt(e,r.current,'rejected');}
   throw new SaveHostError('UNRELATED_CURRENT');
  },
  async acknowledge(requestId,writeIdentity){
   const e=owned(requestId,writeIdentity);if(!e.confirmed)throw new SaveHostError('NOT_CONFIRMED');
   const value=await store.acknowledge(e.request_id);e.done=true;
   return {schema:'youjia.save-ack/v1',namespace:NAMESPACE,request_id:e.request_id,write_id:e.write_id,status:value.status};
  },
  async inspectLegacy(paths){
   ready();
   const records=await store.snapshot();
   let snapshot;try{snapshot=await captureLegacy({...clone(paths),budget:PRODUCTION_BUDGET});}
   catch(e){snapshot={primary:{status:'read_error',reason:String(e)},backup:{status:'read_error',reason:String(e)}};}
   return inspectSnapshot(records,snapshot);
  },
  async exportRecovery(paths){
   ready();
   const records=await store.snapshot();
   let snapshot;try{snapshot=await captureLegacy({...clone(paths),budget:PRODUCTION_BUDGET});}
   catch(e){snapshot={primary:{status:'read_error',reason:String(e)},backup:{status:'read_error',reason:String(e)}};}
   const inspection=await inspectSnapshot(records,snapshot);
   return {schema:'youjia.recovery-export/v1',namespace:NAMESPACE,inspection,current_envelope:records.current,legacy_sources:records.legacy_sources??null,legacy_snapshot:snapshot};
  },
  async close(){
   if(preparing||(pending&&!pending.done))throw new SaveHostError('WRITE_PENDING');
   if(['opening','initializing'].includes(state))throw new SaveHostError('BOOT_PENDING');
   state='closed';store?.close();store=null;await lifecycle.close();
  },
 });
}
