import sys,json,hashlib,urllib.request,subprocess,re,concurrent.futures,datetime
expected,out=sys.argv[1:]
bases=['https://narutojzm1-dot.github.io/youjia/','https://raw.githubusercontent.com/narutojzm1-dot/youjia/gh-pages/']
checked_stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S%f')
def get(url):
 fresh=url+('\x26' if '?' in url else '?')+'release_check='+checked_stamp
 req=urllib.request.Request(fresh,headers={'Cache-Control':'no-cache'})
 with urllib.request.urlopen(req,timeout=60) as r:return r.read(),r.headers.get('content-type','')
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
 manifests=list(pool.map(lambda b:json.loads(get(b+'game-release.json')[0]),bases))
 assert manifests[0]==manifests[1],manifests
 m=manifests[0];assert m['sourceCommit']==expected,m
 pcks=list(pool.map(lambda b:get(b+m['entry']+'.pck')[0],bases));assert pcks[0]==pcks[1]
 html=get(bases[0]+'index.html')[0].decode();assert 'data-build="'+m['entry']+'"' in html
 modules=m['storageModules'];assert modules['entry']=='save-'+expected[:7]
 assert './'+modules['entry']+'/' in html and './web/save/' not in html
 def verify(item):
  name,want=item;rows=[get(b+modules['entry']+'/'+name) for b in bases]
  content=rows[0][0];assert rows[1][0]==content and hashlib.sha256(content).hexdigest()==want
  source=get('https://raw.githubusercontent.com/narutojzm1-dot/youjia/'+expected+'/web/save/'+name)[0]
  assert source==content
  assert 'javascript' in rows[0][1],(name,rows[0][1])
  return {'name':name,'bytes':len(content),'sha256':want,'public_raw_source_equal':True,'content_type':rows[0][1]}
 verified=list(pool.map(verify,modules['sha256'].items()))
r={'cache_bust_stamp':checked_stamp,'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'manifest':m,'pck':{'bytes':len(pcks[0]),'sha256':hashlib.sha256(pcks[0]).hexdigest(),'public_raw_equal':True},'html_build_and_module_entry':True,'modules':verified}
open(out,'w').write(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
