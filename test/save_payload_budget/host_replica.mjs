// Offline size model of the pinned R1 Host (6e47c3a legacy_v5/source_decode/store)
// with every fixture cap removed. Used only for candidates the real Host cannot
// accept; bounds_model.py first checks it byte-for-byte against the real modules.
const enc = new TextEncoder();
export const utf8 = s => enc.encode(s).length;
export const decode = bytes => new TextDecoder('utf-8', {fatal: true, ignoreBOM: true}).decode(bytes);

export function classify(text) {
  if (text === null) return 'absent';
  let data;
  try { data = JSON.parse(text); } catch (_) { return 'corrupt'; }
  if (!data || typeof data !== 'object' || Array.isArray(data)) return 'corrupt';
  return data.version === 5 ? 'v5' : 'unsupported';
}

export function legacyPayload(primary, backup) {
  const p = classify(primary), b = classify(backup);
  if (p === 'unsupported' || b === 'unsupported') return {error: 'unsupported legacy version'};
  const selected = p === 'v5' ? 'primary' : b === 'v5' ? 'backup' : null;
  if (!selected) return {error: 'no readable v5 source'};
  const src = t => t === null ? {status: 'absent'} : {status: 'present', text: t};
  return {selected, payload: JSON.stringify({schema: 'youjia.legacy-v5-import/v1', selected,
    sources: {primary: src(primary), backup: src(backup)}})};
}

export function base64(bytes) {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

// Same object shape Godot source_snapshot.gd capture() serializes for head.html.
export function snapshotArg(primaryBytes, backupBytes) {
  const src = b => b === null ? {status: 'absent'} : {base64: b.length ? base64(b) : '', status: 'present'};
  return JSON.stringify({backup: src(backupBytes), primary: src(primaryBytes)});
}

const hex = n => [...crypto.getRandomValues(new Uint8Array(n))].map(v => v.toString(16).padStart(2, '0')).join('');
async function sha(bytes) {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))].map(v => v.toString(16).padStart(2, '0')).join('');
}
const FIELDS = ['schema', 'store_id', 'commit_id', 'request_id', 'parent_commit_id', 'generation',
  'payload_bytes', 'payload_sha256'];
async function digest(e) {
  const parts = FIELDS.map(k => enc.encode(e[k]));
  const out = new Uint8Array(parts.reduce((n, p) => n + 8 + p.length, 0));
  const view = new DataView(out.buffer);
  let offset = 0;
  for (const p of parts) { view.setBigUint64(offset, BigInt(p.length), false); offset += 8; out.set(p, offset); offset += p.length; }
  return sha(out);
}

// store.mjs envelope() without MAX_PAYLOAD or validation.
export async function envelope(payload, parent = null) {
  const e = {schema: 'youjia.save-envelope/v1', store_id: parent?.store_id || hex(16), commit_id: hex(16),
    request_id: hex(16), parent_commit_id: parent?.commit_id || '',
    generation: String(parent ? BigInt(parent.generation) + 1n : 1n),
    payload_bytes: payload, payload_sha256: await sha(enc.encode(payload)), envelope_sha256: ''};
  e.envelope_sha256 = await digest(e);
  return e;
}

// store.mjs submit(): intent {state, request_id, parent, candidate}; recovery
// archives {...intent, state: 'rejected'} so every entry carries both envelopes.
export const intent = (state, parent, candidate) => ({state, request_id: candidate.request_id, parent, candidate});

// json: UTF-8 bytes of JSON.stringify (what store.mjs same()/copy compare).
// strings: UTF-8 bytes of every string leaf. v8: V8 ValueSerializer string
// encoding estimate (1 byte/char if all chars <= U+00FF, else 2 bytes/char).
export function metrics(value) {
  let strings = 0, v8 = 0;
  const walk = v => {
    if (typeof v === 'string') { strings += utf8(v); v8 += /[^\u0000-\u00ff]/.test(v) ? 2 * v.length : v.length; }
    else if (v && typeof v === 'object') for (const k of Object.keys(v)) { strings += utf8(k); v8 += k.length; walk(v[k]); }
  };
  walk(value);
  return {json: utf8(JSON.stringify(value)), strings, v8};
}
