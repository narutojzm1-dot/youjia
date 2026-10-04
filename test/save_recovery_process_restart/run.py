"""R4 subset: kill an isolated Chromium process group, reopen same profile/origin.
Not a power-loss, quota, migration, or production-host proof.
"""
import argparse, functools, hashlib, http.server, json, os, pathlib, signal, socket
import subprocess, tempfile, threading, time, urllib.request, uuid
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--candidate', required=True)
parser.add_argument('--host-sha', required=True)
parser.add_argument('--fixture-sha', required=True)
parser.add_argument('--out', required=True)
parser.add_argument('--chrome', default='/usr/bin/chromium')
args = parser.parse_args()
root = pathlib.Path(args.candidate).resolve()
class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_): pass
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(Quiet, directory=str(root)))
threading.Thread(target=server.serve_forever, daemon=True).start()
report = {'host_sha': args.host_sha, 'fixture_sha': args.fixture_sha,
          'pck_sha256': hashlib.sha256((root/'index.pck').read_bytes()).hexdigest(),
          'scope': 'SIGKILL isolated browser process group; same disk profile/origin; not power loss or production host', 'cases': []}

def check(case, value, label):
    if not value: raise AssertionError(label)
    case['checks'].append(label)

def launch(p, profile, log):
    with socket.socket() as s:
        s.bind(('127.0.0.1',0)); port=s.getsockname()[1]
    proc = subprocess.Popen([args.chrome, '--headless', '--no-sandbox', '--no-first-run',
        '--no-default-browser-check', '--use-gl=angle', '--use-angle=swiftshader',
        '--enable-unsafe-swiftshader', '--remote-debugging-address=127.0.0.1',
        f'--remote-debugging-port={port}', f'--user-data-dir={profile}', 'about:blank'],
        stdout=log, stderr=log, start_new_session=True)
    try:
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            if proc.poll() is not None: raise RuntimeError('isolated browser exited')
            try:
                with urllib.request.urlopen(f'http://127.0.0.1:{port}/json/version',timeout=1): break
            except Exception: time.sleep(.1)
        else: raise TimeoutError('CDP did not start')
        return proc,p.chromium.connect_over_cdp(f'http://127.0.0.1:{port}')
    except BaseException:
        kill(proc); raise

def kill(proc):
    # This PID is created above as its own session/group; never touches user browser.
    if proc and proc.poll() is None:
        os.killpg(proc.pid,signal.SIGKILL);proc.wait(timeout=15)

def opened(browser,url):
    page=browser.contexts[0].new_page();page.goto(url)
    page.wait_for_function('window.YoujiaRecoveryFixture?.ready',timeout=30000)
    return page

try:
 with sync_playwright() as p:
  for barrier in ['intent_prepared_complete','candidate_committed_before_receipt','acknowledged']:
   case={'barrier':barrier,'checks':[]};report['cases'].append(case)
   proc=None
   with tempfile.TemporaryDirectory(prefix='youjia-r4-profile-') as profile, tempfile.TemporaryFile() as log:
    try:
     proc,browser=launch(p,profile,log);report['browser']=browser.version
     url=f'http://127.0.0.1:{server.server_port}/index.html?recovery_store=youjia-recovery-test-{uuid.uuid4().hex}'
     page=opened(browser,url);before=page.evaluate('window.YoujiaRecoveryProbe.snapshot()')
     if barrier!='acknowledged': page.evaluate('(b)=>window.YoujiaRecoveryProbe.arm(b)',barrier)
     page.evaluate('window.YoujiaRecoveryFixture.grant(1)')
     if barrier=='acknowledged':
      page.wait_for_function('window.YoujiaRecoveryFixture.business().watermark===1 && !window.YoujiaRecoveryFixture.business().pending')
     else: page.wait_for_function('window.YoujiaRecoveryProbe.paused')
     at_kill=page.evaluate('window.YoujiaRecoveryProbe.snapshot()');case['before']=before;case['at_kill']=at_kill
     old_pid=proc.pid;kill(proc);check(case,proc.returncode==-signal.SIGKILL,'actual SIGKILL exit');proc=None
     proc,browser=launch(p,profile,log);check(case,proc.pid!=old_pid,'new browser process')
     page=opened(browser,url);rec=page.evaluate('window.YoujiaRecoveryProbe.recovery()');case['recovery']=rec
     expected={'intent_prepared_complete':'restored_parent_intent_rejected','candidate_committed_before_receipt':'restored_candidate','acknowledged':'clean'}[barrier]
     check(case,rec['verdict']==expected,'expected recovery verdict')
     payload=json.loads(rec['current']['payload_bytes']);watermark=0 if barrier=='intent_prepared_complete' else 1
     check(case,payload['watermark']==watermark,'trusted watermark after process restart')
     check(case,not rec['present']['intent'],'intent cleared')
     if barrier=='intent_prepared_complete':
      check(case,rec['current']==before['current'],'exact parent retained')
      check(case,rec['archive'][0]['request_id']==at_kill['intent']['request_id'],'rejected request archived')
     else: check(case,rec['current']==at_kill['current'],'exact committed envelope retained')
     page.evaluate('window.YoujiaRecoveryFixture.grant(1)')
     page.wait_for_function('window.YoujiaRecoveryFixture.business().watermark===1 && !window.YoujiaRecoveryFixture.business().pending')
     after=page.evaluate('window.YoujiaRecoveryProbe.snapshot()');case['after_retry']=after
     business=page.evaluate('window.YoujiaRecoveryFixture.business()')
     check(case,json.loads(after['current']['payload_bytes'])['grants']==[1],'exactly one durable grant')
     check(case,business['grants']==[1] and business['confirmed_serials']==[1],'business agrees with durable grant')
     case['status']='PASS'
    except Exception as e: case['status']='FAIL';case['error']=repr(e)
    finally: kill(proc)
   print(case['status'],barrier,len(case['checks']),flush=True)
finally:
 server.shutdown()
 pathlib.Path(args.out).write_text(json.dumps(report,ensure_ascii=False,indent=2))
if any(c['status']!='PASS' for c in report['cases']): raise SystemExit(1)
