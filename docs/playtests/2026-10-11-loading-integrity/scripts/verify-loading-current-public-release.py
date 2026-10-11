"""Verify deployed bytes against Pages Git blob IDs without fetching large blobs twice."""
import hashlib,json,re,subprocess,time,urllib.request,sys,shutil
from pathlib import Path
REPO=Path(r'D:\games\youjia-test\assistant');OUT=Path(__file__).parent/'loading-current-public-release';OUT.mkdir(exist_ok=True)
BASE='https://narutojzm1-dot.github.io/youjia/'
EXPECTED=sys.argv[1]
stamp=str(int(time.time()))
def small(name):
 for attempt in range(3):
  try:
   req=urllib.request.Request(BASE+name,headers={'Cache-Control':'no-cache','Accept-Encoding':'identity'})
   with urllib.request.urlopen(req,timeout=20) as r:return r.read()
  except Exception:
   if attempt==2:raise
manifest_bytes=small('game-release.json?verify='+stamp);manifest=json.loads(manifest_bytes)
(OUT/('manifest-'+stamp+'.json')).write_bytes(manifest_bytes)
assert manifest['sourceCommit']==EXPECTED, 'public build has not reached the loading fix: '+manifest['sourceCommit']
html=small('?verify='+stamp).decode();(OUT/'index.html').write_text(html,encoding='utf-8')
cfg=json.loads(re.search(r'const config = (\{.*?\});',html)[1])
assert cfg['mainPack']==manifest['entry']+'.pck'
assert cfg['executable']==manifest['engineAssets']['entry']
assert './'+manifest['loaderModules']['entry']+'/download_assets.mjs' in html
for name,size in cfg['fileSizes'].items():
 if name.endswith('.wasm'):
  prior=Path(__file__).parent/'loading-public-release'/name
  if prior.is_file():shutil.copy2(prior,OUT/name)
 assert re.fullmatch(r'(?:engine-[0-9a-f]{64}\.wasm|game-[0-9a-f]+\.pck)',name)
 final=OUT/name;partial=OUT/(name+'.part')
 if final.exists() and final.stat().st_size==size:continue
 offset=partial.stat().st_size if partial.exists() else 0
 assert 0<=offset<=size
 with partial.open('ab') as f:
  while offset<size:
   end=min(size-1,offset+4*1048576-1)
   for attempt in range(3):
    try:
     req=urllib.request.Request(BASE+name,headers={'Range':f'bytes={offset}-{end}','Accept-Encoding':'identity'})
     with urllib.request.urlopen(req,timeout=20) as r:
      assert r.status==206 and r.headers.get('Content-Range')==f'bytes {offset}-{end}/{size}' and not r.headers.get('Content-Encoding')
      data=r.read(end-offset+2);assert len(data)==end-offset+1
     break
    except Exception:
     if attempt==2:raise
   f.write(data);f.flush();offset=end+1
   print(json.dumps({'file':name,'read':offset,'size':size}),flush=True)
 partial.replace(final)
results={}
names=list(cfg['fileSizes'])
for name in manifest['engineAssets']['sha256']:
 if name not in names:
  assert re.fullmatch(r'engine-[0-9a-f]{64}\.(?:js|audio\.worklet\.js|audio\.position\.worklet\.js)',name)
  (OUT/name).write_bytes(small(name));names.append(name)
for kind in ['storageModules','loaderModules']:
 entry=manifest[kind]['entry'];assert re.fullmatch(r'(save|boot)-[0-9a-f]+',entry)
 for name,digest in manifest[kind]['sha256'].items():
  assert re.fullmatch(r'[a-z0-9_]+\.mjs',name)
  path=entry+'/'+name;dest=OUT/path;dest.parent.mkdir(exist_ok=True);dest.write_bytes(small(path));names.append(path)
  assert hashlib.sha256(dest.read_bytes()).hexdigest()==digest,path
for name in names:
 data=(OUT/name).read_bytes();digest=hashlib.sha256(data).hexdigest()
 if name in manifest['engineAssets']['sha256']:assert digest==manifest['engineAssets']['sha256'][name]
 if name in cfg.get('fileHashes',{}):assert digest==cfg['fileHashes'][name],name+' differs from pinned HTML hash'
 actual=subprocess.check_output(['git','hash-object','--no-filters',str(OUT/name)],cwd=REPO,text=True).strip()
 tree=subprocess.check_output(['git','ls-tree','origin/gh-pages','--',name],cwd=REPO,text=True).strip()
 assert tree and tree.split()[2]==actual,name+' differs from actual Pages Git blob'
 results[name]={'bytes':len(data),'sha256':digest,'gitBlob':actual}
result={'source':EXPECTED,'entry':manifest['entry'],'engineEntry':cfg['executable'],'files':results,'verifiedAt':time.time(),'reusedPreviouslyVerifiedWasm':True}
(OUT/'verified.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2),flush=True)
