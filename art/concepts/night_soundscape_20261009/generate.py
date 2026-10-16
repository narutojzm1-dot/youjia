"""Original synthesized candidate sounds. No samples, copied melody or recordings.

Requires numpy, scipy and soundfile; execute from any working directory.
Writes runtime Ogg and decoded technical evidence. Metrics are NOT a listening review.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
ASSETS = ROOT / 'assets/holiday/audio'
RATE = 24000
RNG = np.random.default_rng(20261009)
TAU = 2 * np.pi
events = []


def noise(seconds, low, high):
    count = round(seconds * RATE)
    freq = np.fft.rfftfreq(count, 1 / RATE)
    spectrum = RNG.normal(size=len(freq)) + 1j * RNG.normal(size=len(freq))
    weight = np.exp(-np.maximum(low - freq, 0) / max(low * .12, 1))
    weight *= np.exp(-np.maximum(freq - high, 0) / max(high * .12, 1))
    weight[0] = 0
    wave = np.fft.irfft(spectrum * weight, n=count)
    return wave / max(np.sqrt(np.mean(wave ** 2)), 1e-9)


def add(dst, start, wave, pan=0):
    # Circular placement includes a note's decay across the loop boundary.
    at = (round(start * RATE) + np.arange(len(wave))) % len(dst)
    for side, gain in enumerate([np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)]):
        np.add.at(dst[:, side], at, wave * gain)


def envelope(t, duration):
    return np.sin(np.pi * np.clip(t / duration, 0, 1)) ** 2


def bed(seconds):
    return np.zeros((round(seconds * RATE), 2))


night = bed(64)
# Very quiet continuous air, without the daytime birds.
for side in range(2):
    night[:, side] = noise(64, 300, 2000) * .002
for start in np.arange(1.2, 63, 2.1):
    start += RNG.uniform(-.35, .35)
    for chirp in range(int(RNG.integers(2, 5))):
        dur = .045 + RNG.uniform(0, .025)
        t = np.arange(round(dur * RATE)) / RATE
        hz = RNG.uniform(3700, 4600)
        wave = np.sin(TAU * hz * t) * envelope(t, dur) * .046
        add(night, start + chirp * .115, wave, float(RNG.uniform(-.8, .8)))
for start in [6.4, 8.0, 19.3, 21.7, 35.9, 48.2, 50.6, 59.1]:
    dur = RNG.uniform(.32, .65)
    t = np.arange(round(dur * RATE)) / RATE
    hz = RNG.uniform(230, 310)
    phase = TAU * (hz * t + 7 * np.sin(TAU * 8 * t) / (TAU * 8))
    wave = (np.sin(phase) + .3 * np.sin(phase * 2.03))
    wave *= (.55 + .45 * np.sin(TAU * 37 * t)) * envelope(t, dur) * .14
    add(night, start, wave, -.4)
    events.append({'cue': 'stylized-frog', 'second': start})
# One understated hiss in 64 s: environmental detail, no threat/reward event.
dur = .85
t = np.arange(round(dur * RATE)) / RATE
add(night, 43.6, noise(dur, 2300, 6500) * envelope(t, dur) * .009, .6)
events.append({'cue': 'occasional-hiss', 'second': 43.6})

rain = bed(32)
for side in range(2):
    rain[:, side] = noise(32, 650, 7500) * .027
for start in RNG.uniform(0, 32, 320):
    dur = .04
    t = np.arange(round(dur * RATE)) / RATE
    wave = np.sin(TAU * RNG.uniform(800, 1800) * t) * np.exp(-t * 110)
    wave *= np.minimum(t / .002, 1) * RNG.uniform(.006, .025)
    add(rain, float(start), wave, float(RNG.uniform(-.9, .9)))

snore = bed(4.8)
for start, duration, hz, gain in [(.2, 1.55, 104, .30), (2.7, 1.2, 88, .14)]:
    t = np.arange(round(duration * RATE)) / RATE
    phase = TAU * (hz * t + .8 * np.sin(TAU * 3.1 * t))
    throat = np.sin(phase) + .24 * np.sin(2 * phase) + .10 * np.sin(3 * phase)
    breath = noise(duration, 150, 1100)
    wave = (throat * .6 + breath * .14) * envelope(t, duration) * gain
    add(snore, start, wave)

music = bed(64)
# Sparse original 16-bar nocturne, 60 bpm; independent of the daytime themes.
melody = [76, 71, 69, 67, 74, 71, 67, 64, 72, 74, 76, 71, 69, 67, 64, 67]
basses = [48, 55, 45, 52, 53, 48, 50, 55]
for index, note in enumerate(melody):
    start = index * 4 + (1 if index % 3 == 1 else 0)
    for midi, when, amp in [(note, start, .10), (basses[index//2], index*4, .065)]:
        t = np.arange(8 * RATE) / RATE
        hz = 440 * 2 ** ((midi - 69) / 12)
        wave = sum(np.sin(TAU * hz * partial * t) * strength * np.exp(-t * decay)
                   for partial, strength, decay in [(1,1,.8),(2,.20,1.4),(3,.065,2.1)])
        wave *= (1 - np.exp(-t * 28)) * amp
        wave[-2400:] *= np.linspace(1, 0, 2400)
        add(music, when, wave, -.25 if midi < 60 else .25)
        add(music, when + .19, wave * .13, .35 if midi < 60 else -.35)
        events.append({'cue':'night-music','second':when,'midi':midi})

report = {}
ASSETS.mkdir(parents=True, exist_ok=True)
for name, pcm in [('night_air',night),('rain_air',rain),('sleep_breath',snore),('night_music',music)]:
    assert np.max(np.abs(pcm)) < .8
    path = ASSETS / (name + '.ogg')
    with sf.SoundFile(path, 'w', samplerate=RATE, channels=2, format='OGG', subtype='VORBIS') as output:
        for offset in range(0, len(pcm), 4096):
            output.write(pcm[offset:offset+4096])
    decoded, rate = sf.read(path, always_2d=True)
    report[name] = {'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'bytes':path.stat().st_size,'rate':rate,'channels':2,'seconds':len(decoded)/rate,
        'pcm_float_bytes':len(decoded)*2*4,'peak':float(np.max(np.abs(decoded))),
        'rms':float(np.sqrt(np.mean(decoded**2))),
        'loop_boundary_step':float(np.max(np.abs(decoded[-1]-decoded[0]))),
        'listening':'NOT REVIEWED'}
    # Last/first 2 seconds repeated: quick separate candidate seam listening.
    seam = np.concatenate([decoded[-2*RATE:],decoded[:2*RATE:]])
    with sf.SoundFile(OUT / (name+'-seam.ogg'), 'w', samplerate=RATE, channels=2, format='OGG', subtype='VORBIS') as output:
        for offset in range(0,len(seam)*2,4096):
            output.write(np.tile(seam,(2,1))[offset:offset+4096])
(OUT/'levels.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
(OUT/'events.json').write_text(json.dumps(events,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(report,indent=2))
