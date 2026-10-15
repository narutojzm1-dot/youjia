"""Ordinary player input; readonly Host payload; parallel software audio observer."""
from pathlib import Path
import json, math, time, hashlib, base64, traceback
from playwright.sync_api import sync_playwright

root=Path(r'D:\games\youjia-test\assistant-recovery')
out=root/'nearby-find-audio-current347-oct13/web';assert not out.exists();out.mkdir()
export=root/'nearby-find-audio-current347-web-oct13'
candidate=json.loads((export/'candidate-source.json').read_text(encoding='utf-8-sig'))
read_payload="""async()=>{if(!(await indexedDB.databases()).some(d=>d.name==='youjia-save-host-v1'))return null;
const db=await new Promise((yes,no)=>{const r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});
const current=await new Promise((yes,no)=>{const r=db.transaction('records','readonly').objectStore('records').get('current');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});db.close();return current?.payload_bytes?JSON.parse(current.payload_bytes):null}"""
def write(name,value):(out/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def road(d):
    points=[(740,845),(850,811),(945,769),(1030,729),(1110,690),(1150,660),(1220,630),(1305,599),(1360,565)]
    for a,b in zip(points,points[1:]):
        length=math.dist(a,b)
        if d<=length:return (a[0]+(b[0]-a[0])*d/length,a[1]+(b[1]-a[1])*d/length)
        d-=length
    return points[-1]
def gate_screen(width,height):
    foot=road(663);zoom=max(min(width/1672,height/941),width/1280,max(100,height-(140 if width<700 else 76))/720)
    visible=(width/zoom,height/zoom)
    axis=lambda c,v,n:n/2 if v>=n else max(v/2,min(c,n-v/2))
    camera=(axis(foot[0],visible[0],1672),axis(foot[1]-visible[1]*.1,visible[1],941))
    return ((1240-camera[0])*zoom+width/2,(668-camera[1])*zoom+height/2)

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,args=['--use-gl=angle','--use-angle=d3d11'])
    context=browser.new_context(viewport={'width':1280,'height':720},has_touch=True)
    page=context.new_page();errors=[];steps=[];windows=[];resources=[]
    page.add_init_script((root/'nearby-find-audio-observer-oct12.js').read_text(encoding='utf-8'))
    page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true);window.inputTrace=[];for(const k of ['pointerdown','pointerup','keydown','blur','focus','visibilitychange'])window.addEventListener(k,e=>inputTrace.push({kind:k,trusted:e.isTrusted,x:e.clientX,y:e.clientY,key:e.key,visibility:document.visibilityState,t:performance.now()}),true)")
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda e:errors.append(e.text) if e.type=='error' else None)
    cdp=context.new_cdp_session(page);cdp.send('Network.enable',{'maxTotalBufferSize':220000000,'maxResourceBufferSize':120000000})
    cdp.on('Network.responseReceived',lambda e:resources.append(e) if e['response']['url'].endswith(('.pck','.wasm','.js','.mjs')) else None)
    def payload():return page.evaluate(read_payload)
    def audio():return page.evaluate('audioObservation.diagnostics()')
    def count():return len([s for s in audio()['sources'] if abs(s.get('duration',0)-.95)<.002 and not s['loop']])
    def wait(predicate,label,seconds=20):
        end=time.monotonic()+seconds
        while time.monotonic()<end:
            value=payload()
            if value and predicate(value):return value
            page.wait_for_timeout(40)
        raise AssertionError(label+' timed out')
    def shot(stage):
        row={'stage':stage,'audio':audio(),'payload':payload(),'inputs':page.evaluate('inputTrace'),'errors':errors.copy()}
        steps.append(row);write('steps.json',steps);page.screenshot(path=str(out/(stage+'.png')))
        assert not errors and not row['audio']['failures'],row
        print(json.dumps({'stage':stage,'shortStarts':count(),'rms':[s['rms'] for s in row['audio']['signal']]}),flush=True)
    def signal(stage,seconds=1.15):
        rows=[];end=time.monotonic()+seconds
        while time.monotonic()<end:
            rows.append(audio());page.wait_for_timeout(20)
        windows.append({'stage':stage,'rows':rows});write('signal-windows.json',windows)
        return max((s['rms'] for r in rows for s in r['signal']),default=0)
    def enter():
        size=page.viewport_size
        if size['width']==1280:page.mouse.click(128,600,delay=70)
        else:page.touchscreen.tap(size['width']-55,size['height']-40)
        wait(lambda v:((v.get('exploration') or {}).get('session') or {}).get('state')=='active','near entry')
        page.wait_for_timeout(450)
    def returned():
        size=page.viewport_size;page.mouse.click(size['width']-(90 if size['width']>=700 else 73),43,delay=60)
        wait(lambda v:(v.get('exploration') or {}).get('session') is None,'return')
        page.wait_for_timeout(550)
        backend=audio()['backend']
        assert backend['buffers']<=baseline_backend['buffers'] and backend['players']<=baseline_backend['players'] and backend['bytes']<=baseline_backend['bytes'],('pickup cache/player retained beyond current yard baseline',backend,baseline_backend)
    def find_offer():
        for attempt in range(12):
            enter();v=payload();offer=v['exploration']['session']['offers'].get('gate','')
            if offer:return offer
            returned()
        raise AssertionError('no natural gate offer in twelve ordinary trips')
    def pickup(offer,touch=False):
        size=page.viewport_size;x,y=gate_screen(size['width'],size['height'])
        if touch:page.touchscreen.tap(x,y)
        else:page.mouse.click(x,y,delay=60)
        wait(lambda v:((v.get('exploration') or {}).get('session') or {}).get('carried')==[offer],'natural accepted pickup')
        return x,y
    try:
        page.goto('http://127.0.0.1:8798/',wait_until='domcontentloaded');page.wait_for_function('window.first',timeout=120000)
        assert count()==0;shot('title-quiet')
        page.mouse.click(640,368,delay=80);page.wait_for_timeout(2200)
        wait(lambda v:v.get('holiday_day',0)>0,'yard');shot('yard')
        package=[]
        for e in resources:
            name=e['response']['url'].split('8798/',1)[1]
            body=cdp.send('Network.getResponseBody',{'requestId':e['requestId']})
            data=base64.b64decode(body['body']) if body.get('base64Encoded') else body['body'].encode()
            assert data==(export/name).read_bytes(),name
            package.append({'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
        write('package.json',{'candidate':candidate,'browser':browser.version,'files':package,'webgl':page.evaluate("()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,version:g.getParameter(g.VERSION)}}"),'conditions':'Fresh headless profile with default mute-audio. Original audio destination connections forwarded; parallel analysers/recorders only. Ordinary mouse/touch/keyboard input; readonly Host payload. No clock/seed/save/volume/game-state injection.'})
        page.keyboard.press('Escape');page.wait_for_timeout(350)
        page.mouse.click(640,335,delay=60);page.mouse.click(640,469,delay=60);page.wait_for_timeout(700)
        shot('music-environment-off');assert signal('baseline-quiet',.3)<1e-7
        baseline_backend=audio()['backend'].copy();write('baseline-backend.json',baseline_backend)
        page.keyboard.press('Escape');page.wait_for_timeout(300)
        expected=payload().get('keepsakes',{}).copy()
        def retain(offer):expected[offer]=expected.get(offer,0)+1

        offer=find_offer();before=count();x,y=pickup(offer)
        peak=signal('accepted-one-shot');assert count()==before+1 and peak>1e-6,(count(),before,peak)
        shot('accepted-direct-pick');page.mouse.click(x,y,click_count=3,delay=60);page.wait_for_timeout(350)
        assert count()==before+1;shot('repeat-ground-no-second-sound')
        page.mouse.click(800,550,delay=60);page.wait_for_timeout(400);returned();retain(offer)
        assert payload().get('keepsakes',{})==expected;shot('point-ground-and-return')

        offer=find_offer();page.keyboard.press('Escape');page.wait_for_timeout(350)
        page.mouse.click(640,605,delay=60);page.keyboard.press('Escape');page.wait_for_timeout(350)
        before=count();pickup(offer);assert signal('muted-pickup')<1e-7 and count()==before
        shot('muted-pickup-retained');page.keyboard.press('Escape');page.wait_for_timeout(350)
        page.mouse.click(640,605,delay=60);page.keyboard.press('Escape');page.wait_for_timeout(350)
        assert signal('unmute-no-replay',.4)<1e-7 and count()==before
        shot('unmute-no-replay');returned();retain(offer)

        offer=find_offer();before=count();pickup(offer);page.keyboard.press('Escape');page.wait_for_timeout(150)
        assert count()==before+1 and signal('pause-stops-tail',.25)<1e-7
        shot('pause-stops-tail');page.keyboard.press('Escape');page.wait_for_timeout(250)
        assert count()==before+1 and signal('resume-no-replay',.25)<1e-7
        shot('resume-no-replay');returned();retain(offer)

        offer=find_offer();before=count();pickup(offer);other=context.new_page();other.goto('about:blank');other.bring_to_front();page.wait_for_timeout(300)
        shot('other-tab-after-pickup');page.bring_to_front();other.close();page.wait_for_timeout(350)
        assert count()==before+1;shot('tab-return-no-second-start');returned();retain(offer)

        offer=find_offer();before=count();pickup(offer);returned()
        assert count()==before+1 and signal('return-stops-tail',.3)<1e-7
        retain(offer);shot('return-stops-tail');assert payload().get('keepsakes',{})==expected

        page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(350)
        offer=find_offer();before=count();pickup(offer,touch=True)
        peak=signal('portrait-touch-one-shot');assert count()==before+1 and peak>1e-6
        shot('portrait-touch-pick');returned();retain(offer)
        assert payload().get('keepsakes',{})==expected
        recordings=page.evaluate('audioObservation.finishRecordings()')
        for item in recordings:
            data=base64.b64decode(item.pop('base64'));name=f"ordinary-context-{item['context']}.webm";(out/name).write_bytes(data);item.update(path=name,sha256=hashlib.sha256(data).hexdigest())
        write('ordinary-recordings.json',recordings)
        page.reload(wait_until='domcontentloaded');page.wait_for_function('window.first',timeout=120000)
        assert count()==0;shot('reload-title-no-replay')
        page.touchscreen.tap(195,430);page.wait_for_timeout(2000);wait(lambda v:v.get('holiday_day',0)>0,'reload yard')
        assert payload().get('keepsakes',{})==expected and count()==0;shot('reload-preserves-all-finds')
        recordings=page.evaluate('audioObservation.finishRecordings()')
        for item in recordings:
            data=base64.b64decode(item.pop('base64'));name=f"reload-context-{item['context']}.webm";(out/name).write_bytes(data);item.update(path=name,sha256=hashlib.sha256(data).hexdigest())
        write('recordings.json',recordings)
        result={'source':candidate['source'],'states':len(steps),'acceptedPickups':6,'audibleSoftwareStarts':5,'mutedSkipped':1,'keepsakesAfterReload':expected,'errors':errors,'limitations':'Native96 covers low-motion, swap/full/failed/restore and lifecycle policies. Ordinary Web covers direct mouse/touch pickup, repeats, mute/pause/return/reload and another tab. Software audio only; no headphone/speaker perceptual mix, physical phone, OS lock-screen, or current623 regional audio integration claim.'}
        write('summary.json',result);print('NEAR_FIND_AUDIO_WEB_COMPLETE '+json.dumps(result),flush=True)
    except Exception as e:
        write('failure.json',{'error':str(e),'traceback':traceback.format_exc(),'candidate':candidate,'errors':errors,'payload':payload(),'audio':audio()});page.screenshot(path=str(out/'failure.png'));raise
    finally:browser.close()
