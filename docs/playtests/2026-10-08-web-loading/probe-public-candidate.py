import json,re,time,urllib.request
from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).parent;REPO=Path(r'D:\games\youjia-test\assistant');OUT=ROOT/'loading-public-candidate-cache';OUT.mkdir(exist_ok=True)
BASE='https://narutojzm1-dot.github.io/youjia/'
with urllib.request.urlopen(BASE,timeout=30) as response:html=response.read().decode()
config=json.loads(re.search(r'const config = (\{.*?\});',html)[1])
script=re.search(r"script.src = '([^']+)'",html)[1]
save=re.search(r"import\('\./(save-[^/]+)/bridge.mjs'",html)[1]
code=re.search(r'<script>([\s\S]*?)</script>',(REPO/'web/loading.html').read_text(encoding='utf-8'))[1]
code=code.replace('$GODOT_CONFIG',json.dumps(config)).replace('$GODOT_THREADS_ENABLED','false').replace('$GODOT_URL',script).replace('./web/save/',f'./{save}/').replace('./web/boot/','./boot-candidate/')
html=re.sub(r'<script>[\s\S]*?</script>',lambda m:'<script>'+code+'</script>',html,count=1)
(OUT/'candidate.html').write_text(html,encoding='utf-8')
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
 context=b.new_context(viewport={'width':1280,'height':720});page=context.new_page();events=[];errors=[];snaps=[]
 page.route(BASE,lambda route:route.fulfill(status=200,content_type='text/html',body=html))
 page.route(BASE+'boot-candidate/download_assets.mjs',lambda route:route.fulfill(status=200,content_type='text/javascript',body=(REPO/'web/boot/download_assets.mjs').read_text(encoding='utf-8')))
 page.on('console',lambda msg:events.append({'type':msg.type,'text':msg.text}))
 page.on('pageerror',lambda e:errors.append(str(e)))
 cdp=context.new_cdp_session(page);cdp.send('Network.enable')
 cdp.on('Network.responseReceived',lambda e:events.append({'response':{k:e['response'].get(k) for k in ['url','status','headers']}}))
 start=time.monotonic();page.goto(BASE,wait_until='domcontentloaded',timeout=45000)
 for i in range(25):
  page.wait_for_timeout(10000)
  snap=page.evaluate("({build:document.documentElement.dataset.build,hidden:document.querySelector('#loading').hidden,status:document.querySelector('#loading-status').innerText,detail:document.querySelector('#loading-detail').innerText,timings:window.youjiaLoadTimings})")
  snap['elapsed']=round(time.monotonic()-start,2);snaps.append(snap)
  result={'candidateOnly':True,'config':config,'browser':b.version,'snapshots':snaps,'events':events,'errors':errors}
  (OUT/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(snap,ensure_ascii=False),flush=True)
  if snap['hidden']:
   page.screenshot(path=str(OUT/'ready-title.png'));page.mouse.click(640,368);page.wait_for_timeout(1800);page.screenshot(path=str(OUT/'yard.png'))
   page.reload(wait_until='domcontentloaded');page.wait_for_function("document.querySelector('#loading').hidden",timeout=45000)
   result['warm']=page.evaluate('window.youjiaLoadTimings');result['events']=events;result['errors']=errors
   page.screenshot(path=str(OUT/'warm-title.png'))
   (OUT/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
   print('WARM '+json.dumps(result['warm']),flush=True)
   assert 'assetCacheHit' in result['warm'];assert not errors
   break
  if 'failed' in snap['timings']:
   page.screenshot(path=str(OUT/'failed.png'));break
 else:page.screenshot(path=str(OUT/'timeout.png'))
 b.close()
