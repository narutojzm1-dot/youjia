import os,subprocess,time,ctypes,json,re
os.environ['DISPLAY']=':93'
x=ctypes.CDLL('libX11.so.6'); t=ctypes.CDLL('libXtst.so.6')
x.XOpenDisplay.restype=ctypes.c_void_p
d=x.XOpenDisplay(None)
t.XTestFakeMotionEvent.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_ulong]
t.XTestFakeButtonEvent.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_int,ctypes.c_ulong];x.XFlush.argtypes=[ctypes.c_void_p]
open('/workspace/pr402-candidate/stage','w').close()
f=open('/workspace/pr402-candidate/native-final.log','w')
p=subprocess.Popen(['/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--path','/workspace/pr402-candidate','--script','test/native_review.gd'],stdout=f,stderr=f)
seen=set()
while p.poll() is None:
 stage=open('/workspace/pr402-candidate/stage').read()
 if stage and stage not in seen:
  seen.add(stage);time.sleep(.5)
  subprocess.run(['import','-window','root',f'/workspace/pr402-candidate/final-{stage}.png'],check=True)
  rows=[json.loads(line) for line in open('/workspace/pr402-candidate/native-final.log') if line.startswith('{')]
  row=rows[-1]
  pos=[float(v) for v in re.findall(r'-?\d+(?:\.\d+)?',row['dialog_position'])]
  size=[float(v) for v in re.findall(r'-?\d+(?:\.\d+)?',row['dialog_size'])]
  ok=[float(v) for v in re.findall(r'-?\d+(?:\.\d+)?',row['ok_rect'])]
  if stage=='portrait':
   # root(30,30)+dialog(12,234)+OK center(182,353)
   t.XTestFakeMotionEvent(d,-1,int(30+pos[0]+ok[0]+ok[2]/2),int(30+pos[1]+ok[1]+ok[3]/2),0);t.XTestFakeButtonEvent(d,1,1,0);t.XTestFakeButtonEvent(d,1,0,0);x.XFlush(d)
  if stage=='cancel':
   t.XTestFakeMotionEvent(d,-1,int(30+pos[0]+size[0]-14),int(30+pos[1]-18),0);t.XTestFakeButtonEvent(d,1,1,0);t.XTestFakeButtonEvent(d,1,0,0);x.XFlush(d)
 time.sleep(.1)
print('exit',p.returncode,'stages',sorted(seen))
