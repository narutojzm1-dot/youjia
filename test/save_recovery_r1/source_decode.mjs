import {FIXTURE_BUDGET, checkBudget} from './budgets.mjs';
// Native byte snapshot -> existing raw v5 preservation input, before target initialization writes.
// Production must establish legacy writer quiescence; this adapter grants no lock.
function decodeSource(value, budget) {
 if (!value || typeof value !== 'object' || Array.isArray(value)) throw Error('invalid source');
 if (value.status === 'absent' && Object.keys(value).length === 1) return {status:'absent'};
 if (value.status !== 'present' || Object.keys(value).sort().join(',') !== 'base64,status' ||
     typeof value.base64 !== 'string' || value.base64.length > budget.base64Chars) throw Error('unreadable or oversized source');
 const binary=atob(value.base64);
 if (btoa(binary)!==value.base64 || binary.length>budget.sourceBytes) throw Error('noncanonical or oversized source');
 const raw=Uint8Array.from(binary,c=>c.charCodeAt(0));
 // Fatal decoding refuses damaged bytes rather than substituting replacement
 // characters. Preserve a BOM too; subsequent v5 policy must not silently strip it.
 return {status:'present',text:new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(raw)};
}
export function decodeSourceSnapshot(input, budget = FIXTURE_BUDGET) {
 checkBudget(budget);
 if (!input || typeof input !== 'object' || Array.isArray(input) ||
     Object.keys(input).sort().join(',') !== 'backup,primary') throw Error('two source snapshots required');
 return {primary:decodeSource(input.primary, budget),backup:decodeSource(input.backup, budget)};
}
