from pathlib import Path
folder=Path(r'D:\games\youjia-test\assistant-recovery')
s=(folder/'browser-nearby-web-storage-fault-oct11.py').read_text(encoding='utf-8')
old="picked=wait_state(lambda v:((v.get('exploration') or {}).get('session') or {}).get('carried')==[offer],'actual pickup commit after retry',timeout=15000)"
assert s.count(old)==1
s=s.replace(old,"""if mode=='pickup-abort':
            # The button resolves uncertainty. A definite rejection need not
            # re-enqueue a new pickup; the live carried item can commit on return.
            page.wait_for_timeout(1000);snap('pickup-after-resolve')
            assert payload()['keepsakes']==baseline
            picked=payload()
        else:
            picked=wait_state(lambda v:((v.get('exploration') or {}).get('session') or {}).get('carried')==[offer],'actual pickup confirmed',timeout=15000)""")
s=s.replace("page.wait_for_timeout(1200);snap('pickup-confirmed')","page.wait_for_timeout(1200);snap('pickup-retained-in-memory' if mode=='pickup-abort' else 'pickup-confirmed')")
s=s.replace("retry=json.loads(input())","retry=json.loads(input())\n            (folder/'retry-coordinate.json').write_text(json.dumps({'point':retry,'chosen_from_actual_failure_screenshot':True,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())},indent=2),encoding='utf-8')")
old="root = Path(sys.argv[1]); root.mkdir(parents=True,exist_ok=True)"
assert s.count(old)==1
s=s.replace(old,old+"""
class Tee:
    def __init__(self,terminal,path):self.terminal=terminal;self.file=path.open('w',encoding='utf-8')
    def write(self,value):self.terminal.write(value);self.file.write(value);self.file.flush();return len(value)
    def flush(self):self.terminal.flush();self.file.flush()
sys.stdout=Tee(sys.stdout,root/'driver.log')""")
(folder/'browser-nearby-web-storage-fault-resolve-oct11.py').write_text(s,encoding='utf-8')
