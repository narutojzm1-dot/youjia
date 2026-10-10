"""Ordinary browser inputs only. IndexedDB/network are read-only observers."""
import base64, hashlib, json, math, sys, time
from pathlib import Path
from playwright.sync_api import sync_playwright

root = Path(sys.argv[1]); root.mkdir(parents=True,exist_ok=True)
candidate = Path(sys.argv[2]); source = sys.argv[3]; port = sys.argv[4]
url = 'http://127.0.0.1:'+port+'/'
init = """window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true);
window.domInputTrace=[];for(const k of ['pointerdown','pointerup','mousedown','mouseup','keydown','keyup'])
document.addEventListener(k,e=>domInputTrace.push({kind:k,trusted:e.isTrusted,x:e.clientX,y:e.clientY,key:e.key,t:performance.now()}),true);"""
read_payload = """async()=>{if(!(await indexedDB.databases()).some(d=>d.name==='youjia-save-host-v1'))return null;
const db=await new Promise((yes,no)=>{const r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});
const current=await new Promise((yes,no)=>{const r=db.transaction('records','readonly').objectStore('records').get('current');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});db.close();
return current?.payload_bytes?JSON.parse(current.payload_bytes):null}"""

def position(distance):
    points=[(740,845),(850,811),(945,769),(1030,729),(1110,690),(1150,660),(1220,630),(1305,599),(1360,565)]
    for a,b in zip(points,points[1:]):
        length=math.dist(a,b)
        if distance<=length:return (a[0]+(b[0]-a[0])*distance/length,a[1]+(b[1]-a[1])*distance/length)
        distance-=length
    return points[-1]

