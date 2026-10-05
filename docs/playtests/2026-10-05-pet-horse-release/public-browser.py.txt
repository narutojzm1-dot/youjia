from playwright.sync_api import sync_playwright
import json,sys
build_expected,outdir=sys.argv[1:]
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl'])
 page=b.new_page(viewport={'width':844,'height':390},device_scale_factor=1)
 errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 page.goto('https://narutojzm1-dot.github.io/youjia/?verify='+build_expected,wait_until='domcontentloaded')
 page.wait_for_function('window.first',timeout=120000)
 build=page.locator('html').get_attribute('data-build')
 assert build==build_expected,build
 page.mouse.click(422,196)
 page.wait_for_timeout(1000)
 page.mouse.click(730,44)
 page.wait_for_timeout(500)
 page.mouse.click(491,194)
 page.mouse.click(650,292)
 page.wait_for_timeout(300)
 page.screenshot(path=outdir+'/public-pause.png')
 page.mouse.click(257,134)
 page.wait_for_timeout(500)
 page.screenshot(path=outdir+'/public-resumed.png')
 assert not errors,errors
 result={'build':build,'viewport':[844,390],'page_errors':errors,'scope':'public canvas startup, pause, two sliders, resume; screenshots reviewed separately, no listening claim'}
 open(outdir+'/public-browser.json','w').write(json.dumps(result))
 print(result)
 b.close()
