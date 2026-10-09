import {PRODUCTION_BUDGET as FIXTURE_BUDGET, checkBudget} from './budgets.mjs';

// Read-only legacy boundary. Never mounts IDBFS, creates stores, writes, or deletes.
// A captured pair is one transaction's view, not exclusion of an old page writer.
const DATABASE = '/userfs';
const VERSION = 21;
const STORE = 'FILE_DATA';
const fail = reason => Object.freeze({primary:Object.freeze({status:'read_error',reason}),
 backup:Object.freeze({status:'read_error',reason})});
const absent = () => Object.freeze({status:'absent'});
function validPaths(primary, backup) {
 if (typeof primary !== 'string' || typeof backup !== 'string') return false;
 const suffix = '/youjia_save.json';
 if (!primary.endsWith(suffix)) return false;
 const parent = primary.slice(0, -suffix.length);
 const parts=parent.split('/');
 return parts[0]==='' && parts[1]==='userfs' && parts.slice(1).every(part=>part.length>0 && part!=='.' && part!=='..' && !/[\\\u0000-\u001f\u007f]/.test(part)) && backup === parent+'/youjia_save.bak';
}
function encode(record, key, budget) {
 if (key === undefined) return absent();
 if (!record || Object.getPrototypeOf(record) !== Object.prototype ||
     Object.keys(record).sort().join(',') !== 'contents,mode,timestamp' ||
     !Number.isInteger(record.mode) || record.mode < 0 || record.mode > 65535 || (record.mode & 0xf000) !== 0x8000 ||
     !(record.timestamp instanceof Date) || !Number.isFinite(record.timestamp.getTime()) ||
     !(record.contents instanceof Uint8Array) && !(record.contents instanceof Int8Array)) throw Error('invalid_file_record');
 if (record.contents.byteLength > budget.sourceBytes) throw Error('source_too_large');
 // Copy the structured clone returned by the completed readonly transaction.
 const bytes = new Uint8Array(record.contents.buffer,record.contents.byteOffset,record.contents.byteLength).slice();
 let binary = '';
 for (let i=0; i<bytes.length; i+=8192) binary += String.fromCharCode(...bytes.subarray(i,i+8192));
 const base64 = btoa(binary);
 if (base64.length > budget.base64Chars) throw Error('transport_too_large');
 return Object.freeze({status:'present',base64});
}

export async function captureIdbfsSource(input = {}) {
 if (!input || typeof input!=='object' || Array.isArray(input)) return fail('invalid_input');
 const {primaryPath,backupPath,budget=FIXTURE_BUDGET}=input;
 try { checkBudget(budget); } catch { return fail('unknown_budget_profile'); }
 if (!validPaths(primaryPath,backupPath)) return fail('invalid_globalized_paths');
 if (!globalThis.indexedDB || typeof indexedDB.databases !== 'function') return fail('database_enumeration_unavailable');
 let databases;
 try { databases = await indexedDB.databases(); } catch { return fail('database_enumeration_failed'); }
 const entry = databases.find(item => item.name === DATABASE);
 if (!entry) return Object.freeze({primary:absent(),backup:absent()});
 if (entry.version !== VERSION) return fail('unknown_database_version');
 return new Promise(resolve => {
  let request, db, settled=false, upgrade=false;
  const finish = result => { if (settled) return; settled=true; clearTimeout(timer); if(db) db.close(); resolve(result); };
  const timer=setTimeout(()=>finish(fail('read_timeout')),10000);
  try { request=indexedDB.open(DATABASE); } catch { finish(fail('open_failed')); return; }
  request.onblocked=()=>finish(fail('open_blocked'));
  request.onupgradeneeded=()=>{
   // It disappeared after enumeration. Abort the implicit creation transaction;
   // never delete as cleanup: a concurrent legacy page may recreate its own DB.
   upgrade=true;
   request.transaction.abort();
  };
  request.onerror=async event=>{
   event.preventDefault();
   if (!upgrade) { finish(fail('open_failed')); return; }
   try {
    const remaining=await indexedDB.databases();
    finish(fail(remaining.some(item=>item.name===DATABASE) ? 'creation_race_database_present' : 'database_disappeared_no_creation'));
   } catch { finish(fail('creation_abort_verification_failed')); }
  };
  request.onsuccess=()=>{
   db=request.result;
   if (settled) { db.close(); return; }
   db.onversionchange=()=>{ db.close(); };
   if (db.version!==VERSION || db.objectStoreNames.length!==1 || !db.objectStoreNames.contains(STORE)) {
    finish(fail('unknown_database_schema')); return;
   }
   let tx, records={},keys={},error=null;
   try {
    tx=db.transaction(STORE,'readonly');
    const store=tx.objectStore(STORE);
    if (store.keyPath!==null || store.autoIncrement || store.indexNames.length!==1 || !store.indexNames.contains('timestamp')) throw Error('unknown_store_schema');
    const index=store.index('timestamp');
    if(index.keyPath!=='timestamp' || index.unique || index.multiEntry) throw Error('unknown_index_schema');
    for(const [label,path] of [['primary',primaryPath],['backup',backupPath]]) {
     const value=store.get(path), key=store.getKey(path);
     value.onsuccess=()=>{ records[label]=value.result; };
     key.onsuccess=()=>{ keys[label]=key.result; };
    }
   } catch (cause) { error=cause.message || 'transaction_failed'; if(tx) tx.abort(); else finish(fail(error)); }
   if (!tx) return;
   tx.onabort=()=>finish(fail(error || 'transaction_aborted'));
   tx.onerror=()=>{ error=error || 'transaction_failed'; };
   tx.oncomplete=()=>{
    if(error) { finish(fail(error)); return; }
    try { finish(Object.freeze({primary:encode(records.primary,keys.primary,budget),backup:encode(records.backup,keys.backup,budget)})); }
    catch(cause) { finish(fail(cause.message || 'capture_failed')); }
   };
  };
 });
}
