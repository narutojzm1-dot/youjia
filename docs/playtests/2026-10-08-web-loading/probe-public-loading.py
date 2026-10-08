import json, time
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path(__file__).parent / 'loading-070ae5a-public'
OUT.mkdir(exist_ok=True)
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    context = browser.new_context(viewport={'width':1280,'height':720})
    page = context.new_page()
    cdp = context.new_cdp_session(page)
    cdp.send('Network.enable')
    events, requests, errors = [], {}, []
    start = time.monotonic()
    def event(name, data):
        t=round(time.monotonic()-start,3)
        if name == 'request':
            req=data['request']; requests[data['requestId']]={'url':req['url'],'bytes':0}
            events.append({'event':name,'t':t,'id':data['requestId'],'url':req['url']})
        elif name == 'data':
            requests.setdefault(data['requestId'],{}).setdefault('bytes',0)
            requests[data['requestId']]['bytes']+=data['dataLength']
        elif name == 'response':
            r=data['response']; events.append({'event':name,'t':t,'id':data['requestId'],'url':r['url'],'status':r['status'],'headers':r['headers'],'diskCache':r.get('fromDiskCache'),'protocol':r.get('protocol')})
        else:
            events.append({'event':name,'t':t,**data})
    for name, method in [('request','requestWillBeSent'),('response','responseReceived'),('data','dataReceived'),('finished','loadingFinished'),('failed','loadingFailed'),('cache','requestServedFromCache')]:
        cdp.on('Network.'+method,lambda data, n=name:event(n,data))
    page.on('pageerror',lambda error:errors.append(str(error)))
    page.on('console',lambda msg: events.append({'event':'console','t':round(time.monotonic()-start,3),'type':msg.type,'text':msg.text}) if msg.type=='error' else None)
    page.goto('https://narutojzm1-dot.github.io/youjia/',wait_until='domcontentloaded',timeout=45000)
    snapshots=[]
    for run in ['cold','warm']:
        if run == 'warm': page.reload(wait_until='domcontentloaded',timeout=45000)
        run_start=time.monotonic()
        for i in range(17):
            page.wait_for_timeout(10000)
            state=page.evaluate('''() => ({build:document.documentElement.dataset.build, loading:document.querySelector('#loading')?.innerText, hidden:document.querySelector('#loading')?.hidden, timings:window.youjiaLoadTimings, resources:performance.getEntriesByType('resource').filter(r=>/\\.(pck|wasm)$/.test(r.name)).map(r=>({name:r.name,duration:r.duration,transferSize:r.transferSize,encoded:r.encodedBodySize,decoded:r.decodedBodySize}))})''')
            snap={'run':run,'elapsed':round(time.monotonic()-run_start,2),'state':state,'requests':requests.copy()}
            snapshots.append(snap)
            print(json.dumps({'run':run,'elapsed':snap['elapsed'],'state':state,'bytes':{v.get('url','').split('/')[-1]:v.get('bytes') for v in requests.values() if v.get('url','').endswith(('.wasm','.pck'))}},ensure_ascii=False),flush=True)
            (OUT/'probe.json').write_text(json.dumps({'events':events,'snapshots':snapshots,'errors':errors},ensure_ascii=False,indent=2),encoding='utf-8')
            if state['hidden'] or (state.get('timings') or {}).get('startupFailed'):
                page.screenshot(path=str(OUT/(run+'.png')))
                break
        else:
            page.screenshot(path=str(OUT/(run+'-stalled.png')))
            break
    browser.close()
