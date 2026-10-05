from pathlib import Path
import cv2, numpy as np, hashlib, json
from PIL import Image
root=Path(__file__).parent
source=root.parent/'near-path-cast-check/near_path.png'
im=np.array(Image.open(source).convert('RGB'))
mask=np.zeros(im.shape[:2],np.uint8)
polygons=[[(1263,789),(1275,779),(1290,781),(1303,793),(1308,810),(1300,823),(1280,827),(1266,820),(1260,805)],[(1357,783),(1375,770),(1400,765),(1420,769),(1424,794),(1416,818),(1392,831),(1365,837),(1356,817)]]
for p in polygons: cv2.fillPoly(mask,[np.array(p,np.int32)],255)
mask=cv2.dilate(mask,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(13,13)))
clean=im.copy()
for polygon, offset in zip(polygons, [(-65,-85),(-175,-60)]):
 local=np.zeros(im.shape[:2],np.uint8)
 cv2.fillPoly(local,[np.array(polygon,np.int32)],255)
 local=cv2.dilate(local,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(13,13)))
 x,y,w,h=cv2.boundingRect(local)
 donor=im[y+offset[1]:y+offset[1]+h,x+offset[0]:x+offset[0]+w].copy()
 patchmask=local[y:y+h,x:x+w].copy()
 print('region',x,y,w,h)
 blended=cv2.seamlessClone(donor,clean.copy(),patchmask,(x+w//2,y+h//2),cv2.NORMAL_CLONE)
 clean[local>0]=blended[local>0]
# Restore the adjacent purple leaf and its original edge; it is scenery, not a pickup.
leaf=np.zeros(mask.shape,np.uint8)
cv2.fillPoly(leaf,[np.array([(1334,783),(1341,778),(1347,781),(1345,788),(1356,787),(1366,789),(1369,793),(1361,797),(1352,796),(1348,802),(1342,799),(1335,801),(1331,795)],np.int32)],255)
leaf=cv2.dilate(leaf,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(5,5)))
restore=cv2.GaussianBlur(leaf.astype(np.float32)/255,(15,15),3)
restore[leaf>0]=1
clean=np.rint(clean*(1-restore[...,None])+im*restore[...,None]).astype(np.uint8)
mask[leaf>0]=0
clean[mask==0]=im[mask==0]
Image.fromarray(clean).save(root/'near_path_clean_candidate.png')
Image.fromarray(mask).save(root/'edit-mask.png')
Image.fromarray(clean).crop((1190,730,1470,870)).resize((1120,560)).save(root/'after-detail.png')
changed=np.any(im!=clean,axis=2)
record={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256((root/'near_path_clean_candidate.png').read_bytes()).hexdigest(),'size':[im.shape[1],im.shape[0]],'changed_pixels':int(changed.sum()),'outside_mask_changed':int(np.count_nonzero(changed&(mask==0))),'method':'OpenCV normal seamless clone from adjacent grass; explicit polygons dilated 6px; unchanged outside mask','status':'unreviewed candidate; not runtime-ready','authorization':'User explicitly allowed local pixel cleanup in this conversation, originals retained'}
(root/'measurements.json').write_text(json.dumps(record,indent=2))
print(json.dumps(record))
