"""Recover the exact original evidence bytes; no image resizing/re-encoding.
Usage: python restore-archives.py OUTPUT_DIRECTORY (Python3.10+)
"""
from pathlib import Path
import hashlib,json,tarfile,io,sys
root=Path(__file__).resolve().parent
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
def digest(data):return hashlib.sha256(data).hexdigest()
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
count=0
for f in sorted(root.glob('*-archive.json')):
    m=json.loads(f.read_text(encoding='utf-8'));raw=(root/m['file']).read_bytes()
    assert len(raw)==m['bytes'] and digest(raw)==m['sha256'] and blob(raw)==m['git_blob'],m['file']
    expected={v['path']:v for v in m['originals']}
    with tarfile.open(fileobj=io.BytesIO(raw),mode='r:xz') as archive:
        members=archive.getmembers();assert {v.name for v in members}==set(expected)
        for entry in members:
            assert entry.isfile() and not entry.issym() and not entry.islnk()
            target=(out/m['label']/entry.name).resolve();assert target.is_relative_to(out)
            data=archive.extractfile(entry).read();v=expected[entry.name]
            assert len(data)==v['bytes'] and digest(data)==v['sha256'] and blob(data)==v['git_blob']
            target.parent.mkdir(parents=True,exist_ok=True)
            if target.exists():assert target.read_bytes()==data,'Refuse to overwrite differing file'
            else:target.write_bytes(data)
            count+=1
print(json.dumps({'originals_verified_and_restored':count,'destination':str(out)}))
