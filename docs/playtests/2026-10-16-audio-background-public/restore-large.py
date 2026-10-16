import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parent
if len(sys.argv)!=2:raise SystemExit('python restore-large.py OUTPUT_DIRECTORY')
out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
for f in json.loads((root/'large-artifacts.json').read_text(encoding='utf-8'))['files']:
    chunks=[]
    for p in f['parts']:
        data=(root/p['path']).read_bytes()
        assert len(data)==p['bytes'] and hashlib.sha256(data).hexdigest()==p['sha256']
        chunks.append(data)
    data=b''.join(chunks)
    assert len(data)==f['bytes'] and hashlib.sha256(data).hexdigest()==f['sha256']
    assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==f['git_blob']
    dest=(out/f['path']).resolve();assert dest.is_relative_to(out)
    if dest.exists():assert dest.read_bytes()==data
    else:dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
    print(f['path'],f['sha256'])
