"""Run against a separately exported fixture directory; never load game save origin."""
import http.server, threading, json, hashlib, pathlib, sys
from functools import partial
from playwright.sync_api import sync_playwright
root = pathlib.Path(sys.argv[1]).resolve()
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), partial(http.server.SimpleHTTPRequestHandler, directory=str(root / 'web')))
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True, args=['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        page = browser.new_page(); errors = []; logs = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.on('console', lambda m: logs.append(m.text))
        page.goto(f'http://127.0.0.1:{server.server_port}/index.html')
        page.wait_for_function('window.gateResult || window.gateError', timeout=90000)
        assert not page.evaluate('window.gateError'), page.evaluate('window.gateError')
        result = page.evaluate('window.gateResult')
        assert result == {'checks': 20, 'events': ['complete', 'abort'], 'removed': True}, result
        assert not errors, errors
        assert 'SAVE GATE WEB PASS 20' in logs, logs
        assert not any('ERROR:' in line or 'SCRIPT ERROR' in line for line in logs), logs
        report = {'browser': browser.version, 'result': result, 'pageerrors': errors, 'pck_sha256': hashlib.sha256((root / 'web/index.pck').read_bytes()).hexdigest()}
        (root / 'result.json').write_text(json.dumps(report, indent=2)); print(json.dumps(report))
        browser.close()
finally:
    server.shutdown()
