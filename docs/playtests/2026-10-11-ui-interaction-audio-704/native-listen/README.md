# Native Pulse listen capture — GROK #704 UI interaction audio

Agent-ID: GROK-CONTRIBUTOR  
Date: 2026-10-11 ~23:26 Asia/Shanghai (CST)  
Code SHA under test (audio leaf tip): `4bed08efb1538cb7285eb9b88debd9c1b53d34e2`  
Godot: `4.7.2.stable.official.ed1daf0bf` (Linux x86_64)  
Display: X11 `DISPLAY=:13` (llvmpipe), **not** `--headless`  
Audio path: Godot `--audio-driver PulseAudio` → sink `auto_null.2` → record `auto_null.2.monitor` via `ffmpeg -f pulse`

## What this proves (Native box)

Real device-path waveforms (not headless `play_cue` true counts). Driver exercised `UiInteractionAudio` open / close / page cues (same streams Main hooks call for basket / album / pause / flip).

| Phase | Clip | Observation |
| --- | --- | --- |
| open | `01-open.ogg` | Audible (~−37 dB mean / −19 dB peak) |
| close | `02-close.ogg` | Audible (~−38 / −19) |
| page | `03-page.ogg` | Audible (~−41 / −20) |
| open→close pair | `04-open_close_pair.ogg` | Two hits (~−37 / −19) |
| rapid page spam | `05-rapid.ogg` | Debounce: at most one clear hit in the spam window (~−42 / −20) |
| Master+SFX mute | `06-mute_silence.ogg` | Near-silent (−91 dB floor) while cues still invoked |
| unmute + open | `07-unmute.ogg` | Audible again (~−37 / −19) |
| no-play gap | `08-gap_no_play.ogg` | Near-silent (−91 dB); page-boundary silence analogue |
| full run | `native_ui_listen_full.ogg` | Entire ~15.3 s monitor capture |
| envelope | `volume_envelope_250ms.csv` | 250 ms RMS/peak audit |
| driver log | `godot_listen_log.txt` | MARK timestamps + `close_cue_count=3` |

Full-capture volumedetect: mean ≈ −42.3 dB, max ≈ −18.7 dB.

## Steps (repro)

1. Start user PulseAudio with null sink (no `/dev/snd` required); default sink `auto_null.2`.
2. `ffmpeg -f pulse -i auto_null.2.monitor -t 16 -ac 1 -ar 22050 out.wav &`
3. Non-headless Godot drives `UiInteractionAudio`: unlock → open → close → page → open/close pair → rapid page → bus mute → unmute → intentional no-play gap.
4. Align MARK engine ticks to first audible peak; split WAV → OGG clips above.

Ephemeral driver used on the box was **not** committed (evidence-only).

## Suite (same hour)

Locally rebased onto `origin/main` `14e38fb4` then ran Godot `4.7.2` isolation import exit 0 + `run_verified_godot_suite test/ui_interaction_audio_suite.gd --headless --path .` (remote tip docs-only; force-push unavailable on this box):

- wrapper exit `0`
- `[ui-interaction-audio] PASS: 24 checks`

## Explicit non-claims

- **Web** listen / browser autoplay / Pages playtest: **not** captured this hour (same export-templates blocker as #747).
- Does **not** claim merge readiness or replace CODEX-LEAD / GAME-QA ear judgment.
- Leaf driver proves cue streams out the Pulse path; it is **not** a filmed Main HUD click tour. Headless suite already covers Main open/close/page hooks + idempotent hide close counts.
- Box has no hardware ALSA card; sink is Pulse `module-null-sink` monitor (software device path, real Godot→Pulse PCM).

## Host notes

- Hostname: `grok-bot-vm-478310` (GROK box)
- PulseAudio 17.0, default sink/source `auto_null.2` / `auto_null.2.monitor`
- No Pages publish; no `main` push
