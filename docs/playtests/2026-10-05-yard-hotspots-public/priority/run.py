import json,time,io
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
out=Path('/workspace/yard-hotspots-priority-public');ev=[];errors=[]
tplroot=Path('/workspace/youjia-production-save/docs/playtests/2026-10-05-fishing-active-hud/retest');box=(1080,660,1250,692)
def mask(im):return [v<120 for v in im.convert('L').crop(box).getdata()]
tpl={k:mask(Image.open(tplroot/f'1280-720-{i}.png')) for i,k in enumerate(['wait','reel','toss'])}
def label(im):
 a=mask(im);s={k:sum(x and y for x,y in zip(a,b))/max(1,sum(x or y for x,y in zip(a,b))) for k,b in tpl.items()};k=max(s,key=s.get);return k if s[k]>.65 else 'other'
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-webgl']);ctx=b.new_context(viewport={'width':1280,'height':720});pg=ctx.new_page()
 pg.on('pageerror',lambda e:errors.append(str(e)));pg.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 pg.add_init_script("window.first=false;window.addEventListener('youjia:first-frame',()=>window.first=true)")
 r=pg.goto('https://narutojzm1-dot.github.io/youjia/');html=r.text();m=pg.evaluate("fetch('game-release.json',{cache:'no-store'}).then(r=>r.json())");assert m['sourceCommit']=='1a3842c63558fa68a68ca41c2da58f4c5a254929';assert 'game-1a3842c' in html
 pg.wait_for_function('window.first',timeout=120000);pg.mouse.click(640,360);pg.wait_for_timeout(5000)
 pg.mouse.click(750,540);pg.wait_for_timeout(5000);pg.screenshot(path=str(out/'positioning-cast.png'));pg.keyboard.press('Space');pg.wait_for_timeout(500);pg.screenshot(path=str(out/'pre-cast.png'))
 def click(tag,x,y):
  a=time.monotonic();pg.mouse.click(x,y);ev.append({'action':tag,'xy':[x,y],'start':a,'returned':time.monotonic()})
 click('pond-cast',750,540);pg.wait_for_timeout(150);click('fence-during-cast',900,390);pg.wait_for_timeout(100);pg.screenshot(path=str(out/'after-fast-fence.png'))
 start=time.monotonic();last='';caught=False
 while time.monotonic()-start<45:
  im=Image.open(io.BytesIO(pg.screenshot()));lab=label(im)
  if lab!=last:im.save(out/f'observed-{len(ev):02}-{lab}.png');ev.append({'label':lab,'time':time.monotonic()});last=lab
  if lab=='reel':
   click('reel',1165,677);pg.wait_for_timeout(150);click('flowerbox-after-reel',335,234);pg.wait_for_timeout(100);pg.screenshot(path=str(out/'after-reel-flowerbox.png'));caught=True;break
  pg.wait_for_timeout(250)
 (out/'result.json').write_text(json.dumps({'manifest':m,'events':ev,'reel_clicked':caught,'errors':errors},indent=2));b.close()
