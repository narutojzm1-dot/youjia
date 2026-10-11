"""Local candidate: normal UI, readonly payload, diagnostic parallel WebAudio taps.
This measures software audio; it does not prove headphone/speaker listening.
"""
from pathlib import Path
from urllib.parse import urlparse, unquote
import base64, hashlib, json, math, time, traceback
from playwright.sync_api import sync_playwright

r=Path(r'D:\games\youjia-test\assistant-recovery')
out=r/'nearby-audio-web-proof-oct11/long'
out.mkdir(parents=True,exist_ok=True)
export=r/'nearby-audio-combination-web'
candidate=json.loads((export/'candidate-source.json').read_text(encoding='utf-8-sig'))
source=candidate['source']; errors=[]; steps=[]; samples=[]; resources=[]
read_payload="""async()=>{if(!(await indexedDB.databases()).some(d=>d.name==='youjia-save-host-v1'))return null;
const db=await new Promise((yes,no)=>{const r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});
const current=await new Promise((yes,no)=>{const r=db.transaction('records','readonly').objectStore('records').get('current');r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});db.close();
return current?.payload_bytes?JSON.parse(current.payload_bytes):null}"""
def write(name,value): (out/name).write_bytes((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def gate_screen():
    points=[(740,845),(850,811),(945,769),(1030,729),(1110,690),(1150,660),(1220,630),(1305,599),(1360,565)]
    distance=663
    for a,b in zip(points,points[1:]):
        length=math.dist(a,b)
        if distance<=length:
            foot=(a[0]+(b[0]-a[0])*distance/length,a[1]+(b[1]-a[1])*distance/length);break
        distance-=length
    camera=(max(640,min(foot[0],1032)),max(360,min(foot[1]-72,581)))
    return (1240-camera[0]+640,668-camera[1]+360)

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,args=['--use-gl=angle','--use-angle=d3d11','--enable-precise-memory-info'])
    context=browser.new_context(viewport={'width':1280,'height':720},has_touch=True,device_scale_factor=1)
    page=context.new_page()
    page.add_init_script((r/'nearby-web-audio-observer-oct11.js').read_text(encoding='utf-8'))
    page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true);window.inputTrace=[];for(const k of ['pointerdown','pointerup','keydown'])document.addEventListener(k,e=>inputTrace.push({kind:k,trusted:e.isTrusted,x:e.clientX,y:e.clientY,key:e.key,t:performance.now()}),true)")
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda e:errors.append(e.text) if e.type=='error' else None)
    cdp=context.new_cdp_session(page);cdp.send('Network.enable',{'maxTotalBufferSize':220000000,'maxResourceBufferSize':120000000})
    cdp.on('Network.responseReceived',lambda e:resources.append(e) if e['response']['url'].endswith(('.pck','.mjs','.wasm','.js')) else None)
    def payload():return page.evaluate(read_payload)
    def wait(predicate,label,budget=60000):
        deadline=time.monotonic()+budget/1000
        while time.monotonic()<deadline:
            value=payload()
            if value and predicate(value): return value
            page.wait_for_timeout(100)
        raise AssertionError(label+' timed out')
    def audio():return page.evaluate('audioObservation.diagnostics()')
    def snapshot(stage):
        row={'stage':stage,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'audio':audio(),'payload':payload(),'errors':errors.copy(),'inputs':page.evaluate('inputTrace')}
        steps.append(row);write('steps.json',steps)
        page.screenshot(path=str(out/(stage+'.png')))
        write(stage+'-pcm.json',page.evaluate('audioObservation.pcm()'))
        assert not errors,errors
        assert not row['audio']['failures'],row['audio']['failures']
        print(json.dumps({'stage':stage,'backend':row['audio']['backend'],'rms':[v['rms'] for v in row['audio']['signal']]}),flush=True)
        return row
    def signal(wanted,label):
        values=[]
        for _ in range(12):
            v=audio();values.append(v);page.wait_for_timeout(100)
        write(label+'-signal.json',values)
        peaks=[max((s['rms'] for s in v['signal']),default=0) for v in values]
        if wanted: assert max(peaks)>1e-6,(label,peaks)
        else: assert max(peaks)<1e-7,(label,peaks)
    def controls(prefix):
        page.keyboard.press('Escape');page.wait_for_timeout(700);snapshot(prefix+'-pause')
        page.mouse.click(640,335,delay=90);page.wait_for_timeout(1300)
        snapshot(prefix+'-environment-only');signal(True,prefix+'-environment-only')
        page.mouse.click(640,469,delay=90);page.wait_for_timeout(1300)
        snapshot(prefix+'-both-off');signal(False,prefix+'-both-off')
        page.mouse.click(640,335,delay=90);page.wait_for_timeout(1300)
        snapshot(prefix+'-music-only');signal(True,prefix+'-music-only')
        page.mouse.click(640,469,delay=90);page.wait_for_timeout(700)
        page.mouse.click(640,605,delay=90);page.wait_for_timeout(1300)
        snapshot(prefix+'-master-muted');signal(False,prefix+'-master-muted')
        page.mouse.click(640,605,delay=90);page.wait_for_timeout(1300)
        snapshot(prefix+'-restored');signal(True,prefix+'-restored')
        page.keyboard.press('Escape');page.wait_for_timeout(500)
    def enter():
        page.mouse.click(1166,677,delay=90)
        wait(lambda v:((v.get('exploration') or {}).get('session') or {}).get('state')=='active','HUD entry')
        page.wait_for_timeout(1000)
    def returned():
        page.mouse.click(1190,43,delay=90)
        wait(lambda v:(v.get('exploration') or {}).get('session') is None,'return cleanup')
        page.wait_for_timeout(1000)
    def finish_recordings(tag):
        recordings=page.evaluate('audioObservation.finishRecordings()')
        for item in recordings:
            data=base64.b64decode(item.pop('base64'));assert len(data)==item['bytes']
            name=f"{tag}-context-{item['context']}.webm";(out/name).write_bytes(data)
            item.update(path=name,sha256=hashlib.sha256(data).hexdigest())
        write(tag+'-recordings.json',recordings)
        return recordings
    try:
        page.goto('http://127.0.0.1:8797/',wait_until='domcontentloaded');page.wait_for_function('window.first',timeout=120000)
        snapshot('title');page.mouse.click(640,368,delay=90);page.wait_for_timeout(3000)
        wait(lambda v:v.get('holiday_day',0)>0,'yard ready');snapshot('yard-day');signal(True,'yard-day')
        package=[]
        for response in resources:
            name=unquote(urlparse(response['response']['url']).path).lstrip('/')
            original=(export/name).read_bytes()
            body=cdp.send('Network.getResponseBody',{'requestId':response['requestId']})
            actual=base64.b64decode(body['body']) if body.get('base64Encoded') else body['body'].encode()
            assert actual==original,name
            package.append({'path':name,'bytes':len(actual),'sha256':hashlib.sha256(actual).hexdigest()})
        canvas_renderer=page.evaluate("""()=>{const g=document.querySelector('canvas').getContext('webgl2');const e=g?.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,version:g?.getParameter(g.VERSION)}}""")
        write('package.json',{'source':source,'candidate':candidate,'files':package,'browser':browser.version,'webgl':canvas_renderer,'observerSha256':hashlib.sha256((r/'nearby-web-audio-observer-oct11.js').read_bytes()).hexdigest(),'conditions':'Fresh isolated headless Chrome profile; default mute-audio retained. Parallel mono analysers and MediaRecorder streams measure graph software, not hardware audible output. No player/time/weather/seed/storage injection.'})
        controls('day-controls')
        for _ in range(3):
            before=payload()['world_weather']['weather']
            if before=='rain':break
            page.mouse.click(324,677,delay=90)
            wait(lambda v:v['world_weather']['weather']!=before,'normal weather button')
            page.wait_for_timeout(500)
        assert payload()['world_weather']['weather']=='rain'
        snapshot('yard-rain');page.mouse.click(128,600,delay=90)
        wait(lambda v:((v.get('exploration') or {}).get('session') or {}).get('state')=='active','world gate entry')
        page.wait_for_timeout(1000);snapshot('near-rain-day');signal(True,'near-rain-day')
        baseline=payload().get('keepsakes',{}).copy();offer=''
        for trip in range(1,7):
            offer=payload()['exploration']['session']['offers'].get('gate','')
            if offer:break
            returned();enter()
        if offer:
            page.mouse.click(*gate_screen(),delay=90)
            wait(lambda v:((v.get('exploration') or {}).get('session') or {}).get('carried')==[offer],'natural direct pickup')
            page.wait_for_timeout(1900);snapshot('natural-pick')
            page.mouse.click(800,550,delay=90);page.wait_for_timeout(1800);snapshot('point-ground-continue')
            returned();snapshot('collected-return');enter()
        else:snapshot('no-natural-gate-offer-in-six-trips')
        expected=dict(baseline)
        if offer:expected[offer]=expected.get(offer,0)+1
        start=time.monotonic();night_controls=False;returned_during_span=False;last_bucket=-1
        while time.monotonic()-start<700:
            elapsed=time.monotonic()-start
            row={'elapsedSeconds':elapsed,'audio':audio(),'payload':payload(),'errors':errors.copy()};samples.append(row)
            assert not errors and not row['audio']['failures']
            if row['audio']['backend']:
                assert row['audio']['backend']['buffers']<=7 and row['audio']['backend']['players']<=6
                assert row['audio']['backend']['bytes']<=512*1024*1024
            assert all(s['nonFinite']==0 and s['peak']<=1 for s in row['audio']['signal'])
            if not returned_during_span and elapsed>130:
                returned();snapshot('midspan-yard');enter();snapshot('midspan-near');returned_during_span=True
            durable=row['payload'];day=durable.get('holiday_day',1);clock=durable.get('holiday_day_elapsed',0)
            if not night_controls and 350<clock<540:
                snapshot('natural-near-rain-night');controls('night-controls');snapshot('night-controls-resumed');night_controls=True
            bucket=int(elapsed//30)
            if bucket!=last_bucket:
                write('long-samples.json',samples)
                print(json.dumps({'elapsedSeconds':round(elapsed,1),'day':day,'durableDayElapsed':clock,'backend':row['audio']['backend'],'nightControls':night_controls}),flush=True)
                last_bucket=bucket
            page.wait_for_timeout(900)
        write('long-samples.json',samples);snapshot('long-complete')
        assert night_controls,'Natural nighttime controls not reached'
        assert any(abs(s['duration']-76.8)<.01 for s in audio()['sources']),'No actual near music source'
        assert any(abs(s['duration']-64)<.01 for s in audio()['sources']),'No actual night music/environment source'
        recordings=finish_recordings('long')
        returned();snapshot('final-return');assert payload().get('keepsakes',{})==expected
        page.reload(wait_until='domcontentloaded');page.wait_for_function('window.first',timeout=120000)
        snapshot('reload-title');page.mouse.click(640,368,delay=90);page.wait_for_timeout(2500)
        snapshot('reload-yard');assert payload().get('keepsakes',{})==expected;signal(True,'reload-yard')
        finish_recordings('reload')
        result={'source':source,'states':len(steps),'longSpanSeconds':samples[-1]['elapsedSeconds'],'samples':len(samples),'naturalPicked':offer,'keepsakesAfterReload':payload().get('keepsakes',{}),'nightControls':night_controls,'errors':errors,'recordings':recordings,'limitations':'Diagnostic WebAudio graph capture and normal UI; default headless mute-audio. Includes deliberate muted control segments, not uninterrupted10-minute listening. No headphone/speaker quality, actual hardware, full browser-process/GPU memory, phone or background lifecycle claim.'}
        write('summary.json',result);print('NEAR_AUDIO_LONG_WEB_COMPLETE '+json.dumps({k:v for k,v in result.items() if k!='recordings'}),flush=True)
    except Exception as e:
        write('failure.json',{'error':str(e),'traceback':traceback.format_exc(),'source':source,'errors':errors,'lastAudio':audio(),'payload':payload()})
        page.screenshot(path=str(out/'failure.png'))
        try:finish_recordings('failure')
        except Exception:pass
        raise
    finally:browser.close()
