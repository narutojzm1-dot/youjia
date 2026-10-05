import json,sys,time
from pathlib import Path
from playwright.sync_api import sync_playwright
url,folder=sys.argv[1:3];out=Path(folder);out.mkdir(parents=True,exist_ok=True)
events=[]
with sync_playwright() as p:
 for w,h,dpr in [(844,390,3),(390,844,3)]:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
  pg=b.new_page(viewport={'width':w,'height':h},device_scale_factor=dpr);errors=[]
  pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  pg.add_init_script("""window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true);
   window.observedGainNodes=[];const proto=window.BaseAudioContext?.prototype;
   if(proto){const original=proto.createGain;proto.createGain=function(...args){const node=Reflect.apply(original,this,args);window.observedGainNodes.push({node,creator:new Error().stack});return node;};}
  """)
  pg.goto(url);pg.wait_for_function('window.first',timeout=120000)
  def snap(stage):
   backend=pg.evaluate("window.__manusBgm?JSON.parse(window.__manusBgm.diagnostics()):null")
   f=f'{w}-{h}-dpr{dpr}-{stage}.png';pg.screenshot(path=str(out/f),scale='css')
   gains=pg.evaluate("observedGainNodes.filter(o=>o.creator.includes('channel')).map(o=>o.node.gain.value)")
   e={'stage':stage,'view':[w,h,dpr],'build':pg.locator('html').get_attribute('data-build'),'backend':backend,'gains':gains,'errors':errors.copy(),'screenshot':f}
   events.append(e);(out/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2));return e
  pg.mouse.click(w/2,h/2);pg.wait_for_timeout(350);pg.keyboard.press('Escape');pg.wait_for_timeout(8500)
  initial=snap('paused-before-controls')
  music=(590,194) if w==844 else (190,480)
  ambience=(590,291) if w==844 else (190,616)
  pg.mouse.click(*music,delay=80);pg.wait_for_timeout(500);m=snap('music-half')
  assert len(initial['gains'])==2 and len(m['gains'])==2,(initial,m)
  assert sum(0<new<old for old,new in zip(initial['gains'],m['gains']))==1,m
  pg.mouse.click(*ambience,delay=80);pg.wait_for_timeout(500);a=snap('ambience-half')
  assert sum(0<new<old for old,new in zip(m['gains'],a['gains']))==1,a
  mute=(252,297) if w==844 else (190,666)
  pg.mouse.click(*mute,delay=500);pg.wait_for_timeout(1000);m=snap('muted')
  # Master mute zeros gain; already-playing channels do not stop decoding.
  events[-1]['expected_effective'] = m['backend']['playing']==2 and m['gains']==[0,0]
  pg.mouse.click(*mute,delay=500);pg.wait_for_timeout(1000);m=snap('unmuted')
  events[-1]['expected_effective'] = m['backend']['playing']==2 and m['gains']==a['gains']
  for name,xy in [('music',(590,134) if w==844 else (190,396)),('ambience',(590,232) if w==844 else (190,530))]:
   pg.mouse.click(*xy,delay=500);pg.wait_for_timeout(1000);v=snap(name+'-off');events[-1]['expected_effective']=v['backend']['playing']==1
   pg.mouse.click(*xy,delay=500);pg.wait_for_timeout(1000);v=snap(name+'-on');events[-1]['expected_effective']=v['backend']['playing']==2
  pg.keyboard.press('Escape');pg.wait_for_timeout(300);snap('resume-first-hint')
  # Existing visible first-hint route; pause again and keep it unread for 5s.
  pg.keyboard.press('Escape');pg.wait_for_timeout(5500);snap('paused-visible-hint')
  pg.keyboard.press('Escape');pg.wait_for_timeout(300);snap('resume-preserved-hint')
  (out/'events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2))
  assert not errors,errors
  b.close()
print(json.dumps(events,ensure_ascii=False))
