import json
from pathlib import Path
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
 page=b.new_page();page.goto('https://narutojzm1-dot.github.io/youjia/game-release.json',wait_until='domcontentloaded')
 result=page.evaluate('''async()=>{
  const c=new AbortController();const t=setTimeout(()=>c.abort(),30000);
  try {const r=await fetch('game-070ae5a.pck',{headers:{Range:'bytes=0-1048575'},signal:c.signal});const a=await r.arrayBuffer();return {status:r.status,headers:Object.fromEntries(r.headers),length:a.byteLength,first:[...new Uint8Array(a).slice(0,24)]};} catch(e){return {error:String(e)}} finally{clearTimeout(t)}
 }''')
 print(json.dumps(result));Path(__file__).with_name('loading-range-result.json').write_text(json.dumps(result,indent=2))
 b.close()
