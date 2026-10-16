import pathlib,cv2,json,sys
from PIL import Image,ImageDraw
R=pathlib.Path(__file__).parent;x=json.loads((R/'web-sequence.json').read_text('utf-8'));assert x['pass'] and x['source']==(sys.argv[1] if len(sys.argv)>1 else 'b031894c79e39f8323ba29bd53ffe1f6aacd9941')
ends=[]
for stage in [1,2,3]:ends.append(next(r['seconds'] for r in x['records'] if r.get('stove',{}).get('revision')==stage))
times=[(i,e-9+n/5) for i,e in enumerate(ends) for n in range(12)]
c=cv2.VideoCapture(str(R/'stove-continuous.webm'));samples=[];index=0;decoded=0;last=0
while True:
 ok,f=c.read()
 if not ok:break
 decoded+=1;last=c.get(cv2.CAP_PROP_POS_MSEC)/1000
 while index<len(times) and last>=times[index][1]:
  stage,t=times[index];frame=Image.fromarray(cv2.cvtColor(f,cv2.COLOR_BGR2RGB)).crop((250,350,490,575));out=Image.new('RGB',(240,250),'#fff4de');out.paste(frame,(0,25));ImageDraw.Draw(out).text((5,6),f'Stage {stage+1} / {last:.2f}s',fill='black');samples.append(out);index+=1
c.release();assert len(samples)==36
small=[f.quantize(colors=64,dither=Image.Dither.NONE) for f in samples]
small[0].save(R/'stove-three-heights-preview.gif',save_all=True,append_images=small[1:],duration=200,loop=0,optimize=True)
sheet=Image.new('RGB',(6*240,3*250),'#fff4de')
for row in range(3):
 for col,n in enumerate([0,2,4,6,8,10]):sheet.paste(samples[row*12+n],(col*240,row*250))
sheet.save(R/'web-final-motion-contact-sheet.jpg',quality=92)
facts={'source':x['source'],'pass':True,'decoded_frames':decoded,'last_timestamp_seconds':last,'stage_end_seconds':ends,'preview':'3 separate 2.4-second actual Web excerpts at original playback speed, sampled at 5fps; 1:1 crop, not the complete continuous sequence','gif_bytes':(R/'stove-three-heights-preview.gif').stat().st_size}
(R/'video-final-inspection.json').write_bytes(json.dumps(facts,ensure_ascii=False,indent=2).encode());print(json.dumps(facts))
