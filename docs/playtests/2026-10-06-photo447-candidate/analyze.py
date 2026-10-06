"""Read-only screenshot/envelope analysis. Never contacts or changes the game."""
from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parent
expected=[243,227,203]
rows=[]
for case in ['portrait-normal','portrait-reduce','landscape-normal','landscape-reduce']:
 points=[(96,390),(295,390),(195,294),(195,493)] if case.startswith('portrait') else [(198,150),(369,150),(284,70),(284,244)]
 for p in sorted(ROOT.glob(case+'-photo-*.png')):
  im=Image.open(p).convert('RGB');pixels=[list(im.getpixel(xy)) for xy in points]
  rows.append({'case':case,'file':p.name,'points_xy':points,'side_order':['left','right','top','bottom'],'pixels_rgb':pixels,'four_points_equal_mat_color':all(v==expected for v in pixels)})
(ROOT/'mat-samples.json').write_text(json.dumps({'expected_color_hex':'#f3e3cb','expected_rgb':expected,'note':'Four interior points supplement visual inspection; not every edge pixel. Nonmatching early/fade frames are not full-hold failures.','frames':rows},indent=2)+'\n')
def records(filename):
 data=json.loads((ROOT/filename).read_text());out={}
 for db in data.values():
  st=db.get('records',{})
  for k,v in zip(st.get('keys',[]),st.get('values',[])):
   if isinstance(v,dict) and 'payload_bytes' in v:out[str(k)]=v
 return out
before=records('portrait-normal-db.json');after=records('portrait-normal-reopened-db.json')
bp=json.loads(before['current']['payload_bytes']);ap=json.loads(after['current']['payload_bytes'])
summary={'cases':[],'reopened':{'scope':'actual page close/new page in same browser context; browser process never restarted','before_generation':before['current']['generation'],'after_generation':after['current']['generation'],'whole_current_equal':before['current']==after['current'],'album_equal':bp['album']==ap['album'],'photo_moments_equal':bp['photo_moments']==ap['photo_moments'],'album':bp['album'],'photo_rule_ids':list(bp['photo_moments'])}}
for case in ['portrait-normal','portrait-reduce','landscape-normal','landscape-reduce']:
 rec=records(case+'-db.json');payload=json.loads(rec['current']['payload_bytes']);summary['cases'].append({'case':case,'generation':rec['current']['generation'],'album':payload['album'],'photo_rule_ids':list(payload['photo_moments']),'photo_moments_sha256':hashlib.sha256(json.dumps(payload['photo_moments'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()})
(ROOT/'storage-readonly-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
