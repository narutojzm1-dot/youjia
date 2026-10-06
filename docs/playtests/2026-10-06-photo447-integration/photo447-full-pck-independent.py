from pathlib import Path
import struct,hashlib,json

def parse(p):
 b=Path(p).read_bytes(); magic,fmt,major,minor,patch,flags=struct.unpack_from('<6I',b)
 assert b[:4]==b'GDPC' and fmt==4 and flags==2,(fmt,flags)
 base,diroff=struct.unpack_from('<QQ',b,24);count=struct.unpack_from('<I',b,diroff)[0];pos=diroff+4
 out={}
 for _ in range(count):
  length=struct.unpack_from('<I',b,pos)[0];pos+=4
  name=b[pos:pos+length].rstrip(b'\0').decode();pos+=length
  offset,size=struct.unpack_from('<QQ',b,pos);pos+=16
  md5=b[pos:pos+16].hex();pos+=16
  ef=struct.unpack_from('<I',b,pos)[0];pos+=4
  data=b[base+offset:base+offset+size]
  assert len(data)==size and hashlib.md5(data).hexdigest()==md5,(name,offset,size,ef)
  assert name not in out,name
  out[name]={'bytes':size,'md5':md5,'sha256':hashlib.sha256(data).hexdigest(),'flags':ef}
 return {'path':str(p),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'format':fmt,'version':[major,minor,patch],'flags':flags,'count':count,'directory_offset':diroff,'directory_end':pos,'files':out}
import subprocess
old=parse('/dev/shm/photo447-preview/index.pck')
new=parse('/dev/shm/photo447-full-export/index.pck')
added={k:new['files'][k] for k in new['files'].keys()-old['files'].keys()}
removed={k:old['files'][k] for k in old['files'].keys()-new['files'].keys()}
changed={k:{'before':old['files'][k],'after':new['files'][k]} for k in old['files'].keys()&new['files'].keys() if old['files'][k]!=new['files'][k]}
assert set(added)=={'game-sharing.json','game-verification.json','template.json','template-provenance.json'}
for name,entry in added.items():
    raw=subprocess.check_output(['git','show','d22f28f40d72d9860eb5bb267a7a45df84253fe1:'+name],cwd='/tmp/youjia-photo447')
    assert len(raw)==entry['bytes'] and hashlib.sha256(raw).hexdigest()==entry['sha256']
assert not removed and not changed
print(json.dumps({'source':'d22f28f40d72d9860eb5bb267a7a45df84253fe1','before':{k:v for k,v in old.items() if k!='files'},'after':{k:v for k,v in new.items() if k!='files'},'added':added,'removed':removed,'changed':changed,'identical_member_count':len(old['files'])},indent=2))
