from pathlib import Path
import json,time,sys
p=Path('/tmp/title439-public-qa');c=json.loads(sys.argv[1]);(p/'command.json').write_text(json.dumps(c));start=time.monotonic()
while time.monotonic()-start<45:
 if (p/'done').exists() and (p/'done').read_text()==c['name']:print(c['name']);break
 time.sleep(.2)
else:raise RuntimeError('command timeout')
