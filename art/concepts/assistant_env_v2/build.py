from pathlib import Path
import subprocess, numpy as np, hashlib, json
from scipy.signal import butter,sosfiltfilt
p=Path(__file__).resolve().parent
source=p.parents[2]/'art/concepts/audio_b_stems_v1/bed_yard_env.ogg'
raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(source),'-f','f32le','-acodec','pcm_f32le','-'])
x=np.frombuffer(raw,dtype='<f4').reshape(-1,2); sr=48000;n=len(x)
# Three copies allow filtering across the existing circular boundary.
band=butter(2,[100,1500],btype='bandpass',fs=sr,output='sos')
y=sosfiltfilt(band,np.tile(x,(3,1)),axis=0)[n:2*n]
t=np.arange(n)/n
# Periodic, sparse smooth gust envelope; no discrete calls or new event sounds.
e=.10+.90*((1+np.cos(2*np.pi*4*t))/2)**3
y*=e[:,None]
target=np.sqrt(np.mean(x.astype(float)**2));y*=target/np.sqrt(np.mean(y*y))
peak=np.max(abs(y)); ceiling=10**(-3/20)
if peak>ceiling:y*=ceiling/peak
subprocess.run(['ffmpeg','-v','error','-y','-f','f32le','-ar',str(sr),'-ac','2','-i','pipe:0','-c:a','libvorbis','-q:a','4',str(p/'env_gust_candidate.ogg')],input=y.astype('<f4').tobytes(),check=True)
z=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(p/'env_gust_candidate.ogg'),'-f','f32le','-']),dtype='<f4').reshape(-1,2)
seam=np.concatenate([z[-8*sr:],z[:8*sr]])
subprocess.run(['ffmpeg','-v','error','-y','-f','f32le','-ar',str(sr),'-ac','2','-i','pipe:0','-c:a','libvorbis','-q:a','4',str(p/'seam_once.ogg')],input=seam.tobytes(),check=True)
info={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'duration_seconds':len(z)/sr,'sample_rate':sr,'channels':2,'source_rms_dbfs':float(20*np.log10(target)),'candidate_rms_dbfs':float(20*np.log10(np.sqrt(np.mean(z.astype(float)**2)))),'peak_dbfs':float(20*np.log10(np.max(abs(z)))),'clipped_samples':int(np.sum(abs(z)>=1)),'seam_sample_delta':abs(z[0]-z[-1]).tolist(),'files':{f.name:{'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in p.glob('*.ogg')},'listening':'not performed; no speaker/listener claim'}
(p/'measurements.json').write_text(json.dumps(info,indent=2)+'\n');print(json.dumps(info))
