"""Original, isolated discovery cue sketch; no sampled or referenced melody."""
from pathlib import Path
import hashlib,json
import numpy as np
import soundfile as sf
p=Path(__file__).resolve().parent
sr=48000
duration=.95
t=np.arange(round(sr*duration))/sr
y=np.zeros_like(t)
# A soft two-tone rise with a short woody onset. Own synthesis, no game samples.
for start,freq,gain in [(0,523.251,.075),(.16,783.991,.058)]:
 u=t-start
 mask=u>=0
 v=u[mask]
 env=(1-np.exp(-v/.012))*np.exp(-v/.22)
 tone=np.sin(2*np.pi*freq*v)+.18*np.sin(2*np.pi*freq*2*v)*np.exp(-v/.12)
 y[mask]+=gain*env*tone
rng=np.random.default_rng(20261005)
noise=rng.normal(0,1,len(t))
noise=np.convolve(noise,np.ones(9)/9,mode='same')
y+=.009*noise*(1-np.exp(-t/.002))*np.exp(-t/.018)
tail=np.clip((duration-t)/.12,0,1)
y*=tail*tail*(3-2*tail)
y[0]=0;y[-1]=0
sf.write(p/'discovery_soft.wav',y,sr,subtype='PCM_16')
z,_=sf.read(p/'discovery_soft.wav')
info=dict(status='original_unheard_sketch_not_runtime_ready',sample_rate=sr,duration=len(z)/sr,
 channels=1,peak_dbfs=float(20*np.log10(np.max(abs(z)))),rms_dbfs=float(20*np.log10(np.sqrt(np.mean(z*z)))),
 clipped_samples=int(np.sum(abs(z)>=1)),sha256=hashlib.sha256((p/'discovery_soft.wav').read_bytes()).hexdigest())
(p/'measurements.json').write_text(json.dumps(info,indent=2)+'\n',encoding='utf-8')
print(json.dumps(info))
