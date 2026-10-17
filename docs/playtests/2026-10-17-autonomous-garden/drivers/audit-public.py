from pathlib import Path
import urllib.request,hashlib,json,sys,re,datetime,subprocess
source=sys.argv[1]
out=Path(__file__).parent/'public-files';out.mkdir(exist_ok=True)
base='https://narutojzm1-dot.github.io/youjia/'
def download(url,path=None):
    h=hashlib.sha256();size=0;chunks=[]
    with urllib.request.urlopen(urllib.request.Request(url,headers={'Cache-Control':'no-cache','User-Agent':'youjia-release-verification'}),timeout=60) as r:
        target=path.open('wb') if path else None
        try:
            while chunk:=r.read(1024*1024):
                h.update(chunk);size+=len(chunk)
                if target:target.write(chunk)
                if not path:chunks.append(chunk)
        finally:
            if target:target.close()
    return size,h.hexdigest(),b''.join(chunks) if not path else None
gh=r'C:/Program Files/GitHub CLI/gh.exe'
sha=json.loads(subprocess.check_output([gh,'api','repos/narutojzm1-dot/youjia/git/ref/heads/gh-pages']))['object']['sha']
fixed='https://raw.githubusercontent.com/narutojzm1-dot/youjia/'+sha+'/'
manifest_bytes=download(base+'game-release.json')[2];manifest=json.loads(manifest_bytes)
assert manifest['sourceCommit']==source,(source,manifest['sourceCommit'])
html=download(base+'index.html')[2];assert ('data-build="game-'+source[:7]+'"').encode() in html
config=json.loads(re.search(rb'const config = (\{.*?\});',html).group(1))
paths={'index.html':None,'game-release.json':None,manifest['entry']+'.pck':config['fileHashes'][manifest['entry']+'.pck']}
for name,digest in manifest['engineAssets']['sha256'].items():paths[name]=digest
for key in ['storageModules','loaderModules']:
    for name,digest in manifest[key]['sha256'].items():paths[manifest[key]['entry']+'/'+name]=digest
repo=Path(r'C:/Users/jiangzengming/.codex/worktrees/growth-garden-700/youjia')
for name in ['store.mjs','budgets.mjs','legacy_seal.mjs']:
    raw=subprocess.check_output(['git','show',source+':test/photo_writer_epoch/old-15fc174/'+name],cwd=repo)
    paths['save-15fc174/'+name]=hashlib.sha256(raw).hexdigest()
result={'source':source,'gh_pages_commit':sha,'recorded_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'full_files':[],'public_base':base,'fixed_base':fixed,'prior_writer3_modules':'save-15fc174; exact hashes from frozen raw Git blobs in source commit test/photo_writer_epoch/old-15fc174'}
for name,expected in paths.items():
    p=out/'public'/name;p.parent.mkdir(parents=True,exist_ok=True)
    size,digest,_=download(base+name,p)
    if expected:assert digest==expected,(name,digest,expected)
    fs,fh,_=download(fixed+name)
    assert (size,digest)==(fs,fh),(name,'public/fixed mismatch')
    if name in ['index.html','game-release.json']:
        q=out/'fixed'/name;q.parent.mkdir(parents=True,exist_ok=True);download(fixed+name,q)
    result['full_files'].append({'path':name,'bytes':size,'sha256':digest,'public_and_fixed_complete':True})
    print(name,size,digest,flush=True)
result['pass']=True;result['complete_downloads']=len(paths)*2
(out/'audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print('PUBLIC_AUDIT_PASS',result['complete_downloads'],flush=True)
