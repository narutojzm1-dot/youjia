"""Isolated browser API-failure compatibility test; not ordinary player evidence."""
import hashlib, json, pathlib, sys
from playwright.sync_api import sync_playwright

meta = json.loads(pathlib.Path('/workspace/motion-candidate-release.json').read_text())
out = pathlib.Path('/workspace/reduced-motion-fallback')
out.mkdir(exist_ok=False)
url = 'http://127.0.0.1:8195/'
result = {'scope': 'candidate browser API-failure injection; not ordinary preference UX',
          'runtime': meta['source'], 'pck_sha256': meta['pck_sha256'], 'cases': []}
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
        args=['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--enable-unsafe-swiftshader'])
    try:
        for name, fault in [('missing', 'window.matchMedia = undefined;'),
                            ('throws', "window.matchMedia = () => { throw new Error('TEST media API unavailable'); }; ")]:
            context = browser.new_context(viewport={'width': 1280, 'height': 720})
            page = context.new_page()
            case = {'name': name, 'fault': fault, 'errors': []}
            result['cases'].append(case)
            page.on('pageerror', lambda e, c=case: c['errors'].append(str(e)))
            page.on('console', lambda m, c=case: c['errors'].append(m.text) if m.type == 'error' else None)
            page.add_init_script(fault + "window.motionTestFirstFrame=false; addEventListener('youjia:first-frame',()=>window.motionTestFirstFrame=true);")
            source = page.request.get(url+'game-release.json').json()
            assert source['sourceCommit'] == meta['source']
            response = page.request.get(url+meta['entry']+'.pck')
            assert response.status == 200 and hashlib.sha256(response.body()).hexdigest() == meta['pck_sha256']
            page.goto(url)
            assert page.locator('html').get_attribute('data-build') == meta['entry']
            page.wait_for_function('window.motionTestFirstFrame', timeout=180000)
            page.wait_for_timeout(1000)
            page.screenshot(path=str(out/(name+'-title.png')))
            page.mouse.click(640, 368)
            page.wait_for_timeout(1800)
            page.screenshot(path=str(out/(name+'-yard.png')))
            assert page.request.get(url+'game-release.json').json()['sourceCommit'] == meta['source']
            case['first_frame'] = True
            case['normal_input'] = {'mouse_click': [640, 368]}
            assert not case['errors'], case['errors']
            context.close()
    finally:
        (out/'result.json').write_text(json.dumps(result, indent=2))
        browser.close()
print(json.dumps(result))
