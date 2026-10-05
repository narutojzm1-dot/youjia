const fs=require('fs'),vm=require('vm'),assert=require('assert');
const src=fs.readFileSync('scripts/platform/motion_preference.gd','utf8').split('const SOURCE := """')[1].split('"""')[0];
let checks=0;function test(ok){assert.ok(ok);checks++;}
function fixture(mode='ok'){
 const listeners={query:new Map(),document:new Map(),window:new Map()}, values=[];
 const target=(name)=>({addEventListener(k,v){listeners[name].set(k,v)},removeEventListener(k,v){if(listeners[name].get(k)===v)listeners[name].delete(k)}});
 const query=Object.assign(target('query'),{matches:true});
 const document=Object.assign(target('document'),{visibilityState:'visible'});
 const window=Object.assign(target('window'),{matchMedia(s){assert.equal(s,'(prefers-reduced-motion: reduce)');if(mode==='throw')throw Error('unavailable');return query}});
 if(mode==='missing')delete window.matchMedia;
 if(mode==='bad')query.matches='true';
 const binding=vm.runInNewContext(src,{window,document});binding.start(v=>values.push(v));
 return{binding,query,document,window,listeners,values};
}
let f=fixture();test(f.values.join()==='true');f.binding.start(()=>{throw Error('duplicate')});test(f.listeners.query.size===1);
f.query.matches=false;f.listeners.query.get('change')();test(f.values.join()==='true,false');
f.query.matches='false';f.listeners.query.get('change')();test(f.values.length===2);
f.query.matches=true;f.document.visibilityState='hidden';f.listeners.document.get('visibilitychange')();test(f.values.length===2);
f.document.visibilityState='visible';f.listeners.document.get('visibilitychange')();test(f.values.at(-1)===true);
f.query.matches=false;f.listeners.window.get('pageshow')();test(f.values.at(-1)===false);
const stale=f.listeners.query.get('change');f.binding.stop();test(Object.values(f.listeners).every(x=>x.size===0));stale();test(f.values.length===4);f.binding.stop();f.binding.start(()=>{});test(f.listeners.query.size===0);
for(const mode of ['missing','throw','bad']){f=fixture(mode);test(f.values.length===0);f.binding.stop();test(Object.values(f.listeners).every(x=>x.size===0));}
f=fixture();const old=f.binding;const replacement=vm.runInNewContext(src,{window:f.window,document:f.document});test(Object.values(f.listeners).every(x=>x.size===0));test(f.window.__YoujiaMotionPreferenceBinding===replacement);old.stop();test(f.window.__YoujiaMotionPreferenceBinding===replacement);replacement.start(v=>f.values.push(v));test(f.listeners.query.size===1);replacement.stop();test(!('__YoujiaMotionPreferenceBinding' in f.window));
console.log('MOTION PREFERENCE JS PASS',checks);
