"""Rebuild isolated #194 listening candidates; never edits runtime assets."""
from pathlib import Path
import argparse, hashlib, json, platform
import numpy as np
import scipy
from scipy.signal import butter, sosfiltfilt
import soundfile as sf

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
parser.add_argument('--previous', type=Path, required=True)
parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parent)
args = parser.parse_args()
expected = {
    'source': '239efcb8235acb56e12450c2e40e409336c1c139403a07ee8b4803f621bde241',
    'previous': '429b5f2d95f54b0a6902a7f5ce634eb78ea1bd3ffe3804196ef5a66cec5f2e05',
}
for name in expected:
    if hashlib.sha256(getattr(args, name).read_bytes()).hexdigest() != expected[name]:
        raise ValueError(f'{name} hash mismatch')
x, sr = sf.read(args.source, dtype='float64', always_2d=True)
previous, previous_sr = sf.read(args.previous, dtype='float64', always_2d=True)
assert sr == previous_sr == 48000 and x.shape == previous.shape == (6144000, 2)
out = args.output
out.mkdir(parents=True, exist_ok=True)
n = len(x)
duration = n / sr
# Circular extension keeps the existing filtering method comparable to PR300.
y = sosfiltfilt(butter(2, [100, 1500], btype='bandpass', fs=sr, output='sos'),
               np.tile(x, (3, 1)), axis=0)[n:2*n]
t = np.arange(n) / sr
events = [(9, 10.5, .68), (28.5, 16, .46), (58, 12, .80), (76.5, 8, .38), (108, 19, .61)]
envelope = np.full(n, .08)
for center, width, strength in events:
    distance = (t - center + duration/2) % duration - duration/2
    support = abs(distance) < width/2
    envelope[support] += strength * np.cos(np.pi * distance[support] / width)**4
y *= envelope[:, None]
target = -22.4914
y *= 10**(target/20) / np.sqrt(np.mean(y*y))
ceiling = 10**(-3.2/20)
if np.max(abs(y)) > ceiling:
    y *= ceiling / np.max(abs(y))

def measure(z):
    return dict(duration_seconds=len(z)/sr, rms_dbfs=float(20*np.log10(np.sqrt(np.mean(z*z)))),
                peak_dbfs=float(20*np.log10(np.max(abs(z)))), clipped_samples=int(np.sum(abs(z)>=1)),
                seam_delta=abs(z[0]-z[-1]).tolist(),
                pcm_float32_sha256=hashlib.sha256(z.astype('<f4').tobytes()).hexdigest())

files = {}
def write(name, z):
    path = out/name
    # libsndfile on Windows can exhaust the native stack on a whole-track write.
    with sf.SoundFile(path, 'w', samplerate=sr, channels=2, format='OGG', subtype='VORBIS') as stream:
        for offset in range(0, len(z), 16384):
            stream.write(z[offset:offset+16384])
    decoded, rate = sf.read(path, always_2d=True)
    assert rate == sr and decoded.shape == z.shape and np.isfinite(decoded).all()
    files[name] = dict(sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                       bytes=path.stat().st_size, **measure(decoded))
    return decoded

candidate = write('env_irregular_candidate.ogg', y)
write('seam_once.ogg', np.concatenate([candidate[-8*sr:], candidate[:8*sr]]))
# RMS matching reduces a level confound; it is not perceptual loudness matching.
comparison_target = min(-27.0, *(measure(z)['rms_dbfs'] for z in [x, previous, candidate]))
for name, z in [('compare_original.ogg', x), ('compare_previous.ogg', previous),
                ('compare_irregular.ogg', candidate)]:
    adjusted = z * 10**((comparison_target-measure(z)['rms_dbfs'])/20)
    write(name, adjusted)
info = dict(status='candidate_not_heard_not_runtime_ready', source_hashes=expected,
            sample_rate=sr, channels=2, events_center_width_strength=events, floor=.08,
            pre_encode=measure(y), comparison_target_rms_dbfs=comparison_target,
            versions=dict(python=platform.python_version(), numpy=np.__version__,
                          scipy=scipy.__version__, soundfile=sf.__version__,
                          libsndfile=sf.__libsndfile_version__), files=files)
(out/'measurements.json').write_text(json.dumps(info, indent=2)+'\n', encoding='utf-8')
print(json.dumps(info, indent=2))
