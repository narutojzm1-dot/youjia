from pathlib import Path
import json,hashlib,cv2
from PIL import Image,ImageDraw
R=Path(__file__).parent;w=json.loads((R/'public-check/mill-actual/web-sequence.json').read_text());assert w['pass'] and w['actual_formal_site'];vpath=R/'public-check/mill-actual/mill-continuous.webm'
first=[next(x['seconds'] for x in w['records'] if x['production']['revision']==n) for n in [1,2]];starts=[max(0,x-6.4) for x in first];targets=[s+i/5 for s in starts for i in range(12)]
v=cv2.VideoCapture(str(vpath));captured={};j=0;n=0;last=0
while True:
 ok,im=v.read()
 if not ok:break
 n+=1;t=v.get(cv2.CAP_PROP_POS_MSEC)/1000;last=t
 while j<len(targets) and t>=targets[j]:captured[targets[j]]=Image.fromarray(cv2.cvtColor(im,cv2.COLOR_BGR2RGB));j+=1
v.release();assert len(captured)==len(targets),(j,len(targets),last)
crop=(490,305,650,465);frames=[captured[t].crop(crop).resize((320,320),Image.Resampling.LANCZOS) for t in targets]
frames[0].save(R/'public-mill-grip-preview.gif',save_all=True,append_images=frames[1:],duration=200,loop=0,optimize=False)
sheet=Image.new('RGB',(960,345),'#eee8d9');draw=ImageDraw.Draw(sheet)
for i,k in enumerate([0,5,17]):sheet.paste(frames[k],(i*320,25));draw.text((i*320+8,5),f'{targets[k]:.1f}s / public Web / 2x crop',fill='#222222')
sheet.save(R/'public-mill-grip-sheet.jpg',quality=92)
report={'source':w['source'],'actual_formal_site':True,'video_bytes':vpath.stat().st_size,'video_sha256':hashlib.sha256(vpath.read_bytes()).hexdigest(),'decoded_frames':n,'last_ms':last*1000,'excerpt_starts_seconds':starts,'each_excerpt_seconds':2.4,'gif_fps':5,'display_scale':2,'crop':crop,'play_speed':1,'not_native_resolution_or_hardware_performance':True,'sequential_full_decode':True}
(R/'public-mill-video-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
