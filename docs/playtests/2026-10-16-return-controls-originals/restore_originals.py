from pathlib import Path
import json,hashlib,zipfile,tarfile,io,sys
root=Path(__file__).resolve().parent;out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
def digest(b):return hashlib.sha256(b).hexdigest()
m=json.loads((root/'manifest.json').read_text());parts=[]
for p in m['parts']:
 b=(root/p['path']).read_bytes();assert len(b)==p['bytes'] and digest(b)==p['sha256'];parts.append(b)
raw=b''.join(parts);assert len(raw)==m['zip_bytes'] and digest(raw)==m['zip_sha256']
def write(path,b):
 p=(out/path).resolve();assert p.is_relative_to(out);p.parent.mkdir(parents=True,exist_ok=True)
 if p.exists():assert p.read_bytes()==b,'Refuse to overwrite differing file'
 else:p.write_bytes(b)
write('youjia-return-controls-crop804.zip',raw)
z=zipfile.ZipFile(io.BytesIO(raw));assert set(z.namelist())=={p['path'] for p in m['zip_entries']}
for p in m['zip_entries']:
 b=z.read(p['path']);assert len(b)==p['bytes'] and digest(b)==p['sha256']
count=0
for n in z.namelist():
 if not n.endswith('-archive.json'):continue
 a=json.loads(z.read(n));data=z.read(a['file']);assert len(data)==a['bytes'] and digest(data)==a['sha256'];expected={p['path']:p for p in a['originals']}
 with tarfile.open(fileobj=io.BytesIO(data),mode='r:xz') as t:
  assert {p.name for p in t.getmembers()}==set(expected)
  for p in t.getmembers():
   assert p.isfile() and not p.issym() and not p.islnk();b=t.extractfile(p).read();e=expected[p.name];assert len(b)==e['bytes'] and digest(b)==e['sha256'];write('originals/'+a['label']+'/'+p.name,b);count+=1
assert count==m['originals']==54
print(json.dumps({'originals_restored_and_verified':count,'zip_bytes':len(raw),'zip_sha256':digest(raw)}))
