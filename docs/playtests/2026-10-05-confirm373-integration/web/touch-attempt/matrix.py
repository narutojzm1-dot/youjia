import json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('/workspace/confirm373-candidate'); result={'source_sha':'6f9d15b8afe2bbc9d9ca0ba2f50a993c06a55b4b','pck_sha256':'794fc7656acd4bceaf3c82f9b4f13d08cb52df0df4abcf1bff91905825e7da29','input':'Playwright touchscreen.tap CSS coordinates; no state/DOM injection','cases':[],'errors':[]}
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']);result['browser']=b.version
 for w,h,d in [(390,844,2),(390,844,3),(360,640,2),(360,640,3)]:
  tag=f'{w}x{h}-dpr{d}';c=b.new_context(viewport={'width':w,'height':h},device_scale_factor=d,is_mobile=True,has_touch=True);page=c.new_page();case={'tag':tag,'actions':[]};result['cases'].append(case)
  page.on('pageerror',lambda e:result['errors'].append(str(e)))
  page.on('console',lambda m:result['errors'].append(m.text) if m.type=='error' else None)
  def shot(label):page.screenshot(path=str(out/f'{tag}-{label}.png'))
  def tap(x,y,label):case['actions'].append({'tap':[x,y],'label':label});page.touchscreen.tap(x,y);page.wait_for_timeout(1000);shot(label)
  page.goto('http://127.0.0.1:8195/');page.wait_for_timeout(12000);shot('title')
  tap(w/2,h/2+8,'yard');tap(w-80,44,'pause')
  # Pause layout center is viewport center; fixed CSS card content has return row 82 above center.
  tap(w/2,h/2-82,'confirm')
  if w==390:tap(w/2,h/2+68,'cancel');tap(w/2,h/2-194,'resume')
  # Smaller viewport actions follow after original images are inspected.
  if w==390 and d==2:
   tap(w-80,44,'pause-again');tap(w/2,h/2-82,'confirm-again');page.set_viewport_size({'width':844,'height':390});page.wait_for_timeout(1200);shot('rotate-confirm')
  c.close();(out/'matrix.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
 b.close()
