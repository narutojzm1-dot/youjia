// Isolated Godot test adapter; never installed in the production game.
import {openStore, envelope, newId} from './store.mjs';
const page_id = newId(), log = [], candidates = new Map();
const barriers = ['intent_prepared_complete', 'candidate_committed_before_receipt'];
const injections = ['abort_intent','abort_commit','drop_receipt','wrong_receipt_identity','duplicate_receipt','delay_receipt'];
let store, name, recovery = false, armed = '', paused = null, fault = {}, sequence = 0;
let request = null, preparing = false;
const clone = value => structuredClone(value);
function event(type, details = {}) { log.push({...details, type, page_id, request_id: details.request_id ?? request, sequence: ++sequence}); }
function trusted(r) { return ['clean','restored_candidate','restored_parent_intent_rejected'].includes(r.verdict); }
function opened(r) {
 recovery = clone(r);
 return {verdict:r.verdict, ...(trusted(r) ? {current_payload:r.current.payload_bytes, current_token:r.current.commit_id} : {})};
}
function entry(id) {
 const e = candidates.get(id);
 if (!e) throw Error('unknown request');
 return e;
}
function writeIdentity(id) {
 if (typeof id !== 'string' || !/^[1-9][0-9]{0,18}$/.test(id) || BigInt(id)>9223372036854775807n) throw Error('invalid write identity');
}
function receipt(e, write_id, r, terminated) {
 return {schema:'youjia.save-receipt/v1', write_id,
 candidate_token:e.candidate.commit_id, parent_token:e.candidate.parent_commit_id,
 observed_token:r.current.commit_id, old_write_terminated:terminated};
}
export const bridge = {
 async open(testName) {
  if (name) throw Error('already opened');
  if (!/^youjia-recovery-test-[a-zA-Z0-9-]{1,100}$/.test(testName)) throw Error('test namespace required');
  name = testName;
  if (!navigator.locks) return opened({verdict:'no_web_locks'});
  store = await openStore(name, {
   event:e => event(e.type,e),
   barrier:async (stage, request_id) => {
    if (armed !== stage) return;
    armed = ''; paused = {name:stage, request_id, page_id}; event('barrier_paused',paused);
    // Only closing this page releases the crash-test barrier and Web Lock.
    await new Promise(() => {});
   },
  });
  return opened(await store.recover());
 },
 async initialize(payload) {
  if (!store) throw Error('store unavailable');
  await store.initialize(payload);
  return opened(await store.recover());
 },
 async prepare(payload, parent_token) {
  if (!store || !trusted(recovery)) throw Error('no trusted current');
  // One Godot write at a time. An acknowledged request may be superseded.
  if (preparing || [...candidates.values()].some(e => !e.done)) throw Error('write pending');
  preparing = true;
  try {
  const s = await store.snapshot();
  if (s.present.intent || s.current?.commit_id !== parent_token) throw Error('recovery required or stale parent');
  const candidate = await envelope(payload, s.current);
  candidates.clear();
  candidates.set(candidate.request_id,{candidate, started:false, done:false, operation:null, write_id:null});
  return {candidate_token:candidate.commit_id, request_id:candidate.request_id};
  } finally { preparing = false; }
 },
 async submit(id, write_id) {
  writeIdentity(write_id);
  const e = entry(id);
  if (e.started) throw Error('request already submitted');
  e.started = true; e.write_id = write_id;
  request = id;
  const injection = fault; fault = {};
  e.operation = store.submit(e.candidate,{abort_stage:injection.abort_stage || ''});
  let current;
  try { current = await e.operation; } finally { request = null; }
  const value = receipt(e,write_id,{current},true);
  // Callback faults affect delivery only, after actual durable write/readback.
  if (injection.drop_receipt) {
   event('receipt_dropped',{request_id:id});
   return await new Promise(() => {});
  }
  if (injection.receipt_identity === 'wrong') value.candidate_token = newId();
  if (injection.delay_receipt_ms) await new Promise(resolve=>setTimeout(resolve,injection.delay_receipt_ms));
  event('receipt_delivered',{request_id:id});
  // Duplicate callback is implemented by the head adapter, not a second write.
  return injection.duplicate_receipt ? {__duplicate_test_receipt:value} : value;
 },
 async resolve(id, write_id) {
  writeIdentity(write_id); const e = entry(id);
  if (!e.started || e.write_id !== write_id) throw Error('resolution identity mismatch');
  // Do not claim parent/termination while an earlier write might still complete.
  try { await e.operation; } catch (_) {}
  request = id;
  let r;
  try { r = await store.recover(); } finally { request = null; }
  if (!trusted(r)) throw Error('recovery has no trusted current');
  recovery = clone(r);
  const observed = r.current.commit_id;
  if (![e.candidate.commit_id,e.candidate.parent_commit_id].includes(observed)) throw Error('unrelated recovered commit');
  if (observed === e.candidate.parent_commit_id && !r.present.intent) e.done = true;
  return receipt(e,write_id,r,!r.present.intent);
 },
 async acknowledge(id) {
  const e = entry(id);
  if (!e.started) throw Error('request not submitted');
  request = id;
  try { const r = await store.acknowledge(id); e.done = true; return r; }
  finally { request = null; }
 },
};
window.YoujiaRecoveryProbe = {
 schema:'youjia.recovery-probe/v1',
 capabilities:()=>({web_locks:!!navigator.locks,indexeddb:!!window.indexedDB,barriers:[...barriers],injections:[...injections]}),
 arm(stage) { if (!barriers.includes(stage) || paused) throw Error('invalid barrier'); armed=stage; },
 get paused() { return clone(paused); },
 inject(options) {
  const allowed=['abort_stage','drop_receipt','receipt_identity','duplicate_receipt','delay_receipt_ms'];
  if (!options || Object.keys(options).some(k=>!allowed.includes(k))) throw Error('invalid injection');
  if (options.abort_stage && !['intent','commit'].includes(options.abort_stage)) throw Error('invalid abort stage');
  if (options.delay_receipt_ms !== undefined && (!Number.isInteger(options.delay_receipt_ms) || options.delay_receipt_ms<0 || options.delay_receipt_ms>10000)) throw Error('invalid delay');
  fault=clone(options);
 },
 recovery:()=>clone(recovery),
 events:()=>clone(log),
 async snapshot() { if (!store) throw Error('store unavailable'); return await store.snapshot(); },
 async cleanup() {
  if (!name || !store || paused) throw Error('cleanup unavailable');
  store.close(); store=null;
  await new Promise((resolve,reject)=>{const r=indexedDB.deleteDatabase(name);r.onsuccess=resolve;r.onerror=()=>reject(r.error);r.onblocked=()=>reject(Error('cleanup blocked: close participating pages'));});
 },
};
