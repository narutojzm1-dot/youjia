import {PRODUCTION_BUDGET as budget} from './budgets.mjs';
import {validate,NAMESPACE} from './store.mjs';
import {validLegacySeal} from './legacy_seal.mjs';
const hash=async bytes=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),v=>v.toString(16).padStart(2,'0')).join('');
const empty={status:'absent'};
async function fingerprint(source,baseline=false){
 if(source?.status==='absent'&&Object.keys(source).length===1)return {status:'absent',sha256:'',bytes:0,reason:''};
 try{
  let bytes;
  if(baseline)bytes=new TextEncoder().encode(source.text);
  else{
   if(source?.status!=='present'||Object.keys(source).sort().join(',')!=='base64,status'||typeof source.base64!=='string'||source.base64.length>budget.base64Chars)throw Error(source?.reason||'invalid_source');
   const raw=atob(source.base64);if(btoa(raw)!==source.base64)throw Error('noncanonical_base64');
   bytes=Uint8Array.from(raw,c=>c.charCodeAt(0));
  }
  if(bytes.length>budget.sourceBytes)throw Error('source_too_large');
  return {status:'present',sha256:await hash(bytes),bytes:bytes.length,reason:''};
 }catch(e){return {status:'unavailable',sha256:'',bytes:0,reason:String(e.message||e)};}
}
// Pure readonly snapshot analysis. Never calls recover (which may clean intent).
export async function inspectSnapshot(records,snapshot){
 const current=records.current,seal=records.legacy_sources??null;
 if(!await validate(current,budget))throw Error('invalid_current');
 if(current.schema==='youjia.save-envelope/v2'){
  if(!await validLegacySeal(seal,budget)||seal.store_id!==current.store_id||seal.seal_sha256!==current.legacy_sources_sha256)throw Error('invalid_sealed_binding');
 }else if(seal!==null)throw Error('unexpected_seal');
 const baseline=seal?JSON.parse(seal.import_payload).sources:{primary:empty,backup:empty};
 const validSnapshot=snapshot&&typeof snapshot==='object'&&!Array.isArray(snapshot)&&Object.keys(snapshot).sort().join(',')==='backup,primary';
 const sources={};
 for(const key of ['primary','backup']){
  const now=await fingerprint(validSnapshot?snapshot[key]:null),old=await fingerprint(baseline[key],true);
  const status=now.status==='unavailable'?'unavailable':now.status==='absent'?'absent':old.status==='present'&&now.sha256===old.sha256?'same':'changed';
  sources[key]={status,snapshot_status:now.status,sha256:now.sha256,bytes:now.bytes,baseline_status:old.status,baseline_sha256:old.sha256,baseline_bytes:old.bytes,reason:now.reason};
 }
 const rows=Object.values(sources);
 const status=rows.some(v=>v.status==='unavailable')?'unavailable':rows.every(v=>v.snapshot_status==='absent')?'absent':rows.some(v=>v.status==='changed'||v.snapshot_status==='absent'&&v.baseline_status==='present')?'changed':'same';
 return {schema:'youjia.legacy-inspection/v1',namespace:NAMESPACE,current_token:current.commit_id,baseline:seal?'sealed':'none',status,sources};
}
