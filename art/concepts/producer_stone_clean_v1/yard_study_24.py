from PIL import Image, ImageDraw
from pathlib import Path
import json
p=Path(__file__).parent
root=p.parent/'find-reveal-runtime-375'
bg=Image.open(root/'assets/holiday/environment/yard_sunny.png').convert('RGBA').resize((1280,720))
person=Image.open(root/'assets/holiday/characters/resident_walk_authored_v1/idle.png').convert('RGBA')
stone=Image.open(p/'stone_trimmed.png').convert('RGBA')
records=[]
for index,(x,y) in enumerate([(490,450),(480,500),(440,545)]):
 depth=.82+.36*((y-420)/230)
 width=24*depth
 scale=width/stone.width
 for state in ['clear','stone','person_front','person_back']:
  canvas=bg.copy()
  def draw_stone():
   s=stone.resize((round(stone.width*scale),round(stone.height*scale)),Image.Resampling.LANCZOS)
   canvas.alpha_composite(s,(round(x-717*scale),round(y-688*scale)))
  def draw_person(py):
   d=.82+.36*((py-420)/230); f=.25*d
   s=person.resize((round(person.width*f),round(person.height*f)),Image.Resampling.LANCZOS)
   canvas.alpha_composite(s,(round(x-192*f),round(py-420*f)))
  if state=='person_back':draw_person(y-8)
  if state!='clear':draw_stone()
  if state=='person_front':draw_person(y+8)
  ImageDraw.Draw(canvas).text((16,16),f'STATIC COMPOSITE - NOT RUNTIME / site {index+1} / {state} / stone width {width:.1f}px',fill='black')
  canvas.convert('RGB').save(p/f'yard24-{index+1}-{state}.png')
 records.append({'site':[x,y],'stone_width_px':width,'anchor':[717,688],'depth':depth})
(p/'yard24-study.json').write_text(json.dumps({'method':'Pillow static source composites; hypothetical depth order, not gameplay or photo evidence','records':records},indent=2))
