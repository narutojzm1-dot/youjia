// Preservation-first migration candidate, test stores only. No legacy file writes.
import {openStore} from './store.mjs';
const LIMIT = 65536; // Same bounded-fixture limit as R1, not a production import budget.
const bytes = s => new TextEncoder().encode(s).length;
function source(value) {
 if (!value || typeof value !== 'object' || Array.isArray(value)) throw Error('explicit source status required');
 if (value.status === 'absent' && Object.keys(value).length === 1) return {status:'absent'};
 if (value.status !== 'present' || Object.keys(value).sort().join(',') !== 'status,text' || typeof value.text !== 'string')
  throw Error('unreadable or invalid source; do not treat read errors as absent');
 if (value.text.length > LIMIT || bytes(value.text) > LIMIT) throw Error('legacy fixture too large');
 return {status:'present',text:value.text};
}
function classify(s) {
 if (s.status === 'absent') return 'absent';
 let data;
 try { data=JSON.parse(s.text); } catch (_) { return 'corrupt'; }
 if (!data || typeof data !== 'object' || Array.isArray(data)) return 'corrupt';
 // This slice knows v5 only; missing/future versions cannot silently downgrade.
 return data.version === 5 ? 'v5' : 'unsupported';
}
export function prepareLegacyV5(input) {
 if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).sort().join(',') !== 'backup,primary')
  throw Error('primary and backup snapshots required');
 const primary=source(input.primary), backup=source(input.backup);
 const p=classify(primary), b=classify(backup);
 // Even an unsupported backup must be retained for explicit version handling.
 if (p==='unsupported' || b==='unsupported') throw Error('unsupported legacy version');
 const selected=p==='v5'?'primary':b==='v5'?'backup':null;
 if (!selected) throw Error('no readable v5 source');
 // Never serialize the parsed legacy object: whitespace, unknown fields, large
 // integer text, album/moments, relationships and plants remain exactly as read.
 const payload=JSON.stringify({schema:'youjia.legacy-v5-import/v1',selected,sources:{primary,backup}});
 if (bytes(payload)>LIMIT) throw Error('combined legacy fixture too large');
 return payload;
}
export async function importLegacyV5(testName,input) {
 // Freeze/validate before opening the target. No source cleanup API exists here.
 const payload=prepareLegacyV5(input);
 const store=await openStore(testName);
 try {
  // R1 atomically requires all target record keys absent, under its Web Lock.
  // Existing good, corrupt or pending target records are never overwritten.
  const current=await store.initialize(payload);
  return {current,selected:JSON.parse(payload).selected};
 } finally { store.close(); }
}
