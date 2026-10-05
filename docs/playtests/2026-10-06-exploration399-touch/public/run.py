"""Prepared ordinary-UI QA. Requires explicit candidate URL/build/PCK before running.
Media emulation uses actual browser matchMedia; no game state setters.
"""
import argparse,hashlib,io,json,time
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--url',required=True);ap.add_argument('--runtime',required=True);ap.add_argument('--entry',required=True);ap.add_argument('--pck-sha256',required=True);ap.add_argument('--out',required=True);a=ap.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=False)
r={'runtime':a.runtime,'expected_pck':a.pck_sha256,'inputs':[],'media':[],'errors':[],'builds':[],'limits':['browser media emulation, not OS settings or physical phone','listener multiplicity is not proved by screenshots','photo detector needs visual confirmation']}
def log(v):r['inputs'].append(dict(v,time=time.monotonic()))
def card_visible(blob):
 im=Image.open(io.BytesIO(blob)).convert('RGB'); pts=[]
 for x in range(5,19,3):
  for y in range(30,240,10):pts.append(im.getpixel((x,y)))
 return sum(min(z)>170 and max(z)-min(z)<85 for z in pts)/len(pts)>.65
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,proxy={'server':'http://proxy:8080'},args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
 def stable(pg,name,stage):
  manifest=pg.request.get(a.url.rstrip('/')+'/game-release.json?t='+str(time.time())).json();assert manifest['sourceCommit']==a.runtime,manifest;r.setdefault('manifests',[]).append({'page':name,'stage':stage,'manifest':manifest,'time':time.monotonic()})
 def bind(ctx,name):
  pg=ctx.new_page();pg.on('pageerror',lambda e:r['errors'].append(str(e)));pg.on('console',lambda m:r['errors'].append(m.text) if m.type=='error' else None)
  pg.add_init_script("window.first=false;addEventListener('youjia:first-frame',()=>window.first=true)")
  stable(pg,name,'before')
  response=pg.request.get(a.url.rstrip('/')+'/'+a.entry+'.pck');actual_hash=hashlib.sha256(response.body()).hexdigest();assert response.status==200 and actual_hash==a.pck_sha256,(response.status,actual_hash);r.setdefault('pck_checks',[]).append({'page':name,'sha256':actual_hash});pg.goto(a.url);entry=pg.locator('html').get_attribute('data-build');assert entry==a.entry,(entry,a.entry);r['builds'].append({'page':name,'entry':entry});pg.wait_for_function('window.first',timeout=180000);pg.wait_for_timeout(1200);return pg
 def shot(pg,n):log({'screenshot':n});pg.screenshot(path=str(out/(n+'.png')),scale='css')
 def click(pg,x,y):log({'click':[x,y]});pg.mouse.click(x,y)
 def media(pg,value):
  log({'emulate_media':value});pg.emulate_media(reduced_motion=value);r['media'].append({'time':time.monotonic(),'requested':value,'actual':pg.evaluate("matchMedia('(prefers-reduced-motion: reduce)').matches")})
 try:
  ctx=b.new_context(viewport={'width':1280,'height':720},device_scale_factor=2,has_touch=True,is_mobile=True);pg=bind(ctx,'touch-keyboard')
  def tap(x,y):log({'touchscreen_tap':[x,y]});pg.touchscreen.tap(x,y)
  tap(640,368);pg.wait_for_timeout(1500);shot(pg,'yard');tap(329,563);pg.wait_for_timeout(7000);shot(pg,'touch-outside');pg.wait_for_timeout(1500);shot(pg,'touch-no-bounce');tap(706,500);pg.wait_for_timeout(3500);shot(pg,'touch-walked');tap(1060,390);pg.wait_for_timeout(6500);shot(pg,'touch-return')
  command=out/'command.json'
  while True:
   if not command.exists():pg.wait_for_timeout(200);continue
   v=json.loads(command.read_text());command.unlink()
   for act in v.get('actions',[]):
    if act[0]=='tap':tap(act[1],act[2])
    elif act[0]=='wait':pg.wait_for_timeout(act[1])
    elif act[0]=='key':log({'key':act[1]});pg.keyboard.press(act[1])
    elif act[0]=='hold':log({'hold':[act[1],act[2]]});pg.keyboard.down(act[1]);pg.wait_for_timeout(act[2]);pg.keyboard.up(act[1])
   shot(pg,v['name']);(out/'progress.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));(out/'done').write_text(v['name'])
   if v.get('exit'):break
  stable(pg,'touch-keyboard','after');ctx.close()
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
