// Fixed rollout budget, no caller-selected test profiles.
export const PRODUCTION_BUDGET = Object.freeze({sourceBytes:1572864,base64Chars:2097152,
 headChars:4195328,importBytes:3670016,writeBytes:1572864,recordsBytes:33554432});
export function checkBudget(value){if(value!==PRODUCTION_BUDGET)throw Error('invalid budget');return value;}
