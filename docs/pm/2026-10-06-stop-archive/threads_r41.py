import subprocess,json,concurrent.futures
repo='repos/narutojzm1-dot/youjia/'
def api(p):
 for i in range(3):
  r=subprocess.run(['gh','api',repo+p,'--paginate'],capture_output=True)
  if r.returncode==0:
   s=r.stdout.decode();d=json.JSONDecoder();a=[]
   while s.strip():v,n=d.raw_decode(s.lstrip());a+=v if isinstance(v,list)else[v];s=s.lstrip()[n:]
   return a
 raise RuntimeError(r.stderr.decode())
nums=[242,168,51,155,375,382,459,470,400,476,478,479,473,130,456,153]

def run(n):
 x={'issue':api('issues/'+str(n)),'comments':api('issues/'+str(n)+'/comments?per_page=100')}
 if 'pull_request' in x['issue'][0]:x.update({'pr':api('pulls/'+str(n)),'reviews':api('pulls/'+str(n)+'/reviews?per_page=100'),'inline':api('pulls/'+str(n)+'/comments?per_page=100')})
 open('/workspace/pm-audit/r41-thread-'+str(n)+'.json','w').write(json.dumps(x,ensure_ascii=False));return n,len(x['comments'])
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as p:
 for x in p.map(run,nums):print(x)
