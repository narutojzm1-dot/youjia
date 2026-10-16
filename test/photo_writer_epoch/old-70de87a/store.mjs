import {makeLegacySeal, validLegacySeal} from './legacy_seal.mjs';
// Dedicated Host database. Never writes the legacy /userfs IDBFS database.
export const NAMESPACE = 'youjia-save-host-v1';
const SCHEMA = 'youjia.save-envelope/v1';
const SEALED_SCHEMA = 'youjia.save-envelope/v2';
const FIELDS = ['schema', 'store_id', 'commit_id', 'request_id', 'parent_commit_id',
  'generation', 'payload_bytes', 'payload_sha256', 'envelope_sha256'];
const sealedFields = [...FIELDS.slice(0,-1), 'legacy_sources_sha256', 'envelope_sha256'];
const fieldsFor = e => e?.schema === SEALED_SCHEMA ? sealedFields : FIELDS;
const sameOrigin = (a,b) => a.schema === b.schema && a.legacy_sources_sha256 === b.legacy_sources_sha256;
const ID = /^[0-9a-f]{32}$/;
const HASH = /^[0-9a-f]{64}$/;
const MAX_GENERATION = 9223372036854775807n;
import {PRODUCTION_BUDGET, checkBudget} from './budgets.mjs';
const encoder = new TextEncoder();
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const copy = v => structuredClone(v);
export const newId = () => crypto.randomUUID().replaceAll('-', '');
async function sha(bytes) {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))]
    .map(v => v.toString(16).padStart(2, '0')).join('');
}
async function digest(e) {
  const parts = fieldsFor(e).slice(0, -1).map(k => encoder.encode(e[k]));
  const out = new Uint8Array(parts.reduce((n, p) => n + 8 + p.length, 0));
  const view = new DataView(out.buffer);
  let offset = 0;
  for (const p of parts) {
    view.setBigUint64(offset, BigInt(p.length), false);
    offset += 8; out.set(p, offset); offset += p.length;
  }
  return sha(out);
}
export async function validate(e, budget = PRODUCTION_BUDGET) {
  checkBudget(budget);
  if (!e || typeof e !== 'object' || Array.isArray(e) ||
      Object.keys(e).length !== fieldsFor(e).length ||
      !fieldsFor(e).every(k => Object.hasOwn(e, k) && typeof e[k] === 'string')) return false;
  if (![SCHEMA, SEALED_SCHEMA].includes(e.schema) || !ID.test(e.store_id) || !ID.test(e.commit_id) ||
      !ID.test(e.request_id) || !(e.parent_commit_id === '' || ID.test(e.parent_commit_id)) ||
      !/^[1-9][0-9]{0,18}$/.test(e.generation) || BigInt(e.generation) > MAX_GENERATION ||
      !HASH.test(e.payload_sha256) || !HASH.test(e.envelope_sha256)) return false;
  if (e.schema === SEALED_SCHEMA && !HASH.test(e.legacy_sources_sha256)) return false;
  if ((e.generation === '1') !== (e.parent_commit_id === '')) return false;
  const limit = e.generation === '1' ? budget.importBytes : budget.writeBytes;
  if (e.payload_bytes.length > limit || encoder.encode(e.payload_bytes).length > limit) return false;
  try { JSON.parse(e.payload_bytes); } catch (_) { return false; }
  return await sha(encoder.encode(e.payload_bytes)) === e.payload_sha256 &&
    await digest(e) === e.envelope_sha256;
}
export async function envelope(payload, parent = null, budget = PRODUCTION_BUDGET, legacy = null) {
  checkBudget(budget);
  const limit = parent === null ? budget.importBytes : budget.writeBytes;
  if (typeof payload !== 'string' || payload.length > limit || encoder.encode(payload).length > limit) throw Error('bounded frozen JSON text required');
  parent = copy(parent); legacy = copy(legacy);
  if (parent !== null && !await validate(parent, budget)) throw Error('invalid parent');
  const generation = parent ? BigInt(parent.generation) + 1n : 1n;
  if (generation > MAX_GENERATION) throw Error('generation exhausted');
  if (legacy !== null && (parent !== null || !await validLegacySeal(legacy,budget) || legacy.import_payload !== payload)) throw Error('invalid root legacy binding');
  const e = {schema: parent?.schema || (legacy ? SEALED_SCHEMA : SCHEMA), store_id: parent?.store_id || legacy?.store_id || newId(), commit_id: newId(),
    request_id: newId(), parent_commit_id: parent?.commit_id || '', generation: String(generation),
    payload_bytes: payload, payload_sha256: await sha(encoder.encode(payload)), envelope_sha256: ''};
  if (e.schema === SEALED_SCHEMA) e.legacy_sources_sha256 = parent?.legacy_sources_sha256 || legacy.seal_sha256;
  e.envelope_sha256 = await digest(e);
  if (!await validate(e, budget)) throw Error('invalid envelope');
  return e;
}
export async function openStore() {
  const name=NAMESPACE, budget=PRODUCTION_BUDGET;
  // A missing lock service must not create even an empty database.
  if (!navigator.locks) throw Error('no_web_locks');
  const db = await new Promise((resolve, reject) => {
    const r = indexedDB.open(name, 1);
    r.onupgradeneeded = () => r.result.createObjectStore('records');
    r.onsuccess = () => resolve(r.result);
    r.onerror = () => reject(r.error);
    r.onblocked = () => reject(Error('database blocked'));
  });
  db.onversionchange = () => db.close();
  function transact(mode, apply, stage = '') {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('records', mode), s = tx.objectStore('records');
      const values = {present: {}}; let result; let failure;
      tx.oncomplete = () => { resolve(result); };
      tx.onabort = () => { reject(failure || tx.error || Error('aborted')); };
      tx.onerror = () => {}; // Terminal abort is authoritative.
      const keys = ['current', 'intent', 'archive', 'legacy_sources']; let remaining = keys.length * 2;
      const finish = () => {
        if (--remaining) return;
        try { result = apply(values, s, tx); }
        catch (e) { failure = e; try { tx.abort(); } catch (_) { /* Already aborted; terminal handler remains authoritative. */ } }
      };
      for (const key of keys) {
        const r = s.get(key), exists = s.count(key);
        r.onsuccess = () => { values[key] = r.result; finish(); };
        exists.onsuccess = () => { values.present[key] = exists.result === 1; finish(); };
      }
    });
  }
  const snapshot = () => transact('readonly', v => copy(v));
  async function locked(fn) {
    return navigator.locks.request(name, {mode: 'exclusive'}, async () => {
      return await fn();
    });
  }
  async function validIntent(i, states) {
    if (!i || typeof i !== 'object' || Array.isArray(i) ||
      Object.keys(i).sort().join(',') !== 'candidate,parent,request_id,state' ||
      !states.includes(i.state) || !await validate(i.parent, budget) || !await validate(i.candidate, budget)) return false;
    return sameOrigin(i.parent,i.candidate) && i.request_id === i.candidate.request_id &&
      i.candidate.store_id === i.parent.store_id &&
      i.candidate.parent_commit_id === i.parent.commit_id &&
      i.candidate.commit_id !== i.parent.commit_id && i.candidate.request_id !== i.parent.request_id &&
      BigInt(i.candidate.generation) === BigInt(i.parent.generation) + 1n;
  }
  function withinRecords(v) {
    if (budget.recordsBytes === Infinity) return true;
    try { return encoder.encode(JSON.stringify({current:v.current, intent:v.intent, archive:v.archive, legacy_sources:v.legacy_sources})).length <= budget.recordsBytes; }
    catch (_) { return false; }
  }
  async function checked(v) {
    if (!withinRecords(v)) return false;
    if (!v.present.current || !await validate(v.current, budget)) return false;
    if (v.current.schema === SEALED_SCHEMA) {
      if (!v.present.legacy_sources || !await validLegacySeal(v.legacy_sources,budget) || v.legacy_sources.store_id !== v.current.store_id || v.legacy_sources.seal_sha256 !== v.current.legacy_sources_sha256) return false;
    } else if (v.present.legacy_sources) return false;
    if (v.present.archive) {
      if (!Array.isArray(v.archive) || v.archive.length > 32) return false;
      for (const item of v.archive) if (!await validIntent(item, ['rejected']) || !sameOrigin(item.parent,v.current) || item.parent.store_id !== v.current.store_id) return false;
    }
    return !v.present.intent || (await validIntent(v.intent, ['prepared', 'committed']) && sameOrigin(v.intent.parent,v.current) && v.intent.parent.store_id === v.current.store_id);
  }
  async function recoverLocked() {
    const v = await snapshot();
    if (!Object.values(v.present).some(Boolean)) return {verdict: 'empty', ...v};
    if (!await checked(v)) return {verdict: 'quarantined', ...v};
    if (!v.present.intent) return {verdict: 'clean', ...v};
    const i = v.intent;
    if (i.state === 'committed' && same(v.current, i.candidate)) {
      await transact('readwrite', (now, s) => {
        if (!same(now, v)) throw Error('recovery conflict');
        s.delete('intent');
      }, 'cleanup');
      const after = await snapshot();
      if (!same(after.current, v.current) || after.present.intent) throw Error('cleanup readback mismatch');
      return {verdict: 'restored_candidate', ...after};
    }
    if (i.state === 'prepared' && same(v.current, i.parent)) {
      const archive = v.archive || [];
      // Preserve diagnostics; full archive blocks rather than silently evicts.
      if (archive.length >= 32) return {verdict: 'quarantined', ...v};
      const next = [...archive, {...i, state: 'rejected'}];
      if (!withinRecords({...v, archive:next, intent:undefined})) return {verdict:'quarantined', ...v};
      await transact('readwrite', (now, s) => {
        if (!same(now, v)) throw Error('recovery conflict');
        s.put(next, 'archive'); s.delete('intent');
      }, 'reject_intent');
      const after = await snapshot();
      if (!same(after.current, v.current) || after.present.intent || !same(after.archive, next)) throw Error('reject readback mismatch');
      return {verdict: 'restored_parent_intent_rejected', ...after};
    }
    return {verdict: 'quarantined', ...v};
  }
  return {
    snapshot,
    // Explicit initialization only; recovery never auto-creates a root.
    async initialize(payload, {preserveLegacy = false} = {}) {
      return locked(async () => {
        const legacy = preserveLegacy ? await makeLegacySeal(payload,newId(),budget) : null;
        const root = await envelope(payload, null, budget, legacy);
        await transact('readwrite', (v, s, tx) => {
          if (Object.values(v.present).some(Boolean)) throw Error('store not empty');
          if (!withinRecords({current:root, ...(legacy ? {legacy_sources:legacy} : {})})) throw Error('record byte budget exceeded');
          s.put(root, 'current');
          if (legacy) s.put(legacy, 'legacy_sources');
        }, 'initialize');
        const v = await snapshot();
        if (!same(v.current, root) || (legacy && !same(v.legacy_sources,legacy)) || !await checked(v)) throw Error('initial readback mismatch');
        return v.current;
      });
    },
    async recover() {
      return locked(async () => { return await recoverLocked(); });
    },
    // Consumer calls only AFTER accepting the verified business receipt.
    // Cleanup failure does not undo the durable commit or business confirmation.
    async acknowledge(request_id) {
      if (typeof request_id !== 'string' || !ID.test(request_id)) throw Error('invalid request identity');
      return locked(async () => {
        const v = await snapshot();
        if (!await checked(v) || v.current.request_id !== request_id) throw Error('acknowledgement mismatch');
        // Idempotence is limited to the same verified current request.
        if (!v.present.intent) return {status: 'already_clear', request_id};
        if (v.intent.state !== 'committed' || v.intent.request_id !== request_id ||
            !same(v.current, v.intent.candidate)) throw Error('acknowledgement mismatch');
        await transact('readwrite', (now, s) => {
          if (!same(now, v)) throw Error('acknowledgement conflict');
          s.delete('intent');
        }, 'acknowledge');
        const after = await snapshot();
        if (!same(after, {...v, intent: undefined, present: {...v.present, intent: false}}))
          throw Error('acknowledgement readback mismatch');
        return {status: 'cleared', request_id};
      });
    },
    async submit(candidate) {
      // Freeze caller input before the first await; later mutation cannot change a submission.
      candidate = copy(candidate);
      if (!await validate(candidate, budget)) throw Error('invalid candidate');
      return locked(async () => {
        const v = await snapshot();
        if (!await checked(v) || v.present.intent) throw Error('recovery required');
        const parent = v.current;
        if (!sameOrigin(candidate,parent) || candidate.store_id !== parent.store_id || candidate.parent_commit_id !== parent.commit_id ||
            candidate.commit_id === parent.commit_id || candidate.request_id === parent.request_id ||
            BigInt(candidate.generation) !== BigInt(parent.generation) + 1n) throw Error('stale parent');
        const intent = {state: 'prepared', request_id: candidate.request_id, parent, candidate};
        // Reserve both prepared and committed shapes before any target write.
        if (!withinRecords({...v, intent}) || !withinRecords({...v, current:candidate, intent:{...intent,state:'committed'}}))
          throw Error('record byte budget exceeded');
        await transact('readwrite', (now, s, tx) => {
          if (!same(now, v)) throw Error('prepare conflict');
          s.put(intent, 'intent');
        }, 'intent');
        await transact('readwrite', (now, s, tx) => {
          if (!same(now.current, parent) || !same(now.intent, intent)) throw Error('commit conflict');
          s.put(candidate, 'current'); s.put({...intent, state: 'committed'}, 'intent');
        }, 'commit');
        const readback = await snapshot();
        if (!await checked(readback) || !same(readback.current, candidate) ||
            !same(readback.intent, {...intent, state: 'committed'})) throw Error('commit readback mismatch');
        // Return a verified record; business confirmation/de-duplication stays with the consumer.
        return copy(candidate);
      });
    },
    close() { db.close(); },
  };
}
