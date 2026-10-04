"""Real two-page candidate import race; temporary Chromium profile only."""
import functools, http.server, json, threading, argparse
from pathlib import Path
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser()
parser.add_argument('--out',required=True)
args=parser.parse_args()
class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*_): pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Handler,directory=str(Path(__file__).resolve().parent)))
threading.Thread(target=server.serve_forever,daemon=True).start()
checks=0
def check(value):
    global checks
    assert value
    checks+=1
try:
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
        context=browser.new_context()
        pages=[context.new_page(),context.new_page()]
        # A plain page avoids executing the single-page suite.
        for page in pages:
            page.goto(f'http://127.0.0.1:{server.server_port}/')
            page.evaluate("async()=>{window.host=(await import('./bridge.mjs')).bridge;}")
        name=pages[0].evaluate("'youjia-recovery-test-'+crypto.randomUUID()")
        for page in pages:
            check(page.evaluate('n=>host.open(n)',name)['verdict']=='empty')
        raws=['{ "version":5,"winner":"A","unknown":9007199254740993 }','{ "version":5,"winner":"B","unknown":9007199254740994 }']
        for page,raw in zip(pages,raws):
            page.evaluate("""raw=>{
                const input={primary:{status:'present',base64:btoa(raw)},backup:{status:'absent'}};
                window.pending=host.initializeLegacy(input).then(value=>{window.result={ok:true,value};},error=>{window.result={ok:false,error:String(error)};});
            }""",raw)
        for page in pages: page.wait_for_function('window.result !== undefined')
        results=[page.evaluate('window.result') for page in pages]
        check(sum(r['ok'] for r in results)==1)
        check(sum(not r['ok'] for r in results)==1)
        winner=next(r['value'] for r in results if r['ok'])
        check(winner['verdict']=='clean')
        fresh=context.new_page()
        fresh.goto(f'http://127.0.0.1:{server.server_port}/')
        recovered=fresh.evaluate("async n=>(await import('./bridge.mjs')).bridge.open(n)",name)
        check(recovered['verdict']=='clean')
        check(recovered['current_token']==winner['current_token'] and recovered['current_payload']==winner['current_payload'])
        check(json.loads(recovered['current_payload'])['sources']['primary']['text'] in raws)
        version=browser.version
        browser.close()
    Path(args.out).write_text(json.dumps({'status':'PASS','checks':checks,'browser':version,'scope':'two real pages, one initializeLegacy winner, fresh-page exact recovery'},indent=2))
    print('PASS',checks)
finally:
    server.shutdown()
