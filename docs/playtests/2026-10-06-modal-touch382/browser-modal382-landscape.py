import base64,hashlib,json,sys,time
from pathlib import Path
from urllib.parse import urlparse,urljoin
from playwright.sync_api import sync_playwright
url,folder,source=sys.argv[1:4]
out=Path(folder);out.mkdir(parents=True,exist_ok=True)
raw=(Path(__file__).parent/'browser-local.py').read_text()
init=raw.split('init="""',1)[1].split('"""',1)[0]
init=init.replace('kind:k,trusted:e.isTrusted,','kind:k,trusted:e.isTrusted,pointerId:e.pointerId,primary:e.isPrimary,')
events=[];proof=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,3)]:
  b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--disable-http2'])
  pg=b.new_page(viewport={'width':w,'height':h},device_scale_factor=dpr,has_touch=True)
  pg.add_init_script(init);errors=[];responses=[]
  pg.on('pageerror',lambda e:errors.append(str(e)))
  pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  cdp=pg.context.new_cdp_session(pg)
  cdp.send('Network.enable',{'maxTotalBufferSize':200000000,'maxResourceBufferSize':100000000})
  cdp.on('Network.responseReceived',lambda e:responses.append(e) if urlparse(e['response']['url']).path.endswith('.pck') else None)
  public=url.startswith('https:')
  manifest=pg.request.get(urljoin(url,'game-release.json')).json() if public else None
  if public:assert manifest['sourceCommit']==source
  pg.goto(url);pg.wait_for_function('window.first',timeout=600000)
  packages=[]
  for e in responses:
   body=cdp.send('Network.getResponseBody',{'requestId':e['requestId']})
   data=base64.b64decode(body['body']) if body['base64Encoded'] else body['body'].encode()
   packages.append({'url':e['response']['url'],'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
  assert packages
  build=pg.locator('html').get_attribute('data-build')
  if public:assert build==manifest['entry']
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(350);pg.keyboard.press('Escape');pg.wait_for_timeout(8500)
  if w==844:resume=(257,134);leave=(257,222);cancel=(422,263);accept=(422,207);music=(587,194)
  else:
   dy=(h-844)/2;resume=(w/2,228+dy);leave=(w/2,340+dy);cancel=(w/2,490+dy);accept=(w/2,434+dy);music=(w/2,481+dy)
  last=0
  def snap(stage):
   global last
   state=pg.evaluate('({backend:JSON.parse(__manusBgm.diagnostics()),gains:audioSources.filter(o=>o.active&&o.gain).map(o=>o.gain.gain.value),inputs:domInputTrace})')
   state['inputs']=state['inputs'][last:];last=pg.evaluate('domInputTrace.length')
   name=f'{w}-{h}-{stage}.png';pg.screenshot(path=str(out/name),scale='css')
   state.update({'view':[w,h,dpr],'actual_viewport':pg.viewport_size,'stage':stage,'screenshot':name,'build':build,'source':source,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'errors':errors.copy()})
   events.append(state);(out/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2),encoding='utf-8')
   assert not errors,errors
   return state['gains']
  initial=snap('pause-initial')
  def unchanged(stage):
   actual=snap(stage)
   assert len(actual)==len(initial) and all(abs(a-e)<0.000001 for a,e in zip(actual,initial)),(stage,actual,initial)
  def tap(point):pg.touchscreen.tap(*point);pg.wait_for_timeout(650)
  def start(point):cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':point[0],'y':point[1]}]})
  def end():cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});pg.wait_for_timeout(650)
  tap(leave);unchanged('confirm-open')
  tap(cancel);unchanged('cancel-tap')
  tap(leave);start(cancel);pg.wait_for_timeout(500);unchanged('cancel-held-before-release');end();unchanged('cancel-held-after-release')
  tap(leave);start((2,2));cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':music[0],'y':music[1]}]});end();unchanged('modal-drag-over-slider')
  tap(cancel);unchanged('cancel-after-modal-drag')
  tap(leave);start(cancel);pg.wait_for_timeout(300);pg.keyboard.press('Escape');end();unchanged('escape-during-held-cancel')
  tap(resume);pg.wait_for_timeout(700);snap('resume-yard')
  pg.keyboard.down('ArrowRight');pg.wait_for_timeout(1200);pg.keyboard.up('ArrowRight');pg.wait_for_timeout(300);snap('yard-after-walk')
  pg.keyboard.press('Escape');pg.wait_for_timeout(1200)
  pg.mouse.click(*leave);pg.wait_for_timeout(400);pg.mouse.click(*cancel);pg.wait_for_timeout(650);unchanged('mouse-cancel')
  pg.mouse.click(*leave);pg.wait_for_timeout(400);pg.keyboard.press('Escape');pg.wait_for_timeout(650);unchanged('keyboard-cancel')
  start(music);cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':music[0]+40,'y':music[1]}]});end()
  changed=snap('ordinary-slider-drag');assert changed!=initial
  # Real browser two-finger stream: the second finger cannot acquire ambience.
  ambience=(587,292) if w==844 else (w/2,616+(h-844)/2)
  first={'id':0,'x':music[0],'y':music[1]};second={'id':1,'x':ambience[0],'y':ambience[1]}
  cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[first]});pg.wait_for_timeout(650)
  owned=snap('multitouch-first-slider')
  cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[first,second]})
  second['x']+=40
  cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[first,second]});pg.wait_for_timeout(650)
  assert snap('multitouch-second-slider')==owned
  cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[first]})
  second['x']+=20
  cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[second]});pg.wait_for_timeout(650)
  assert snap('multitouch-owner-released')==owned
  end()
  before_mouse=snap('mouse-after-touch-before')
  pg.mouse.move(music[0]-50,music[1]);pg.mouse.down();pg.mouse.move(music[0]+50,music[1],steps=5);pg.mouse.up();pg.wait_for_timeout(650)
  assert snap('mouse-after-touch-drag')!=before_mouse
  start(music);pg.wait_for_timeout(650);before_rotation=snap('rotation-held-before')
  pg.set_viewport_size({'width':h,'height':w});pg.wait_for_timeout(850);end()
  assert snap('rotation-held-after')==before_rotation
  pg.set_viewport_size({'width':w,'height':h});pg.wait_for_timeout(850)
  tap(leave);tap(accept);pg.wait_for_timeout(8000);snap('accepted-return-title')
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(1800);snap('reentered-yard')
  if public:assert pg.request.get(urljoin(url,'game-release.json')).json()==manifest
  proof.append({'view':[w,h,dpr],'browser':b.version,'source':source,'build':build,'manifest':manifest,'loaded_packages':packages})
  (out/'source-proof.json').write_text(json.dumps(proof,indent=2),encoding='utf-8')
  b.close()
print(json.dumps({'events':len(events),'views':len(proof),'errors':sum(len(x['errors']) for x in events)}))
