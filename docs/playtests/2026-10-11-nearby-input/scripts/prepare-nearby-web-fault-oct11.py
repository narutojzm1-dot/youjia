from pathlib import Path
folder=Path(r'D:\games\youjia-test\assistant-recovery')
s=(folder/'browser-hud734-ordinary-oct11.py').read_text(encoding='utf-8')
s=s.replace('for w,h in [(390,844),(844,390),(1280,720)]:','for mode in ["pickup-abort","return-abort"]:\n        w,h=1280,720')
s=s.replace("folder=root/str(w);folder.mkdir(exist_ok=True);events=[];errors=[];responses=[]","folder=root/mode;folder.mkdir(exist_ok=True);events=[];errors=[];responses=[]")
s=s.replace("page=context.new_page();page.add_init_script(init)",'''page=context.new_page();page.add_init_script(init+"""window.storageFault={enabled:false,events:[]};
const realTransaction=IDBDatabase.prototype.transaction;
IDBDatabase.prototype.transaction=function(...args){const t=realTransaction.apply(this,args);
if(this.name==='youjia-save-host-v1'&&args[1]==='readwrite'&&window.storageFault.enabled){
const event={at:performance.now(),stores:args[0],mode:args[1],attempted:false,aborted:false};storageFault.events.push(event);
queueMicrotask(()=>{event.attempted=true;try{t.abort();event.aborted=true}catch(e){event.failure=String(e)}})}return t;};""")''')
s=s.replace("'inputs':page.evaluate('window.domInputTrace'),'payload':payload()","'inputs':page.evaluate('window.domInputTrace'),'storage_fault':page.evaluate('window.storageFault'),'payload':payload()")
start=s.index('        action(gate_screen(w,h))')
end=s.index('        context.close()',start)
flow='''        baseline=payload().get('keepsakes',{}).copy()
        if mode=='pickup-abort':page.evaluate('window.storageFault.enabled=true')
        action(gate_screen(w,h))
        if mode=='pickup-abort':
            page.wait_for_function('window.storageFault.events.some(e=>e.aborted)',timeout=15000)
            page.wait_for_timeout(1200);snap('pickup-write-aborted')
            assert payload()['keepsakes']==baseline
            assert ((payload().get('exploration') or {}).get('session') or {}).get('carried',[])==[]
            print('FAULT_UI_READY '+mode,flush=True)
            retry=json.loads(input())
            page.evaluate('window.storageFault.enabled=false');action(retry)
        picked=wait_state(lambda v:((v.get('exploration') or {}).get('session') or {}).get('carried')==[offer],'actual pickup commit after retry',timeout=15000)
        page.wait_for_timeout(1200);snap('pickup-confirmed')
        serial=picked['exploration']['session']['trip_serial']
        if mode=='return-abort':page.evaluate('window.storageFault.enabled=true')
        action((w-90,43))
        if mode=='return-abort':
            page.wait_for_function('window.storageFault.events.some(e=>e.aborted)',timeout=15000)
            page.wait_for_timeout(1200);snap('return-write-aborted')
            assert payload()['keepsakes']==baseline
            assert payload()['exploration_committed_serial']<serial
            assert ((payload().get('exploration') or {}).get('session') or {}).get('carried')==[offer]
            print('FAULT_UI_READY '+mode,flush=True)
            retry=json.loads(input())
            page.evaluate('window.storageFault.enabled=false');action(retry)
        expected=dict(baseline);expected[offer]=expected.get(offer,0)+1
        wait_state(lambda v:v['keepsakes']==expected and v['exploration_committed_serial']==serial and (v.get('exploration') or {}).get('session') is None,'actual return grants once after retry',timeout=20000)
        page.wait_for_timeout(700);snap('return-confirmed')
        page.reload();page.wait_for_function('window.first',timeout=90000);page.wait_for_timeout(500);snap('reload-title')
        action(title);page.wait_for_timeout(1400);snap('reload-yard')
        assert payload()['keepsakes']==expected and payload()['exploration_committed_serial']==serial
        assert ((payload().get('exploration') or {}).get('session')) is None
        summaries.append({'diagnostic':'actual IndexedDB transaction abortion in isolated Chrome, not ordinary uninjected proof','mode':mode,'view':[w,h,1],'events':len(events),'gate_trip':trip,'picked':offer,'keepsakes_after_reload':expected,'errors':errors})
'''
s=s[:start]+flow+s[end:]
s=s.replace('HUD734_ORDINARY_WEB_COMPLETE','NEARBY_ACTUAL_WEB_STORAGE_FAULT_COMPLETE')
(folder/'browser-nearby-web-storage-fault-oct11.py').write_text(s,encoding='utf-8')
