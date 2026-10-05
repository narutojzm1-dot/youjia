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
 for x in range(525,539,3):
  for y in range(240,450,10):pts.append(im.getpixel((x,y)))
 return sum(min(z)>215 and max(z)-min(z)<38 for z in pts)/len(pts)>.65
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader'])
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
  for name,w,h,dpr in [('land',568,320,2),('portrait',390,844,3)]:
   ctx=b.new_context(viewport={'width':w,'height':h},device_scale_factor=dpr);pg=bind(ctx,name);shot(pg,name+'-title')
   command=out/(name+'-command.json')
   while not command.exists():pg.wait_for_timeout(200)
   v=json.loads(command.read_text());click(pg,*v['enter']);pg.wait_for_timeout(1200);shot(pg,name+'-yard');command.unlink()
   while not command.exists():pg.wait_for_timeout(200)
   v=json.loads(command.read_text());click(pg,*v['sheep'])
   end=time.monotonic()+12;detected=False
   while time.monotonic()<end:
    factor=min(1,(h-24-46)/300);cw=240*factor;ch=300*factor;top=h/2-150 if factor==1 else 58;clip={'x':w/2-cw/2,'y':top,'width':cw,'height':ch};raw=pg.screenshot(clip=clip,scale='css');im=Image.open(io.BytesIO(raw)).convert('RGB');pixels=list(im.crop((5,25,14,min(180,im.height-20))).getdata());fraction=sum(min(z)>170 and max(z)-min(z)<85 for z in pixels)/len(pixels)
    if fraction>.78:
     (out/(name+'-possible-photo.png')).write_bytes(raw);log({'photo_detector':name,'fraction':fraction});detected=True
     pg.set_viewport_size({'width':390 if name=='land' else 568,'height':844 if name=='land' else 320});log({'viewport_changed':name});media(pg,'reduce');pg.screenshot(path=str(out/(name+'-after-resize.png')),scale='css');break
    pg.wait_for_timeout(40)
   r.setdefault('detected',{})[name]=detected;pg.wait_for_timeout(2000);shot(pg,name+'-after-expiry');command.unlink();
   while not command.exists():pg.wait_for_timeout(200)
   v=json.loads(command.read_text());click(pg,*v['album']);pg.wait_for_timeout(500);shot(pg,name+'-album');stable(pg,name,'after');ctx.close()
 finally:
  (out/'result.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));b.close()
