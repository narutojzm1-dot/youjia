from pathlib import Path
from PIL import Image
tplroot=Path('/workspace/youjia-production-save/docs/playtests/2026-10-05-fishing-active-hud/retest');box=(1080,660,1250,692)
def mask(im):return [v<120 for v in im.convert('L').crop(box).getdata()]
tpl={k:mask(Image.open(tplroot/f'1280-720-{i}.png')) for i,k in enumerate(['wait','reel','toss'])}
def label(im):
 a=mask(im);s={k:sum(x and y for x,y in zip(a,b))/max(1,sum(x or y for x,y in zip(a,b))) for k,b in tpl.items()};k=max(s,key=s.get);return k if s[k]>.65 else 'other'
