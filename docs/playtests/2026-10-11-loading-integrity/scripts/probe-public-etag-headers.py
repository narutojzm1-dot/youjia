import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
OUT=Path(__file__).parent/'loading-public-etag-headers';OUT.mkdir(exist_ok=True)
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
 context=browser.new_context(viewport={'width':1280,'height':720});page=context.new_page();events=[];errors=[];snapshots=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda msg:events.append({'type':msg.type,'text':msg.text}) if msg.type in ['error','info'] else None)
 cdp=context.new_cdp_session(page);cdp.send('Network.enable')
 cdp.on('Network.responseReceived',lambda e:events.append({'network':{k:e['response'].get(k) for k in ['url','status','fromDiskCache','headers']}}) if e['response']['url'].startswith('https:') else None)
 page.goto('https://narutojzm1-dot.github.io/youjia/',wait_until='domcontentloaded',timeout=45000)
 result={'browser':browser.version,'actualPublic':True,'snapshots':snapshots,'events':events,'errors':errors}
 def state():return page.evaluate("({build:document.documentElement.dataset.build,hidden:document.querySelector('#loading').hidden,status:document.querySelector('#loading-status').innerText,detail:document.querySelector('#loading-detail').innerText,timings:window.youjiaLoadTimings})")
 def save(): (OUT/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 for attempt in range(1):
  for i in range(25):
   page.wait_for_timeout(10000);snapshot=state();snapshot.update(attempt=attempt,elapsed=(i+1)*10);snapshots.append(snapshot);save();print(json.dumps(snapshot,ensure_ascii=False),flush=True)
   if snapshot['hidden'] or 'failed' in snapshot['timings']:break
  if snapshot['hidden']:break
  if False:
   page.screenshot(path=str(OUT/'first-failure.png'));page.locator('#loading-retry').click();continue
  page.screenshot(path=str(OUT/'failed-or-timeout.png'));save();browser.close();raise SystemExit(0)
 assert snapshot['build']=='game-7ed6cc0'
 result['cold']=snapshot;page.screenshot(path=str(OUT/'title.png'));page.mouse.click(640,368);page.wait_for_timeout(1800);page.screenshot(path=str(OUT/'yard.png'))
 read='''async()=>{const db=await new Promise((y,n)=>{const r=indexedDB.open('youjia-save-host-v1');r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)});const v=await new Promise((y,n)=>{const r=db.transaction('records','readonly').objectStore('records').get('current');r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)});db.close();return v?.payload_bytes?JSON.parse(v.payload_bytes):null}'''
 result['saveBefore']=page.evaluate(read);assert result['saveBefore'] is not None
 page.reload(wait_until='domcontentloaded');page.wait_for_function("document.querySelector('#loading').hidden",timeout=45000)
 result['warm']=state();assert 'assetCacheHit' in result['warm']['timings'];page.screenshot(path=str(OUT/'warm-title.png'))
 page.mouse.click(640,368);page.wait_for_timeout(1500);result['saveAfter']=page.evaluate(read);assert result['saveBefore']['keepsakes']==result['saveAfter']['keepsakes']
 save();print('WARM '+json.dumps(result['warm'],ensure_ascii=False),flush=True)
 browser.close()
