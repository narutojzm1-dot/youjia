import assert from 'node:assert/strict';
import {installAssetRecovery} from '../web/boot/download_assets.mjs';

const bytes = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7]);
const config = {fileSizes: {'game-ab.pck': bytes.length, 'engine-cd.wasm': bytes.length}};
function fixture(handler, options = {}) {
  const calls = [], retries = [], errors = [];
  const original = async (url, init) => {calls.push({url, init}); return handler(url, init, calls.length);};
  const target = {fetch: original, location: {href: 'https://example.invalid/game/'}, caches: options.caches};
  const restore = installAssetRecovery(config, {target, idleMs: 15, maxRetries: 2,
    onRetry: event => retries.push(event), onError: error => errors.push(error), ...options});
  const read = async name => new Uint8Array(await (await target.fetch(name)).arrayBuffer());
  return {target, original, restore, read, calls, retries, errors};
}
function partial(init, mode = 'idle') {
  return new Response(new ReadableStream({start(output) {
    output.enqueue(bytes.slice(0, 3));
    if (mode === 'eof') output.close();
    else if (mode === 'disconnect') output.error(new Error('disconnected'));
    else init.signal.addEventListener('abort', () => output.error(new Error('idle aborted')), {once: true});
  }}), {headers: {etag: 'W/"abc"'}});
}
function range(start = 3, total = 8, etag = '"abc"') {
  return new Response(bytes.slice(start), {status: 206,
    headers: {'content-range': `bytes ${start}-7/${total}`, etag}});
}
let t = fixture(() => new Response(bytes));
assert.deepEqual(await t.read('game-ab.pck'), bytes);
assert.equal(t.calls.length, 1, 'normal cacheable request is made only once without Range');
assert.equal(t.calls[0].init.headers, undefined);
t.restore(); assert.equal(t.target.fetch, t.original);

for (const mode of ['idle', 'eof']) {
  t = fixture((url, init, count) => count === 1 ? partial(init, mode) : range());
  assert.deepEqual(await t.read('game-ab.pck'), bytes, mode);
  assert.equal(t.retries.length, 1); assert.equal(t.retries[0].offset, 3);
  assert.equal(t.calls[1].init.headers.Range, 'bytes=3-');
  assert.equal(t.errors.length, 0); t.restore();
}
t = fixture((url, init, count) => count === 1 ? partial(init) : new Response(bytes, {headers: {etag: '"abc"'}}));
assert.deepEqual(await t.read('game-ab.pck'), bytes, 'ignored Range must skip the duplicate prefix'); t.restore();

for (const response of [() => range(2), () => range(3, 9), () => range(3, 8, '"changed"'),
  () => new Response(bytes.slice(3), {status: 206, headers: {'content-range':'bytes 3-7/8','content-encoding':'gzip'}})]) {
  t = fixture((url, init, count) => count === 1 ? partial(init, 'eof') : response());
  await assert.rejects(t.read('game-ab.pck'));
  assert.equal(t.calls.length, 2); assert.equal(t.errors.length, 1);
  t.restore();
}
t = fixture(() => new Response(bytes.slice(0, 3)));
await assert.rejects(t.read('game-ab.pck'), /中断/);
assert.equal(t.calls.length, 3, 'retries must be bounded even if Range is ignored');
assert.equal(t.retries.length, 2); assert.equal(t.errors.length, 1); t.restore();

t = fixture(() => new Response(new Uint8Array(9)));
await assert.rejects(t.read('game-ab.pck'), /大小/);
assert.equal(t.calls.length, 1, 'invalid bytes must fail without retrying'); t.restore();

// A header stall must be aborted and retried as well as a stalled body.
t = fixture((url, init, count) => count === 1 ? new Promise((resolve, reject) =>
  init.signal.addEventListener('abort', () => reject(new Error('header idle')), {once:true})) : new Response(bytes));
assert.deepEqual(await t.read('engine-cd.wasm'), bytes); assert.equal(t.retries[0].offset, 0); t.restore();

t = fixture(() => new Response(bytes));
await t.target.fetch('save-ab/bridge.mjs'); await t.target.fetch('game-ab.pck', {method:'HEAD'});
assert.equal(t.calls[0].init, undefined); assert.equal(t.calls[1].init.method, 'HEAD');
assert.equal(t.retries.length, 0); t.restore();
t = fixture((url, init) => partial(init));
const cancelled = t.read('game-ab.pck'); t.restore(); await assert.rejects(cancelled);
assert.equal(t.retries.length, 0); assert.equal(t.errors.length, 0, 'intentional cancel is not a startup failure');
assert.equal(t.target.fetch, t.original);
console.log('Asset recovery PASS: normal request, body/header idle, premature EOF, resume, ignored Range, invalid/changed bytes, bounded failure, cancellation and unrelated fetch isolation');

// Successful recovery must also survive reloads without redownloading a large
// pack. Failed streams must not enter this separate, bounded asset-only cache.
const saved = new Map();
const cache = {async match(url){return saved.get(url)?.clone()}, async delete(key){saved.delete(key.url || key)},
  async keys(){return [...saved.keys()].map(url=>({url}))},
  async put(url,response){const body=await response.arrayBuffer();saved.set(url,new Response(body,{headers:response.headers}));}};
const caches = {async open(name){assert.equal(name,'youjia-startup-assets-v1');return cache}};
t = fixture((url, init, count)=>count === 1 ? partial(init, 'eof') : range(), {caches});
assert.deepEqual(await t.read('game-ab.pck'), bytes);
await new Promise(resolve=>setTimeout(resolve,20));
assert.deepEqual(await t.read('game-ab.pck'), bytes);
assert.equal(t.calls.length,2,'second load uses the completed asset cache');t.restore();
t = fixture(()=>new Response(bytes.slice(0,3)),{caches,maxRetries:0});
await assert.rejects(t.read('engine-cd.wasm'));await new Promise(resolve=>setTimeout(resolve,20));
assert.equal(saved.has('https://example.invalid/game/engine-cd.wasm'),false);t.restore();
for (let i=0;i<7;i++)saved.set('https://example.invalid/game/game-old'+i+'.pck',new Response(bytes));
t = fixture(()=>new Response(bytes),{caches});await t.read('engine-cd.wasm');await new Promise(resolve=>setTimeout(resolve,20));
assert.equal(saved.size,4);assert(saved.has('https://example.invalid/game/game-ab.pck'));t.restore();
t = fixture(()=>new Response(bytes),{caches:{open(){throw Error('storage denied')}}});
assert.deepEqual(await t.read('game-ab.pck'),bytes);assert.equal(t.errors.length,0);t.restore();
t = fixture(()=>new Response(bytes),{caches:{async open(){return {...cache,put(){throw Error('quota')}}}}});
saved.clear();assert.deepEqual(await t.read('game-ab.pck'),bytes);assert.equal(t.errors.length,0);t.restore();
t = fixture(()=>new Response(bytes),{cacheWaitMs:5,caches:{open(){return new Promise(()=>{})}}});
assert.deepEqual(await t.read('game-ab.pck'),bytes);assert.equal(t.errors.length,0);t.restore();
console.log('Asset cache PASS: recovered reload, incomplete rejection, bounded retention, current-build protection and storage-denied fallback');
