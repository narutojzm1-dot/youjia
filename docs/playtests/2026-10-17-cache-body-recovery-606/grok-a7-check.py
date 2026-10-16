import pathlib,subprocess,json,hashlib,cv2,numpy as np
r=pathlib.Path(__file__).parent/'grok804-a7';r.mkdir(exist_ok=True);repo='C:/Users/Zengm/.codex/worktrees/ui-audio-704/youjia';head='a7c3b47ce31333e5d1ffef49f894e5cba9d5d6b2';prefix='art/concepts/env_fx_stream_20261014/'
rows=[]
for name in ['README.md','verify_realtime_movie.py','godot_preview/stream_flow_driver.gd','stream_flow_realtime_30fps_40s.mp4','stream_flow_realtime_creek_8s.gif']:
 b=subprocess.check_output(['git','-C',repo,'show',head+':'+prefix+name],timeout=45);f=r/name;f.parent.mkdir(exist_ok=True);f.write_bytes(b);rows.append({'file':name,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
c=cv2.VideoCapture(str(r/'stream_flow_realtime_30fps_40s.mp4'));fps=c.get(cv2.CAP_PROP_FPS);n=int(c.get(cv2.CAP_PROP_FRAME_COUNT));w=int(c.get(cv2.CAP_PROP_FRAME_WIDTH));h=int(c.get(cv2.CAP_PROP_FRAME_HEIGHT));assert (fps,n,w,h)==(30.,1200,1280,720)
prev=None;diff=[];tiles=[];idx=0;inds={0,*[int(t*fps)+off for t in [8,16,24,32] for off in [-1,0,1]],1199}
while True:
 ok,cur=c.read()
 if not ok:break
 if prev is not None:diff.append(float(np.mean(cv2.absdiff(cur,prev))))
 if idx in inds:
  tile=cv2.resize(cur,(384,216));cv2.putText(tile,f'{idx/fps:.3f}s',(5,18),cv2.FONT_HERSHEY_SIMPLEX,.5,(0,0,255),1);tiles.append(tile)
 prev=cur;idx+=1
c.release();assert idx==n
while len(tiles)%3:tiles.append(np.zeros_like(tiles[0]))
cv2.imwrite(str(r/'contact.jpg'),np.vstack([np.hstack(tiles[i:i+3]) for i in range(0,len(tiles),3)]))
result={'head':head,'files':rows,'video':{'fps':fps,'frames':n,'decoded':idx,'seconds':n/fps,'width':w,'height':h,'rgb_step_median':float(np.median(diff)),'rgb_step_max':max(diff),'boundary_rgb_steps':[diff[round(t*fps)-1] for t in [8,16,24,32]]},'original_PNG_sequence_not_available':True,'movie_maker_fixed_step_not_real_time_performance':True,'mp4_lossy_not_exact_pixel_gate':True}
(r/'independent-video.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