def gate_screen(w,h):
    foot=position(663)
    zoom=max(min(w/1672,h/941),w/1280,max(100,h-(140 if w<700 else 76))/720)
    visible=(w/zoom,h/zoom)
    def axis(center,size,extent):return extent/2 if size>=extent else max(size/2,min(center,extent-size/2))
    camera=(axis(foot[0],visible[0],1672),axis(foot[1]-visible[1]*.1,visible[1],941))
    return ((1240-camera[0])*zoom+w/2,(668-camera[1])*zoom+h/2)

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,
        args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--disable-http2'])
    summaries=[]
    for w,h in [(390,844),(844,390),(1280,720)]:
        if len(sys.argv)>5 and str(w)!=sys.argv[5]:continue
        folder=root/str(w);folder.mkdir(exist_ok=True);events=[];errors=[];responses=[]
        context=browser.new_context(viewport={'width':w,'height':h},device_scale_factor=2,has_touch=True)
        page=context.new_page();page.add_init_script(init)
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
        cdp=context.new_cdp_session(page);cdp.send('Network.enable',{'maxTotalBufferSize':200000000,'maxResourceBufferSize':100000000})
        cdp.on('Network.responseReceived',lambda e:responses.append(e) if e['response']['url'].endswith(('.pck','.mjs')) else None)
        def payload():return page.evaluate(read_payload)
        def wait_state(predicate,label,timeout=20000):
            stop=time.time()+timeout/1000
            while time.time()<stop:
                value=payload()
                if value and predicate(value):return value
                page.wait_for_timeout(100)
            page.screenshot(path=str(folder/(label.replace(' ','-')+'-timeout.png')),scale='css')
            (folder/'timeout-payload.json').write_text(json.dumps(payload(),ensure_ascii=False,indent=2),encoding='utf-8')
            raise AssertionError(label+' timed out')
        def snap(stage):
            row={'stage':stage,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'errors':errors.copy(),
                'inputs':page.evaluate('window.domInputTrace'),'payload':payload()}
            page.screenshot(path=str(folder/(stage+'.png')),scale='css');events.append(row)
            (folder/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2),encoding='utf-8')
            assert not errors,errors
            print(json.dumps({'view':[w,h],'stage':stage,'keepsakes':row['payload'].get('keepsakes',{}) if row['payload'] else {}},ensure_ascii=False),flush=True)
        def action(xy):
            if w==1280:page.mouse.click(*xy,delay=90)
            else:page.touchscreen.tap(*xy)
        def frame_sample(reduced):
            # Platform preference change exercises the production MotionPreference bridge.
            # rAF timestamps are read-only browser observations, not game debug state.
            page.emulate_media(reduced_motion='reduce' if reduced else 'no-preference')
            page.wait_for_timeout(350)
            values=page.evaluate("""()=>new Promise(resolve=>{const spans=[];let prior=null;
                const tick=t=>{if(prior!==null)spans.push(t-prior);prior=t;
                  if(spans.length===120)resolve(spans);else requestAnimationFrame(tick)};requestAnimationFrame(tick)})""")
            ordered=sorted(values)
            return {'reduced':reduced,'samples':values,'median_ms':ordered[len(ordered)//2],
                    'p95_ms':ordered[int(len(ordered)*.95)-1],'over_50ms':sum(v>50 for v in values)}
        def presentation_probe():
            ordinary=frame_sample(False)
            page.screenshot(path=str(folder/'motion-ordinary.png'),scale='css')
            reduced=frame_sample(True)
            page.screenshot(path=str(folder/'motion-reduced.png'),scale='css')
            page.emulate_media(reduced_motion='no-preference')
            page.wait_for_timeout(350)
            assert not errors,errors
            result={'renderer':'Chrome ANGLE SwiftShader headless, DPR2 emulation, not a physical phone',
                    'viewport':[w,h,2],'ordinary':ordinary,'reduced':reduced,
                    'reduce_media_after_restore':page.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")}
            (folder/'performance.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
            print('MOTION_PERFORMANCE '+json.dumps({k:v for k,v in result.items() if k not in ['ordinary','reduced']} |
                {'ordinary':{k:v for k,v in ordinary.items() if k!='samples'},'reduced':{k:v for k,v in reduced.items() if k!='samples'}}),flush=True)
        def returned():
            action((w-(73 if w<700 else 90),37 if w<700 else 43))
            wait_state(lambda v:(v.get('exploration') or {}).get('session') is None,'return durable cleanup')
            page.wait_for_timeout(700)
        title={390:(194,430),844:(423,195),1280:(640,368)}[w]
        exit_point={390:(76,610),844:(67,300),1280:(128,600)}[w]
        entry_button=(w/2 if w<700 else w-114,h-43)
        page.goto(url)
        try:page.wait_for_function('window.first',timeout=180000)
        except Exception:
            page.screenshot(path=str(folder/'startup-timeout.png'),scale='css')
            (folder/'startup-errors.json').write_text(json.dumps({'errors':errors,'responses':[r['response']['url'] for r in responses]},ensure_ascii=False,indent=2),encoding='utf-8')
            raise
        page.wait_for_timeout(500)
        package={'source':source,'engine':'4.7.2.stable.official.ed1daf0bf','browser':browser.version,'viewport':[w,h,2],'files':{}}
        for r in responses:
            result=cdp.send('Network.getResponseBody',{'requestId':r['requestId']})
            data=base64.b64decode(result['body']) if result.get('base64Encoded') else result['body'].encode()
            name=r['response']['url'].split('/')[-1]
            expected=candidate/('index.pck' if name.endswith('.pck') else 'web/save/'+name)
            assert data==expected.read_bytes(),name+' actual bytes differ'
            package['files'][name]={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
        assert 'index.pck' in package['files']
        (folder/'package.json').write_text(json.dumps(package,indent=2),encoding='utf-8')
        snap('title');action(title);page.wait_for_timeout(1300);snap('yard')
        baseline=payload().get('keepsakes',{}).copy();action(exit_point)
        active=wait_state(lambda v:((v.get('exploration') or {}).get('session') or {}).get('state')=='active','ordinary outing')
        for trip in range(1,7):
            page.wait_for_timeout(700);snap('entry-'+str(trip))
            if trip==1:presentation_probe()
            offer=active['exploration']['session']['offers'].get('gate','')
            if offer:break
            returned();snap('empty-return-'+str(trip));action(entry_button)
            active=wait_state(lambda v:isinstance((v.get('exploration') or {}).get('session'),dict) and v['exploration']['session'].get('state')=='active','next natural outing')
        else:raise AssertionError('six ordinary trips offered no gate find; no seed/state was injected')
        action(gate_screen(w,h))
        picked=wait_state(lambda v:((v.get('exploration') or {}).get('session') or {}).get('carried')==[offer],'automatic ground pickup')
        assert picked['exploration']['session']['taken']=={'gate':offer}
        page.wait_for_timeout(1900);snap('direct-pick')
        free_point={390:(85,570),844:(460,273),1280:(800,550)}[w]
        action(free_point);page.wait_for_timeout(1800);snap('free-ground')
        assert payload()['exploration']['session']['carried']==[offer]
        returned();snap('collected-return')
        expected=dict(baseline);expected[offer]=expected.get(offer,0)+1
        assert payload()['keepsakes']==expected
        # Exercise the formerly leaking HUD gesture and return from it without picking.
        action(entry_button)
        wait_state(lambda v:isinstance((v.get('exploration') or {}).get('session'),dict) and v['exploration']['session'].get('state')=='active','HUD outing')
        page.wait_for_timeout(1700);snap('hud-entry-steady');returned();snap('hud-return')
        assert payload()['keepsakes']==expected
        page.reload();page.wait_for_function('window.first',timeout=180000);page.wait_for_timeout(700);snap('reload-title')
        action(title);page.wait_for_timeout(1400);snap('reload-yard');assert payload()['keepsakes']==expected
        summaries.append({'view':[w,h,2],'events':len(events),'gate_trip':trip,'picked':offer,'keepsakes_after_reload':expected,'errors':errors})
        context.close()
    browser.close()
    (root/'summary.json').write_text(json.dumps(summaries,ensure_ascii=False,indent=2),encoding='utf-8')
    print('NEARBY_WEB_COMPLETE '+json.dumps(summaries,ensure_ascii=False),flush=True)
