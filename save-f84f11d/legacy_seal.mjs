// Immutable import evidence. Hashes detect corruption, not malicious re-signing.
const SCHEMA='youjia.legacy-sources/v1';
const FIELDS=['schema','store_id','import_payload','payload_sha256','seal_sha256'];
const ID=/^[0-9a-f]{32}$/,HASH=/^[0-9a-f]{64}$/;
const bytes=s=>new TextEncoder().encode(s);
const sha=async s=>[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes(s)))].map(v=>v.toString(16).padStart(2,'0')).join('');
const sealHash=s=>sha(JSON.stringify(FIELDS.slice(0,-1).map(k=>s[k])));
function importShape(payload,budget){
 try {
  const v=JSON.parse(payload);
  if(!v || Object.keys(v).sort().join(',')!=='schema,selected,sources' || v.schema!=='youjia.legacy-v5-import/v1' || !['primary','backup'].includes(v.selected))return false;
  if(!v.sources || Object.keys(v.sources).sort().join(',')!=='backup,primary')return false;
  for(const s of Object.values(v.sources)){
   if(!s || typeof s!=='object' || Array.isArray(s))return false;
   if(s.status==='absent' && Object.keys(s).length===1)continue;
   if(s.status!=='present'||Object.keys(s).sort().join(',')!=='status,text'||typeof s.text!=='string'||s.text.length>budget.sourceBytes||bytes(s.text).length>budget.sourceBytes)return false;
   let raw;try{raw=JSON.parse(s.text);}catch(_){continue;}
   if(raw && typeof raw==='object' && !Array.isArray(raw) && raw.version!==5)return false;
  }
  const chosen=v.sources[v.selected];if(chosen.status!=='present')return false;
  const raw=JSON.parse(chosen.text);return raw && typeof raw==='object' && !Array.isArray(raw) && raw.version===5;
 }catch(_){return false;}
}
export async function makeLegacySeal(payload,storeId,budget){
 if(typeof payload!=='string'||bytes(payload).length>budget.importBytes||!ID.test(storeId)||!importShape(payload,budget))throw Error('invalid legacy seal input');
 const s={schema:SCHEMA,store_id:storeId,import_payload:payload,payload_sha256:await sha(payload),seal_sha256:''};
 s.seal_sha256=await sealHash(s);return s;
}
export async function validLegacySeal(s,budget){
 if(!s||typeof s!=='object'||Array.isArray(s)||Object.keys(s).length!==FIELDS.length||!FIELDS.every(k=>typeof s[k]==='string'))return false;
 if(s.schema!==SCHEMA||!ID.test(s.store_id)||!HASH.test(s.payload_sha256)||!HASH.test(s.seal_sha256)||s.import_payload.length>budget.importBytes||bytes(s.import_payload).length>budget.importBytes||!importShape(s.import_payload,budget))return false;
 return s.payload_sha256===await sha(s.import_payload)&&s.seal_sha256===await sealHash(s);
}
