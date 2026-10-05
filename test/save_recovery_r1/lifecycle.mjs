// Optional engine/page lifetime gate. Caller supplies engine.startGame() completion,
// not DOMContentLoaded, a timer, or an application-level ready guess.
export class HostLifecycle {
 #ready; #state='new'; #release; #holding;
 constructor(runtimeReady) { this.#ready=Promise.resolve(runtimeReady); }
 get state() { return this.#state; }
 async open(name) {
  if(this.#state!=='new')throw Error('lifecycle already started');
  this.#state='waiting_runtime';
  try {
   await this.#ready;
   if(this.#state!=='waiting_runtime')throw Error('lifecycle closed before runtime ready');
   if(!navigator.locks)throw Error('no_web_locks');
   this.#state='waiting_writer';
   await new Promise((resolve,reject)=>{
    this.#holding=navigator.locks.request(name+':page-writer',{mode:'exclusive',ifAvailable:true},async lock=>{
     if(this.#state!=='waiting_writer'){reject(Error('lifecycle closed before writer ownership'));return;}
     if(!lock){reject(Error('writer_owned_by_another_page'));return;}
     this.#state='ready';
     await new Promise(done=>{this.#release=done;resolve();});
    });
    this.#holding.catch(reject);
   });
  } catch(e) {if(this.#state!=='closed')this.#state='blocked';throw e;}
 }
 assertReady(){if(this.#state!=='ready')throw Error('lifecycle not ready');}
 async close(){this.#state='closed';this.#release?.();await this.#holding;}
}
