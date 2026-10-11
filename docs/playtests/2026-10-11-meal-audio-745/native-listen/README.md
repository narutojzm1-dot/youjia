# Native Pulse listen capture — GROK #745 meal audio

Agent-ID: GROK-CONTRIBUTOR  
Date: 2026-10-11 ~20:30 Asia/Shanghai (CST)  
SHA under test: `023d8000bb6f598a6281a01f244306d5afb5aabe`  
Godot: `4.7.2.stable.official.ed1daf0bf` (Linux x86_64)  
Display: X11 `DISPLAY=:13` (llvmpipe), **not** `--headless`  
Audio path: Godot `--audio-driver PulseAudio` → sink `auto_null` → record `auto_null.monitor` via `ffmpeg -f pulse`

## What this proves (Native box)

Real device-path waveforms (not headless `play_cue` true counts):

| Phase | Clip | Observation |
| --- | --- | --- |
| cook loop | `01-cook_loop.ogg` | Continuous cook loop energy (~−26 dB RMS) |
| hunger + spoon | `02-hunger_spoon.ogg` | Short cue peaks over loop |
| pause | `03-pause_silence.ogg` | Near-silent after `set_paused(true)` |
| unpause | `04-unpause_cook.ogg` | Loop resumes |
| SFX+Master mute | `05-mute_silence.ogg` | Near-silent while player still marked playing |
| unmute | `06-unmute_cook.ogg` | Loop audible again |
| deny playback_allowed | `07-deny_allow_silence.ogg` | Near-silent; cook stops |
| re-allow | `08-reallow_cook.ogg` | Loop rebuilds without replaying missed shorts |
| full run | `native_meal_listen_full.ogg` | Entire ~21 s monitor capture |
| envelope | `volume_envelope_250ms.csv` | 250 ms RMS/peak audit |
| driver log | `godot_listen_log.txt` | Snapshot lines with playback position |

Full-capture volumedetect: mean ≈ −28.6 dB, max ≈ −12.7 dB.

## Steps (repro)

1. Start user PulseAudio with null sink (no `/dev/snd` required).
2. `ffmpeg -f pulse -i auto_null.monitor -t 22 -ac 1 -ar 22050 out.wav &`
3. Non-headless Godot drives `MealAudio`: unlock → `set_playback_allowed(true)` → cook → hunger/spoon → pause → unpause → bus mute → unmute → deny allow → reallow → stop → free leaf.
4. Split WAV → OGG clips above.

Ephemeral driver used on the box was **not** committed (evidence-only).

## Explicit non-claims

- **Web** listen / browser autoplay / Pages playtest: **not** captured this hour.
- Does **not** claim merge readiness or replace CODEX-LEAD / GAME-QA ear judgment.
- Does **not** claim production cook / missed-meal wiring (#738) is done.
- Box has no hardware ALSA card; sink is Pulse `module-null-sink` monitor (software device path, real Godot→Pulse PCM).

## Host notes

- Hostname: `grok-bot-vm-478310` (GROK box)
- PulseAudio 17.0, default sink/source `auto_null` / `auto_null.monitor`
- No Pages publish; no `main` push
