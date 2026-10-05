import hashlib,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/licenses402-web');build=json.loads(Path('/workspace/confirm373-export/candidate-build.json').read_text());r={'source':build,'errors':[],'actions':[]}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':568,'height':320},device_scale_factor=2);pg=c.new_page();pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 r['before']=pg.request.get('http://127.0.0.1:8195/candidate-build.json').json();assert r['before']==build
 raw=pg.request.get('http://127.0.0.1:8195/index.pck').body();r['pck_sha256']=hashlib.sha256(raw).hexdigest();assert r['pck_sha256']==build['pck_sha256']
 pg.goto('http://127.0.0.1:8195/',wait_until='domcontentloaded');assert pg.locator('html').get_attribute('data-build')=='index';pg.wait_for_function('window.first',timeout=120000);pg.wait_for_timeout(1600)
 pg.screenshot(path=str(out/'title.png'));r['actions'].append({'click':[284,244],'description':'ordinary title license button'})
 with c.expect_page() as pop:pg.mouse.click(284,244)
 license=pop.value;license.wait_for_load_state();r['license']={'url':license.url,'title':license.title(),'text':license.locator('body').inner_text()[:500]};assert 'open-source-licenses.html' in license.url;assert 'Godot' in license.locator('body').inner_text();license.screenshot(path=str(out/'license-html.png'))
 r['after']=pg.request.get('http://127.0.0.1:8195/candidate-build.json').json();assert r['after']==build;assert not r['errors'];b.close()
(out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n');print('PASS ordinary Web HTML opener; not native dialog evidence')
