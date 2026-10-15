import concurrent.futures,subprocess,urllib.request,hashlib,json,time
from pathlib import Path
root=Path(r'C:\Users\Zengm\AppData\Local\Temp\youjia-stream804-gpu')
repo=Path(r'C:\Users\Zengm\.codex\worktrees\ui-audio-704\youjia')
prefix='art/concepts/env_fx_stream_20261014/godot_preview'
sha='2e03211f3e3f850b27f7d8236b10ce5e7fe13e41'
tree=subprocess.check_output(['git','ls-tree','-rz',sha,'--',prefix],cwd=repo)
items=[]
for record in tree.split(b'\0'):
    if not record:continue
    meta,name=record.split(b'\t');mode,kind,blob=meta.decode().split();assert mode=='100644' and kind=='blob'
    items.append((name.decode(),blob))
def fetch(item):
    name,blob=item;url=f'https://raw.githubusercontent.com/narutojzm1-dot/youjia/{sha}/{name}'
    for attempt in range(2):
        try:
            with urllib.request.urlopen(url,timeout=45) as r:data=r.read()
            actual=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest();assert actual==blob
            dest=root/name;assert dest.resolve().is_relative_to(root.resolve());dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
            return {'file':name,'bytes':len(data),'git_blob':blob,'verified':True}
        except Exception as e:
            if attempt==1:return {'file':name,'error':str(e)}
root.mkdir(exist_ok=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(fetch,items))
(root/'source-download.json').write_text(json.dumps({'sha':sha,'files':results},indent=2))
print(json.dumps({'files':len(results),'verified':sum(x.get('verified',False) for x in results),'errors':[x for x in results if 'error' in x]}))
