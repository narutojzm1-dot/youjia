import hashlib,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path(__file__).parent;url='https://narutojzm1-dot.github.io/youjia/';source='82f902a0f22f50032bff9acbe542d0f1953ae684';r={'source':source,'errors':[],'actions':[],'network':[]}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':568,'height':320},device_scale_factor=2);pg=c.new_page()
 c.on('response',lambda z:r['network'].append({'url':z.url,'status':z.status,'content_type':z.headers.get('content-type')}) if '.pck' in z.url or 'open-source-licenses.html' in z.url else None)
 pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
 pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
 try:
  r['before']=pg.request.get(url+'game-release.json?t='+str(time.time())).json();assert r['before']['sourceCommit']==source
  entry=r['before']['entry'];assert entry=='game-'+source[:7]
  req=pg.request.get(url+entry+'.pck');assert req.status==200;raw=req.body();r['pck']={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'url':req.url,'status':req.status}
  pg.goto(url,wait_until='domcontentloaded');r['html_before']=pg.locator('html').get_attribute('data-build');assert r['html_before']==entry
  pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1600);pg.screenshot(path=str(out/'title.png'))
  r['actions'].append({'click':[284,244],'description':'ordinary title license button','time':time.time()})
  with c.expect_page() as pop:pg.mouse.click(284,244)
  lic=pop.value;lic.wait_for_load_state();r['license']={'url':lic.url,'title':lic.title(),'text':lic.locator('body').inner_text()[:500]};assert 'open-source-licenses.html' in lic.url;assert 'Godot' in lic.locator('body').inner_text();lic.screenshot(path=str(out/'license-html.png'))
  assert any(x['status']==200 and 'open-source-licenses.html' in x['url'] for x in r['network'])
  lic.close();pg.bring_to_front();pg.screenshot(path=str(out/'returned-title.png'))
  pg.mouse.click(284,171);r['actions'].append({'click':[284,171],'description':'ordinary enter yard','time':time.time()});pg.wait_for_timeout(2500);pg.screenshot(path=str(out/'yard.png'))
  r['after']=pg.request.get(url+'game-release.json?t='+str(time.time())).json();r['html_after']=pg.locator('html').get_attribute('data-build');assert r['after']['sourceCommit']==source and r['html_after']==entry;assert not r['errors']
  print('PASS public Web HTML opener, return, normal enter; not native dialog evidence')
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n');b.close()
