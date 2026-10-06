from pathlib import Path
from PIL import Image
import numpy as np,json
P=Path('/dev/shm/camera400-bounds-candidate-qa')
def match_group(baseline,box,names,dx_range,dy_range):
 base=np.asarray(Image.open(P/baseline).convert('RGB'),dtype=np.int16)
 x0,y0,x1,y1=box;ref=base[y0:y1,x0:x1];res=[]
 for name in names:
  im=np.asarray(Image.open(P/name).convert('RGB'),dtype=np.int16); best=None
  for dy in dy_range:
   for dx in dx_range:
    x=x0+dx;y=y0+dy
    patch=im[y:y+y1-y0,x:x+x1-x0]
    if patch.shape!=ref.shape:continue
    mae=float(np.abs(ref-patch).mean())
    if best is None or mae<best[0]:best=(mae,dx,dy)
  res.append({'image':name,'delta_pixels_from_baseline':[best[1],best[2]],'mean_absolute_channel_difference':best[0]})
 return {'baseline':baseline,'baseline_box_xyxy':box,'search_dx':[min(dx_range),max(dx_range)],'search_dy':[min(dy_range),max(dy_range)],'results':res}
portrait=match_group('portrait-01-entered.png',[204,122,231,153],[x.name for x in sorted(P.glob('portrait-0[234567]-*.png'))],range(-40,11),range(-5,161))
landscape=match_group('landscape-01-reflow-baseline.png',[379,115,405,132],[x.name for x in sorted(P.glob('landscape-0[234567]-*.png'))],range(-8,9),range(-10,31))
result={'method':'Offline read-only RGB patch nearest match in untouched full PNGs; exhaustive small translation search and mean absolute RGB difference. Approximate visual landmark displacement only, not camera offset or proof of engine quiet phase. Excludes last two portraits because weather changed. No image edits/crops saved.','portrait':portrait,'landscape':landscape}
(P/'landmark-analysis.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
r=json.loads((P/'result.json').read_text());anchors={e['timing_anchor']:e['anchor_monotonic'] for e in r['inputs'] if 'timing_anchor'in e};rows=[]
for e in r['inputs']:
 if 'screenshot_request'not in e and 'screenshot_complete'not in e:continue
 n=e.get('screenshot_request',e.get('screenshot_complete'))
 anchor='first_cancel_release' if n.startswith('landscape-0') else 'entered'
 rows.append({'image':n+'.png','event':'request'if 'screenshot_request'in e else 'complete','utc':e['utc'],'relative_to':anchor,'elapsed_ms':round((e['monotonic']-anchors[anchor])*1000,3)})
(P/'timing-analysis.json').write_text(json.dumps({'method':'Subtract actual input-acknowledgement Python monotonic timestamps from actual screenshot request/completion timestamps; not game clock or exact rendered frame timestamp. Negative title times precede actual ordinary entry.','anchors':anchors,'screenshots':rows},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False));print('TIMING',json.dumps([x for x in rows if x['event']=='request'],ensure_ascii=False))
