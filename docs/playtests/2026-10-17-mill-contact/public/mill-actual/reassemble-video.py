from pathlib import Path
import json,hashlib
p=Path(__file__).parent;m=json.loads((p/'video-parts.json').read_text());data=[]
for x in m['parts']:
 f=p/x['name'];assert f.resolve().parent==p.resolve();b=f.read_bytes();assert len(b)==x['bytes'] and hashlib.sha256(b).hexdigest()==x['sha256'];data.append(b)
b=b''.join(data);assert len(b)==m['original_bytes'] and hashlib.sha256(b).hexdigest()==m['original_sha256'];out=p/'mill-continuous.webm'
if out.exists():assert out.read_bytes()==b
else:out.write_bytes(b)
print('FULL_ORIGINAL_VIDEO_REASSEMBLED',len(b),hashlib.sha256(b).hexdigest())
