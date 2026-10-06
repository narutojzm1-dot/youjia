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
jobs={'comments':'issues/comments?since=2026-10-06T01:19:00Z&per_page=100','open':'issues?state=open&per_page=100','prs':'pulls?state=open&per_page=100','main':'commits/main'}
def run(k):
 v=api(jobs[k]);Path('/workspace/pm-audit/r41-'+k+'.json').write_text(json.dumps(v,ensure_ascii=False));return k,len(v)
from pathlib import Path
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as p:
 for x in p.map(run,jobs):print(x)
