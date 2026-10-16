from pathlib import Path
import json,hashlib
folder=Path(__file__).resolve().parent
m=json.loads((folder/'video-parts.json').read_text(encoding='utf-8'))
chunks=[]
for part in m['parts']:
 b=(folder/Path(part['path']).name).read_bytes()
 assert len(b)==part['bytes'] and hashlib.sha256(b).hexdigest()==part['sha256']
 chunks.append(b)
b=b''.join(chunks)
assert len(b)==m['bytes'] and hashlib.sha256(b).hexdigest()==m['sha256']
p=folder/m['original_file']
if p.exists(): assert p.read_bytes()==b,'Existing file differs; preserve it first'
else: p.write_bytes(b)
print(str(p),len(b),hashlib.sha256(b).hexdigest())
