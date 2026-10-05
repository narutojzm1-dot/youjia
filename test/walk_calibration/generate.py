"""Deterministic 4 px grid calibration; no runtime or asset changes."""
import json,math,re,hashlib,subprocess
from pathlib import Path
from collections import deque
ROOT=Path(__file__).resolve().parents[2]
s=(ROOT/'scripts/game/yard_ground.gd').read_text().split('static func lawn()')[1].split('static func pen_and_lawn')[0]
base=[list(map(float,p)) for p in re.findall(r'Vector2\((\d+), (\d+)\)',s)]
assert len(base)==14
polys={'current':base,'door_lower':base[:12]+[[310,672],[165,630],[175,570]],'left_bank':base[:10]+[[520,564],[390,616],[300,648],[185,600]],'fence_front':base[:8]+[[918,556],[760,550]]+base[10:]}
# These are explicit tentative vertices, never painted collision truth.
obstacles=[(636,452,24,11),(400,516,36,13),(560,505,36,13),(812,496,14,8),(990,448,23,10),(1088,505,23,10)]
def depth(y):return .82+.36*max(0,min(1,(y-420)/230))
def inside(x,y,p):
 c=False
 for a,b in zip(p,p[1:]+p[:1]):
  if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:c=not c
 return c
# Conservative constant maximum-depth footprint; normalized edge distance is exact ellipse-to-line erosion.
def margin(x,y,p):
 for a,b in zip(p,p[1:]+p[:1]):
  ax,ay=(a[0]-x)/11.8,(a[1]-y)/7.08; bx,by=(b[0]-x)/11.8,(b[1]-y)/7.08
  dx,dy=bx-ax,by-ay;t=max(0,min(1,-(ax*dx+ay*dy)/(dx*dx+dy*dy)))
  if (ax+t*dx)**2+(ay+t*dy)**2<1:return False
 return True
def allowed(x,y,p,safe=False,animals=False):
 if not inside(x,y,p):return False
 # Triangle inequality in pond-normalized coordinates gives a conservative Minkowski enclosure.
 factor=1+max(11.8/148,7.08/52) if safe else 1
 rx,ry=148*factor,52*factor
 if ((x-705)/rx)**2+((y-592)/ry)**2<=1:return False
 if safe and not margin(x,y,p):return False
 if animals:
  for ox,oy,rx,ry in obstacles:
   d=depth(oy)
   if ((x-ox)/(rx*d+11.8+2))**2+((y-oy)/(ry*d+7.08+2))**2<=1:return False
 return True
def component(cells,start):
 if not cells:return [],{}
 seed=min(cells,key=lambda p:(p[0]-start[0])**2+(p[1]-start[1])**2);prev={seed:None};q=deque([seed])
 while q:
  x,y=q.popleft()
  for n in [(x+4,y),(x-4,y),(x,y+4),(x,y-4)]:
   if n in cells and n not in prev:prev[n]=(x,y);q.append(n)
 return list(prev),prev
results={}
for name,p in polys.items():
 foot={(x,y) for y in range(400,688,4) for x in range(140,944,4) if allowed(x,y,p)}
 safe={v for v in foot if allowed(*v,p,True)}
 occupied={v for v in safe if allowed(*v,p,True,True)}
 connected,prev=component(occupied,(260,540))
 # Four-neighbour graph path lengths are metric-specific, not runtime route lengths or graph diameter.
 dist={};
 for v in connected:dist[v]=0 if prev[v] is None else dist[prev[v]]+4
 far=max(dist,key=dist.get);route=[];v=far
 while v is not None:route.append(v);v=prev[v]
 area=abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(p,p[1:]+p[:1])))/2
 results[name]={'polygon':p,'polygon_area_exact':area,'foot_area_sampled':len(foot)*16,'safe_area_sampled':len(safe)*16,'sunny_spawn_free_area_sampled':len(occupied)*16,'spawn_component_area_sampled':len(connected)*16,'component_fraction':len(connected)/len(occupied),'longest_shortest_route_from_spawn_grid':dist[far],'route':route[::-1],'safe_points':list(sorted(safe))}
assert results['current']['polygon_area_exact']==80924
out={'base':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'grid_px':4,'render_rect':[0,0,1280,720],'footprint_max':[11.8,7.08],'pond':[705,592,148,52],'sunny_spawn_obstacles':obstacles,'backgrounds':{k:hashlib.sha256((ROOT/f'assets/holiday/environment/yard_{k}.png').read_bytes()).hexdigest() for k in ['sunny','overcast']},'candidates':results}
Path(__file__).with_name('data.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
for k,v in results.items():print(k,{a:b for a,b in v.items() if a not in ['polygon','route','safe_points']})
