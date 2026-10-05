from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import cv2, json, hashlib, argparse
p=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description='Render diagnostic sky boundary; never modify source image.')
parser.add_argument('--source',type=Path,default=p.parents[2]/'assets/holiday/environment/yard_sunny.png')
src=parser.parse_args().source
a=np.array(Image.open(src).convert('RGB'))
ridge=[(1040,169),(1053,184),(1065,186),(1077,181),(1090,202),(1108,218),(1126,227),(1146,244),(1163,230),(1172,233),(1184,223),(1196,231),(1204,248),(1214,235),(1225,219),(1234,224),(1248,204),(1258,200),(1268,184),(1278,181),(1289,170),(1301,163),(1310,151),(1320,174),(1334,184),(1347,197),(1363,192),(1376,208),(1389,229),(1407,225),(1425,239),(1442,259),(1460,246),(1474,251),(1490,239),(1501,255),(1522,244),(1542,258),(1563,269),(1585,282)]
m=np.zeros(a.shape[:2],np.uint8)
cv2.fillPoly(m,[np.array([(1040,70),(1585,70)]+ridge[::-1],np.int32)],255)
# Five-pixel inset: diagnostic proposed sky mask, not approval to edit.
m=cv2.erode(m,np.ones((11,11),np.uint8))
f=np.zeros(m.shape,bool);f[220:385,990:1470]=True;f[250:]=True
conflict=(m>0)&f
overlay=a.copy(); overlay[m>0]=(a[m>0]*.6+np.array([30,200,220])*.4).astype(np.uint8)
overlay[conflict]=(a[conflict]*.4+np.array([255,30,100])*.6).astype(np.uint8)
im=Image.fromarray(overlay);d=ImageDraw.Draw(im);d.line(ridge,fill=(255,255,0),width=1)
im.crop((1000,120,1610,305)).resize((1220,370)).save(p/'sky-mask-overlay-2x.png')
Image.fromarray(m).save(p/'proposed-sky-mask.png')
Image.fromarray(conflict.astype(np.uint8)*255).save(p/'frozen-sky-conflict.png')
(p/'measurements.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'mask_pixels':int((m>0).sum()),'proposed_frozen_sky_pixels':int(conflict.sum()),'status':'diagnostic only; original image unchanged; traced ridge needs independent verification'},indent=2))
