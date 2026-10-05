"""Candidate-only ordinary input QA. Does not call Godot methods or inject saves.
Implemented by PR444 integrator; this is not the independent final review.
"""
from pathlib import Path
import argparse, hashlib, json, time
from playwright.sync_api import sync_playwright

ap = argparse.ArgumentParser()
ap.add_argument('--out', default='/tmp/soft444-candidate-qa')
ap.add_argument('--url', default='http://127.0.0.1:8444/')
args = ap.parse_args()
out = Path(args.out)
out.mkdir(exist_ok=False)
url = args.url
expected = '14a85a532f9510306b7921b9daa23409d17799c6'
expected_hash = 'c8b05b9bbe0a5359d223b8686212366676c549538e3845279b4b84d4f8a92530'
expected_bytes = 27088652
r = {'source': expected, 'candidateOnly': True,
     'role': 'CODEX-LEAD implementation-agent candidate QA; not independent final review',
     'actions': [], 'source_checks': [], 'screenshots': [], 'console': [], 'errors': [],
     'matrix': [[1280,720],[390,844],[568,320]],
     'limits': ['No game-state injection, grab_focus or signal emission',
                'No ear/hearing judgement', 'No physical phone or touch claim',
                'Screenshot geometry is visual; canvas bounds do not measure Godot hit rectangles',
                'English, disabled/save-error buttons and complete album paging are not covered']}
ctx = None
pg = None
view_tag = None

def persist():
    (out/'result.json').write_text(json.dumps(r, ensure_ascii=False, indent=2)+'\n')

def source(stage):
    response = pg.request.get(url+'candidate-release.json?qa='+str(time.time()))
    assert response.ok, response.status
    manifest = response.json()
    assert manifest['sourceCommit'] == expected and manifest['candidateOnly'] is True, manifest
    got = pg.request.get(url+'index.pck?qa='+str(time.time()))
    assert got.ok, got.status
    body = got.body()
    actual = {'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest()}
    assert actual['bytes'] == expected_bytes and actual['sha256'] == expected_hash, actual
    r['source_checks'].append({'stage':stage,'view':view_tag,'manifest':manifest,'actual_pck':actual})
    del body

def shot(name):
    pg.wait_for_timeout(180)
    pg.screenshot(path=str(out/(name+'.png')), scale='css')
    r['screenshots'].append({'name':name,'view':view_tag,
        'url':pg.url,'build':pg.locator('html').get_attribute('data-build'),
        'canvas':pg.locator('canvas').bounding_box(), 'time':time.monotonic()})
    persist()

def open_view(width,height,tag):
    global ctx,pg,view_tag
    if ctx is not None:
        source('before-context-close')
        ctx.close()
    view_tag=tag
    ctx=b.new_context(viewport={'width':width,'height':height},device_scale_factor=2)
    pg=ctx.new_page()
    pg.add_init_script("window.soft444FirstFrame=false;addEventListener('youjia:first-frame',()=>{window.soft444FirstFrame=true})")
    pg.on('console',lambda m:r['console'].append({'view':tag,'type':m.type,'text':m.text}))
    pg.on('pageerror',lambda e:r['errors'].append({'view':tag,'kind':'pageerror','text':str(e)}))
    pg.on('console',lambda m:r['errors'].append({'view':tag,'kind':'console','text':m.text}) if m.type=='error' else None)
    source('before-open')
    pg.goto(url+'?qa=soft444-'+str(time.time()),wait_until='domcontentloaded')
    pg.wait_for_function('window.soft444FirstFrame',timeout=120000)
    pg.wait_for_timeout(600)
    assert pg.locator('html').get_attribute('data-build')=='candidate-soft444-14a85a5'
    shot(tag+'-initial')

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,
        args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
    try:
        open_view(1280,720,'desktop')
        print('READY desktop',flush=True)
        deadline=time.monotonic()+1100
        while time.monotonic()<deadline:
            command=out/'command.json'
            if not command.exists():
                pg.wait_for_timeout(250)
                continue
            c=json.loads(command.read_text()); command.unlink()
            r['actions'].append({'view':view_tag,'time':time.monotonic(),'command':c})
            if 'new_view' in c:
                w,h,tag=c['new_view'];open_view(w,h,tag)
            for a in c.get('actions',[]):
                if a[0]=='move': pg.mouse.move(a[1],a[2])
                elif a[0]=='down': pg.mouse.down()
                elif a[0]=='up': pg.mouse.up()
                elif a[0]=='click': pg.mouse.click(a[1],a[2])
                elif a[0]=='key': pg.keyboard.press(a[1])
                elif a[0]=='keydown': pg.keyboard.down(a[1])
                elif a[0]=='keyup': pg.keyboard.up(a[1])
                elif a[0]=='wait': pg.wait_for_timeout(min(a[1],5000))
                else: raise ValueError('Unknown ordinary-input command '+str(a))
            shot(c['name'])
            (out/'done').write_text(c['name'])
            print('DONE '+c['name'],flush=True)
            if c.get('exit'):
                source('final')
                r['completed']=True
                break
        else:
            raise TimeoutError('Bounded QA command window exceeded')
    except BaseException as exc:
        r['exception']=repr(exc)
        raise
    finally:
        if ctx is not None: ctx.close()
        b.close()
        r['browserClosed']=True
        persist()
