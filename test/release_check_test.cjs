const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const code=readFileSync('web/loading.html','utf8').split('// RELEASE_CHECK_BEGIN')[1].split('// RELEASE_CHECK_END')[0].split('\n').slice(1).join('\n');
const ctx={URL,AbortController,setTimeout,clearTimeout,Date};
vm.createContext(ctx);vm.runInContext(code,ctx);
const check=ctx.checkReleaseBeforeBoot;
const current='game-aaaaaaa',next='game-bbbbbbb',url='https://example.test/youjia/';
const manifest=(sha)=>({schema:'youjia.release/v1',sourceCommit:sha.repeat(40),entry:'game-'+sha.repeat(7)});
const fetchResult=(data)=>async (target,opts)=>{
 assert.equal(opts.cache,'no-store');assert.ok(new URL(target).searchParams.has('_check'));
 return {ok:true,json:async()=>data};
};
(async()=>{
 assert.equal((await check(current,url,fetchResult(manifest('a')))).state,'current');
 const update=await check(current,url,fetchResult(manifest('b')));
 assert.equal(update.state,'update');assert.equal(new URL(update.url).searchParams.get('release'),next);
 assert.equal((await check(current,url+'?release='+current+'&_fresh=1',fetchResult(manifest('b')))).state,'update','old bookmarked attempt must check again');
 const forbidden=()=>{throw new Error('Should not fetch again after automatic retry')};
 assert.equal((await check(current,update.url,forbidden)).state,'stale','stale HTML after refresh must stop');
 assert.equal((await check(next,update.url,forbidden)).state,'target','matched target must not bounce back to stale manifest');
 assert.equal((await check(current,url,async()=>{throw Error('offline')})).state,'unknown');
 assert.equal((await check(current,url,async()=>({ok:false}))).state,'unknown');
 assert.equal((await check(current,url,fetchResult({entry:'../../elsewhere'}))).state,'unknown');
 assert.equal((await check(current,url,fetchResult({...manifest('b'),entry:'game-ccccccc'}))).state,'unknown');
 assert.equal((await check(current,url,async(_,{signal})=>new Promise((_,reject)=>signal.addEventListener('abort',()=>reject(Error('timeout')))),5)).state,'unknown');
 console.log('Release check PASS: current, stale cache, bounded redirect, no downgrade loop, offline, invalid manifest and timeout');
})().catch(e=>{console.error(e);process.exitCode=1});
