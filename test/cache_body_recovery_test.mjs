import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {installAssetRecovery} from '../web/boot/download_assets.mjs';
const bytes=Uint8Array.from([0,1,2,3,4,5,6,7]);
const hash=createHash('sha256').update(bytes).digest('hex');
const url='https://example.invalid/game/game-ab.pck';
let count=0;
function fixture(mode, networkMode='ok', pinned=true) {
  const calls=[],retries=[],errors=[],deletes=[];
  let pulls=0;
  const cache={async match(){return new Response(new ReadableStream({
    pull(c){if(pulls++===0)c.enqueue(bytes.slice(0,3));else if(mode==='short')c.close();else if(mode==='error')c.error(new Error('cache body IO'));},
    cancel(){},
  }),{headers:{'x-youjia-asset-size':'8','x-youjia-asset-sha256':hash}})},
  async delete(key){deletes.push(key)},async put(){},async keys(){return []}};
  const original=async(u,init)=>{calls.push({u,init});return networkMode==='ok'?new Response(bytes):new Response(new ReadableStream({start(c){init.signal.addEventListener('abort',()=>c.error(new Error('network idle')),{once:true})}}));};
  const target={fetch:original,caches:{async open(){return cache}},location:{href:url}};
  const restore=installAssetRecovery({fileSizes:{'game-ab.pck':8},...(pinned?{fileHashes:{'game-ab.pck':hash}}:{})},{target,idleMs:15,maxRetries:2,onRetry:e=>retries.push(e),onError:e=>errors.push(String(e))});
  const read=async()=>new Uint8Array(await(await target.fetch('game-ab.pck')).arrayBuffer());
  return {calls,retries,errors,deletes,read,restore};
}
for(const mode of ['idle','short','error']){
 const t=fixture(mode);assert.deepEqual(await t.read(),bytes);assert.equal(t.calls.length,1);assert.equal(t.retries[0].source,'cache');assert.equal(t.retries[0].offset,3);assert.equal(t.deletes.length,1);assert.equal(t.errors.length,0);t.restore();count++;
}
{
 const t=fixture('idle');const read=t.read();await new Promise(r=>setTimeout(r,3));t.restore();await assert.rejects(read,/取消/);assert.equal(t.calls.length,0);assert.equal(t.deletes.length,0);assert.equal(t.errors.length,0);count++;
}
{
 const t=fixture('idle','idle');await assert.rejects(t.read(),/network idle/);assert.equal(t.calls.length,3);assert.equal(t.retries.length,3);assert.equal(t.errors.length,1);t.restore();count++;
}
{
 const t=fixture('idle','ok',false);assert.deepEqual(await t.read(),bytes);assert.equal(t.calls.length,1);assert.equal(t.retries.length,0);assert.equal(t.deletes.length,1);assert.equal(t.errors.length,0);t.restore();count++;
}
console.log(`Cache body recovery PASS: ${count} scenarios (idle/short/IO fallback, cache cancellation, bounded network failure and unpinned cache bypass)`);
