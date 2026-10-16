import pathlib,json,struct,hashlib,cv2,numpy as np
from PIL import Image,ImageDraw
r=pathlib.Path(__file__).parent;b=r/'grok-b739';proof=b/'keyframe_check_20261017';old=pathlib.Path('C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-0130/grok804-a7/stream_flow_realtime_30fps_40s.mp4');new=b/'stream_flow_realtime_30fps_40s_singlegop.mp4'
def sync_samples(raw):
 out=[]
 def walk(start,end):
  at=start
  while at+8<=end:
   size=struct.unpack_from('>I',raw,at)[0];kind=raw[at+4:at+8];header=8
   if size==1:size=struct.unpack_from('>Q',raw,at+8)[0];header=16
   if size==0:size=end-at
   assert size>=header and at+size<=end,(kind,at,size,end)
   if kind==b'stss':
    count=struct.unpack_from('>I',raw,at+header+4)[0];out.extend(v-1 for v in struct.unpack_from('>'+str(count)+'I',raw,at+header+8))
   elif kind in [b'moov',b'trak',b'mdia',b'minf',b'stbl']:walk(at+header,at+size)
   at+=size
 walk(0,len(raw));return out
def video(p):
 raw=p.read_bytes();cap=cv2.VideoCapture(str(p));fps=cap.get(cv2.CAP_PROP_FPS);n=int(cap.get(cv2.CAP_PROP_FRAME_COUNT));w=int(cap.get(cv2.CAP_PROP_FRAME_WIDTH));h=int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT));assert (fps,n,w,h)==(30,1200,1280,720)
 diffs=[];prev=None;frames={};count=0;tiles=[]
 want={*sum(([x-1,x] for x in [250,500,750,1000]),[]),1199}
 while True:
  ok,cur=cap.read()
  if not ok:break
  if prev is not None:diffs.append(float(cv2.absdiff(cur,prev).mean()))
  if count in want:
   frames[count]=cur.copy();tile=cv2.resize(cur,(384,216));cv2.putText(tile,f'{count} / {count/fps:.3f}s',(5,20),cv2.FONT_HERSHEY_SIMPLEX,.5,(0,0,255),1);tiles.append(tile)
  prev=cur;count+=1
 cap.release();assert count==n
 while len(tiles)%3:tiles.append(np.zeros_like(tiles[0]))
 cv2.imwrite(str(r/(p.stem+'-contact.jpg')),np.vstack([np.hstack(tiles[i:i+3]) for i in range(0,len(tiles),3)]))
 i=raw.find(b'keyint=');assert i>0
 return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'fps':fps,'frames':count,'dimensions':[w,h],'seconds':count/fps,'mp4_stss_sync_frames':sync_samples(raw),'x264_keyint_header':raw[i:i+90].split(b'\0')[0].decode('ascii',errors='replace'),'rgb_adjacent_median':float(np.median(diffs)),'rgb_adjacent_max':max(diffs),'rgb_adjacent_argmax':[int(np.argmax(diffs)),int(np.argmax(diffs))+1],'previous_spike_positions':[{'frame':x,'diff':diffs[x-1]} for x in [250,500,750,1000]]},frames
old_result,old_frames=video(old);new_result,new_frames=video(new)
assert old_result['mp4_stss_sync_frames']==[0,250,500,750,1000]
assert new_result['mp4_stss_sync_frames']==[0]
assert new_result['bytes']==916236 and new_result['sha256']=='054d983a4bee0660d189ba58ae667c595f4f4b5a3f51dfcf4d343aa1c4f81271'
assert new_result['rgb_adjacent_max']<.012
crops=[]
for first in [249,499]:
 for prefix in ['png_native','mp4_gop250','mp4_singlegop']:
  x=np.asarray(Image.open(proof/f'{prefix}_f{first:04d}_crop.png').convert('RGB'));y=np.asarray(Image.open(proof/f'{prefix}_f{first+1:04d}_crop.png').convert('RGB'));assert x.shape==y.shape
  d=np.abs(x.astype(np.int16)-y.astype(np.int16));crops.append({'prefix':prefix,'from':first,'to':first+1,'shape':list(x.shape),'mean':float(d.mean()),'max':int(d.max()),'changed_pixels':int(np.any(d,axis=2).sum())})
small=Image.new('RGB',(420*3,360*2))
for row,n in enumerate([249,250]):
 for col,prefix in enumerate(['png_native','mp4_gop250','mp4_singlegop']):
  im=Image.open(proof/f'{prefix}_f{n:04d}_crop.png').convert('RGB');im.thumbnail((420,360));small.paste(im,(col*420,row*360));ImageDraw.Draw(small).text((col*420+4,row*360+4),f'{prefix} frame{n}',fill='red')
small.save(r/'native-old-new-crop-contact.jpg',quality=90)
raw=(proof/'realtime_movie_raw.txt').read_text();assert '"ok": true' in raw
result={'head':'b739519cc52a41873a9eb19d2abb53abeff7bcbc','previous':'a7c3b47ce31333e5d1ffef49f894e5cba9d5d6b2','old_video_independent':old_result,'new_video_independent':new_result,'provided_lossless_crop_comparison':crops,'author_raw_realtime_movie_present':True,'full_1200_original_PNG_sequence_not_independently_recomputed':True,'fixed_step_movie_is_not_hardware_performance':True,'scope':'independent encoding-spike closure for provided samples and new full decoded demo; no production Host or final art acceptance'}
(r/'independent-b739.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=False))
