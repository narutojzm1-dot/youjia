// Explicit test profiles only. Candidate values are NOT a production contract.
export const FIXTURE_BUDGET = Object.freeze({sourceBytes:65536, base64Chars:87384,
 headChars:180000, importBytes:65536, writeBytes:65536, recordsBytes:Infinity});
export const CANDIDATE_BUDGET = Object.freeze({sourceBytes:1572864, base64Chars:2097152,
 headChars:4195328, importBytes:3670016, writeBytes:1572864, recordsBytes:33554432});
export function budgetProfile(name = 'fixture') {
 if (name === 'fixture') return FIXTURE_BUDGET;
 if (name === 'candidate-v1') return CANDIDATE_BUDGET;
 throw Error('unknown budget profile');
}
export function checkBudget(budget) {
 if (budget !== FIXTURE_BUDGET && budget !== CANDIDATE_BUDGET) throw Error('explicit budget profile required');
 return budget;
}
export function decodeHeadSnapshot(raw, budget = FIXTURE_BUDGET) {
 checkBudget(budget);
 if (typeof raw !== 'string' || raw.length > budget.headChars) throw Error('legacy snapshot JSON string required');
 return JSON.parse(raw);
}
