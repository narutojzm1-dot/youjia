from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np, cv2, json, hashlib
p=Path(__file__).parent
source=p.parent/'stone-v2/revision_v2_unaccepted.png'
raw=np.array(Image.open(source).convert('RGBA'))
_,labels,stats,_=cv2.connectedComponentsWithStats((raw[:,:,3]>=128).astype(np.uint8))
component=1+np.argmax(stats[1:,cv2.CC_STAT_AREA])
support=cv2.dilate((labels==component).astype(np.uint8),cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(7,7)))>0
clean=raw.copy(); clean[~support]=0; clean[clean[:,:,3]==0]=0
box=Image.fromarray(clean[:,:,3]).getbbox()
x0,y0,x1,y1=box
box=(max(0,x0-2),max(0,y0-2),min(raw.shape[1],x1+2),min(raw.shape[0],y1+2))
Image.fromarray(clean).crop(box).save(p/'stone_trimmed.png')
sprite=Image.open(p/'stone_trimmed.png')
sheet=Image.new('RGB',(900,340),'#fff6e8'); d=ImageDraw.Draw(sheet)
for i,color in enumerate(['#fff6e8','#567149','#332d2b']):
 x=i*300;d.rectangle((x,0,x+299,339),fill=color)
 for width,y in [(240,20),(64,175),(24,270)]:
  size=(width,round(sprite.height*width/sprite.width))
  thumb=sprite.resize(size,Image.Resampling.LANCZOS)
  sheet.paste(thumb,(x+(300-width)//2,y),thumb)
sheet.save(p/'edge-and-size-check.png')
record={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256((p/'stone_trimmed.png').read_bytes()).hexdigest(),'crop_xyxy':box,'size':sprite.size,'anchor_candidate':[round(780-box[0],2),round(860-box[1],2)],'opaque_rgb_changed':int(np.count_nonzero(np.any(raw[:,:,:3]!=clean[:,:,:3],axis=2)&(raw[:,:,3]>=128))),'removed_nonzero_alpha_pixels':int(np.count_nonzero((raw[:,:,3]>0)&(clean[:,:,3]==0))),'method':'largest alpha>=128 component, retain original 3px edge band; zero transparent RGB; crop +2px padding','status':'candidate awaiting independent art review and runtime overlap validation'}
(p/'measurements.json').write_text(json.dumps(record,indent=2));print(json.dumps(record))
