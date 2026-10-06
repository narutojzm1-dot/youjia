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
old=parse('/tmp/gate130-export/index.pck');new=parse('/dev/shm/photo447-preview/index.pck')
missing={k:old['files'][k] for k in old['files'].keys()-new['files'].keys()}
added={k:new['files'][k] for k in new['files'].keys()-old['files'].keys()}
changed={k:{'before':old['files'][k],'after':new['files'][k],'byte_delta':new['files'][k]['bytes']-old['files'][k]['bytes']} for k in old['files'].keys()&new['files'].keys() if old['files'][k]!=new['files'][k]}
r={'reviewer':'/root/leader_scope_audit','method':'Read-only PCK v4 directory parse; every member payload checked against its stored MD5, comparison SHA256 per payload','before':{k:v for k,v in old.items() if k!='files'},'after':{k:v for k,v in new.items() if k!='files'},'removed':missing,'added':added,'changed':changed,'same_members':len(new['files'])-len(added)-len(changed),'full_before_files':old['files'],'full_after_files':new['files']}
Path('/tmp/photo447-pck-independent.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({k:v for k,v in r.items() if not k.startswith('full_')},indent=2))
