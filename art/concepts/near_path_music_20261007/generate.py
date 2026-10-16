"""Original near-path theme; no samples or transcribed existing composition.

Run from any directory with numpy + soundfile. Produces the runtime Ogg,
an A/B listening excerpt, a seam excerpt and decoded-signal measurements.
Measurements establish technical properties, never listening approval.
"""
import hashlib
import json
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
RATE = 32000
BEAT = 60.0 / 75.0
BARS = 24
SECONDS = BARS * 4 * BEAT
COUNT = round(SECONDS * RATE)
music = np.zeros((COUNT, 2), dtype=np.float64)
events = []


def note(midi, beat, duration, gain, pan, voice="string"):
    t = np.arange(round((duration * BEAT + 2.2) * RATE)) / RATE
    hz = 440.0 * 2 ** ((midi - 69) / 12)
    if voice == "string":
        signal = sum(a * np.sin(2 * np.pi * hz * h * t) * np.exp(-t / decay)
                     for h, a, decay in [(1, 1, 1.4), (2, .32, .72), (3, .13, .4), (4, .05, .23)])
        attack = 1 - np.exp(-t / .009)
    else:
        signal = (np.sin(2 * np.pi * hz * t) * np.exp(-t / .72)
                  + .19 * np.sin(2 * np.pi * hz * 2.76 * t) * np.exp(-t / .18)
                  + .045 * np.sin(2 * np.pi * hz * 5.4 * t) * np.exp(-t / .065))
        attack = 1 - np.exp(-t / .006)
    release = np.minimum(1, np.maximum(0, (t[-1] - t) / .15))
    signal *= attack * release * gain
    index = (round(beat * BEAT * RATE) + np.arange(len(t))) % COUNT
    music[index, 0] += signal * np.sqrt((1 - pan) / 2)
    music[index, 1] += signal * np.sqrt((1 + pan) / 2)
    events.append(dict(midi=midi, beat=beat, duration=duration, gain=gain, pan=pan, voice=voice))


# Eight original harmonic measures, developed over three phrases. Sparse bass
# and plucked upper voices leave room for the existing environmental layer.
chords = [(43, 55, 59, 62), (42, 54, 57, 62), (40, 55, 59, 64), (36, 55, 59, 64),
          (45, 57, 60, 64), (38, 57, 62, 64), (43, 55, 59, 62), (43, 55, 59, 64)]
melodies = [
    [(0.5, 71), (1.5, 74), (3, 76)], [(1, 74), (2.5, 71)],
    [(0.5, 67), (2, 64), (3.5, 71)], [(1, 69), (2.5, 67)],
    [(0.5, 72), (2, 71)], [(1, 69), (2, 74), (3, 71)],
    [(0.5, 67), (2, 69), (3, 71)], [(1, 74), (2.5, 67)],
]
for bar in range(BARS):
    phrase, step = divmod(bar, 8)
    chord = chords[step]
    base = bar * 4
    note(chord[0], base, 2.5, .17, -.12)
    note(chord[1], base + .5, 1.7, .095, -.24)
    note(chord[2], base + 1.5, 1.4, .07, .2)
    note(chord[3], base + 2.5, 1.4, .085, -.08)
    # The middle phrase breathes: several melody notes are omitted instead of
    # repeating a busy metronomic loop. The last phrase answers an octave down.
    for i, (offset, pitch) in enumerate(melodies[step]):
        if phrase == 1 and (step + i) % 3 == 0:
            continue
        if phrase == 2 and step >= 4:
            pitch -= 12
        note(pitch, base + offset, 1.2, .105 if phrase != 1 else .085, .16, "wood")

# Short circular room tails are rendered across the boundary, not cut off.
dry = music.copy()
for seconds, gain in [(.071, .1), (.137, .065), (.229, .04), (.367, .025)]:
    music += gain * np.roll(dry[:, ::-1], round(seconds * RATE), axis=0)
music -= np.mean(music, axis=0)
music *= 10 ** (-20 / 20) / np.sqrt(np.mean(music ** 2))
if np.max(np.abs(music)) > .79:
    music *= .79 / np.max(np.abs(music))

target = ROOT / "assets/holiday/audio/bed_near_path_music.ogg"
print("Encoding original near-path theme", flush=True)
# Bound encoder work per call on Windows (large Vorbis writes can overflow
# the native encoder stack); the same samples and continuous stream are kept.
def write_ogg(path, samples):
    with sf.SoundFile(path, "w", samplerate=RATE, channels=2,
                      format="OGG", subtype="VORBIS") as output:
        for start in range(0, len(samples), 4096):
            output.write(samples[start:start + 4096])


write_ogg(target, music)
decoded, rate = sf.read(target, always_2d=True)
assert rate == RATE and decoded.shape == (COUNT, 2)
assert np.isfinite(decoded).all() and np.max(np.abs(decoded)) < .95


def db(value):
    return round(float(20 * np.log10(max(float(value), 1e-12))), 4)


window = round(.25 * RATE)
seam = np.concatenate([decoded[-window:], decoded[:window]])
measurements = {
    "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
    "bytes": target.stat().st_size, "seconds": len(decoded) / RATE,
    "sample_rate": RATE, "channels": 2, "bpm": 75, "bars": BARS,
    "peak_dbfs": db(np.max(np.abs(decoded))),
    "rms_dbfs": db(np.sqrt(np.mean(decoded ** 2))),
    "clipped_samples": int(np.count_nonzero(np.abs(decoded) >= 1)),
    "dc": np.mean(decoded, axis=0).tolist(),
    "seam_step": np.abs(decoded[0] - decoded[-1]).tolist(),
    "seam_local_max_step": np.max(np.abs(np.diff(seam, axis=0)), axis=0).tolist(),
    "seam_rms_before_dbfs": db(np.sqrt(np.mean(decoded[-window:] ** 2))),
    "seam_rms_after_dbfs": db(np.sqrt(np.mean(decoded[:window] ** 2))),
    "listening_approved": False,
}
(OUT / "levels.json").write_bytes((json.dumps(measurements, indent=2) + "\n").encode())
(OUT / "score.json").write_bytes((json.dumps(events, indent=2) + "\n").encode())
write_ogg(OUT / "seam-preview.ogg", np.concatenate([decoded[-8 * RATE:], decoded[:8 * RATE]]))
# Listening comparison keeps each decoded track at its own authored level.
# A half-second gap makes the boundary explicit; this is not a looping asset.
yard, yard_rate = sf.read(ROOT / "assets/holiday/audio/bed_yard_music.ogg", always_2d=True)
x = np.arange(12 * RATE) * yard_rate / RATE + 16 * yard_rate
yard_excerpt = np.column_stack([np.interp(x, np.arange(len(yard)), yard[:, c]) for c in range(2)])
preview = np.concatenate([yard_excerpt, np.zeros((RATE // 2, 2)), decoded[8 * RATE:20 * RATE]])
write_ogg(OUT / "yard-then-path-preview.ogg", preview)
print(json.dumps(measurements))
