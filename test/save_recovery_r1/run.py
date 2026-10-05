"""Run the isolated R1 browser checks; never uses a production browser profile."""
import argparse
import functools
import http.server
import json
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--chrome', default='/usr/bin/chromium')
parser.add_argument('--out', required=True)
parser.add_argument('--suite', choices=['suite.html', 'legacy_suite.html', 'migration_bridge_suite.html', 'budget_suite.html'], default='suite.html')
args = parser.parse_args()
root = Path(__file__).resolve().parent
class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(Handler, directory=str(root)))
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=args.chrome, headless=True, args=['--no-sandbox'])
        page = browser.new_page()
        page.goto(f'http://127.0.0.1:{server.server_port}/{args.suite}')
        page.wait_for_function('window.r1Done === true', timeout=180000)
        result = page.evaluate('window.r1')
        result['browser'] = browser.version
        browser.close()
    Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(result['status'], result['checks'])
    if result['status'] != 'PASS':
        raise SystemExit(1)
finally:
    server.shutdown()
