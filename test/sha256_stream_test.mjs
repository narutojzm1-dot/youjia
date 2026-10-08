import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {Sha256Stream} from '../web/boot/sha256_stream.mjs';

const vectors = [
  ['', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'],
  ['abc', 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'],
  ['abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq', '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'],
  ['a'.repeat(1000000), 'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0'],
];
for (const [input, expected] of vectors) {
  const bytes = new TextEncoder().encode(input);
  for (const step of [1, 55, 64, 65537]) {
    const hash = new Sha256Stream();
    for (let offset = 0; offset < bytes.length; offset += step) hash.update(bytes.subarray(offset, offset + step));
    assert.equal(hash.digest(), expected);
    assert.throws(() => hash.update(bytes), /finalized/);
    assert.throws(() => hash.digest(), /finalized/);
  }
}
for (const size of [0,1,55,56,57,63,64,65,119,120,127,128,129,4097,65537]) {
  const allocation = Uint8Array.from({length:size+13}, (_,i)=>(i*71+19)%256);
  const bytes = allocation.subarray(7,7+size); // Nonzero underlying byteOffset.
  const expected = createHash('sha256').update(bytes).digest('hex');
  for (const step of [1,3,55,56,63,64,65,1000,65536]) {
    const hash = new Sha256Stream(); hash.update(new Uint8Array());
    for (let offset=0;offset<size;offset+=step) hash.update(bytes.subarray(offset,offset+step));
    assert.equal(hash.digest(),expected,`${size} bytes split at ${step}`);
  }
}
// Exercise the high 32 bits of the bit count with a stream larger than 512 MiB,
// without retaining that file or allocating a second asset-sized buffer.
const block = new Uint8Array(4*1024*1024).fill(0xa7);
const native = createHash('sha256'), hash = new Sha256Stream();
for(let i=0;i<129;i++){native.update(block);hash.update(block);}
assert.equal(hash.digest(),native.digest('hex'));
console.log('SHA-256 PASS: published vectors, padding/chunk/subarray boundaries, >512MiB incremental length and finalized-state guards');
