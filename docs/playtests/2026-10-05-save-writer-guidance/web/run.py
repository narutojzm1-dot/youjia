from pathlib import Path
from playwright.sync_api import sync_playwright
import json,time
out=Path(__file__).parent
url='http://127.0.0.1:8194/'
read=(out/'read_db.js').read_text();logs=[];errors=[];actions=[];builds=[];records={}
def save():
 for n,v in [('console',{'logs':logs,'errors':errors}),('actions',actions),('builds',builds),('records',records)]:
  (out/(n+'.json')).write_text(json.dumps(v,ensure_ascii=False,indent=2))
def click(p,x,y,label):
 actions.append({'label':label,'xy':[x,y],'time':time.time()});save();p.mouse.click(x,y)
def watch(p,label):
 p.on('console',lambda m:logs.append([label,m.type,m.text]));p.on('pageerror',lambda e:errors.append([label,str(e)]))
 p.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
def bind(p,label):
 build=p.locator('html').get_attribute('data-build');assert build=='index',build
 builds.append({'label':label,'build':build,'url':p.url,'runtime_bound_by_pck':'830320b28ef1592244070683bf0bc3e1acfcdd84'});save()
with sync_playwright() as q:
 b=q.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':1280,'height':720});p1=c.new_page();watch(p1,'first')
 try:
  p1.goto(url);bind(p1,'first');p1.wait_for_function('window.first',timeout=180000);p1.wait_for_timeout(1500)
  click(p1,640,368,'enter');p1.wait_for_timeout(1000);click(p1,364,412,'natural-sheep');p1.wait_for_timeout(9000);click(p1,114,675,'album');p1.wait_for_timeout(1000)
  p1.screenshot(path=str(out/'first-album.png'));records['before_second']=p1.evaluate(read);save()
  p2=c.new_page();watch(p2,'second');p2.goto(url);bind(p2,'second')
  p2.wait_for_function("document.getElementById('loading-status').textContent==='另一页正在游玩'",timeout=180000)
  assert p2.locator('#loading-retry').is_visible();assert not p2.evaluate('window.first')
  p2.screenshot(path=str(out/'second-blocked.png'));records['during_second']=p2.evaluate(read);p1.screenshot(path=str(out/'first-preserved.png'));save()
  assert records['before_second']==records['during_second'],'second page changed database'
  actions.append({'label':'close-first-page','time':time.time()});p1.close();save()
  p2.locator('#loading-retry').click();actions.append({'label':'real-retry-button','time':time.time()});save()
  p2.wait_for_load_state('domcontentloaded');p2.wait_for_function('window.first',timeout=180000);bind(p2,'second-reloaded');p2.wait_for_timeout(1500)
  click(p2,640,368,'reloaded-enter');p2.wait_for_timeout(1500);click(p2,114,675,'reloaded-album');p2.wait_for_timeout(1000)
  p2.screenshot(path=str(out/'second-recovered-album.png'));records['after_retry']=p2.evaluate(read);save()
  assert records['before_second']==records['after_retry'],'normal reload changed original database'
  assert not errors,errors
  print('PASS actual two-page lock guidance / real retry reload / full DB equality')
 finally:
  save();b.close()
