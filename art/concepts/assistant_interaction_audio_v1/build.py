from pathlib import Path
import json,hashlib,platform,subprocess,wave
import numpy as np,scipy
from scipy.signal import butter,sosfiltfilt
p=Path(__file__).resolve().parent;sr=48000;rng=np.random.default_rng(20261005)
report={'tools':{'python':platform.python_version(),'numpy':np.__version__,'scipy':scipy.__version__},'source':'Original deterministic synthesis; no recordings or external samples','listening':'not performed','files':{}}
for name,duration,lo,hi,strokes in [('pet_soft',.46,180,1500,2),('feed_rustle',.34,350,2100,1)]:
 n=round(duration*sr);t=np.arange(n)/sr;noise=rng.standard_normal(n)
 z=sosfiltfilt(butter(2,[lo,hi],btype='bandpass',fs=sr,output='sos'),noise)
 env=np.sin(np.pi*np.arange(n)/(n-1))**2
 if strokes==2:env*=.35+.65*np.sin(2*np.pi*t/duration)**2
 z*=env;z*=10**(-27/20)/np.sqrt(np.mean(z*z));z[0]=z[-1]=0
 pcm=np.round(np.clip(z,-.99,.99)*32767).astype('<i2')
 out=p/(name+'.wav')
 with wave.open(str(out),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes(pcm.tobytes())
 decoded=pcm.astype(float)/32768
 report['files'][out.name]={'duration_seconds':duration,'sample_rate':sr,'channels':1,'sample_format':'PCM16','bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'pcm_sha256':hashlib.sha256(pcm.tobytes()).hexdigest(),'peak_dbfs':float(20*np.log10(np.max(abs(decoded)))),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean(decoded**2)))),'clipped_samples':int(np.sum(abs(decoded)>=1)),'first_last_samples':[int(pcm[0]),int(pcm[-1])]}
(p/'measurements.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
