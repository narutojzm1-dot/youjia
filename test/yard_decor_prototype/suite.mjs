import assert from 'node:assert/strict';import {Decor,spots}from './model.mjs';
const d=new Decor();assert.equal(d.confirm(),false);d.choose(spots[0]);d.cancel();assert.equal(d.placed,null);
d.choose(spots[0]);d.confirm();const original={...d.placed};d.choose(spots[1]);d.cancel();assert.deepEqual(d.placed,original);
d.choose(spots[2]);d.confirm();assert.deepEqual(d.placed,spots[2]);assert.equal(d.id,'fixture:decor:one');
d.choose(spots[0]);d.setMode('free');assert.equal(d.preview,null);assert.deepEqual(d.placed,spots[2]);
for(const p of [null,{x:NaN,y:.7},{x:Infinity,y:.7},{x:.1,y:.7},{x:.5,y:.9}]){assert.equal(d.choose(p),false);assert.deepEqual(d.placed,spots[2]);}
d.choose({x:.44,y:.75});d.confirm();d.remove();assert.equal(d.preview,null);assert.equal(d.placed,null);d.remove();assert.equal(new Decor().placed,null);assert.equal(d.setMode('invalid'),false);console.log('YARD DECOR MODEL PASS');
