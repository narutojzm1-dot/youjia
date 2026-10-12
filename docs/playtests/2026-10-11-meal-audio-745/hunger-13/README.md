# 饥饿第 13 条返修 — 只听 hunger

Agent-ID: GROK-CONTRIBUTOR  
Date: 2026-10-12  
范围：只重做 `assets/holiday/audio/meal_grok/hunger.tres`（cue `meal.hunger` / `play_hunger`）。第 11、12 条锁定文件未改。

## 资源身份

| 文件 | sha256 | 本轮 |
| --- | --- | --- |
| `cook_loop.tres` | `2e9824a0be6cd199d4383d9593a4e184fb41ca9c558b5f91f340d7ef52f5ce1b` | 未改（第 11 条） |
| `cook_spoon.tres` | `b72eab1b9bf06842928aea36183a10f277b828cef21bfada150108b3ad700414` | 未改（第 12 条） |
| `hunger.tres` | `e87ebdbbd310b5aefa02d821affc3a217e634468771356688f6b1ed4d27aad1c` | 新（第 13 条） |

旧 hunger sha256：`3bc6aaa9a12104999da54139d5560067b639af09207b83fbf3636d755a20c27e`。

旧波形能量约 96% 在 80 Hz 以下，200–800 Hz 几乎为空，所以听起来像闷响，不像肚子饿。新波形约 0.64 秒：软起软收，低频蠕动垫底，两声空腔气泡向下滑（约 440→130 Hz，再约 300→90 Hz）。2 kHz 以上几乎没有能量，避免点击。峰值约 0.34（满幅以下），保持轻。

叶子 API 未改。未改 Main、house_sleep、#738 宿主、存档和餐食规则。

## Native Pulse（仅饥饿）

- Godot `4.7.2.stable.official.ed1daf0bf`，非 headless，`--audio-driver PulseAudio`
- 设备列表含 `Default` 与 `auto_null.2`；`ffmpeg -f pulse -i auto_null.2.monitor` 录音
- 临时脚本只 `load` 并播放 `hunger.tres`，不播 cook / spoon，不进 Main。脚本未入库
- 引擎报告 `length=0.64`，`play1 playing=true`
- 监听到的一次波形见 `13-hunger-only.ogg`（从原始 wav 裁到 0.70 秒）
- 整段原始 wav volumedetect：mean ≈ −31.2 dB，max ≈ −9.4 dB（与资源峰值 0.34 的约 −9.4 dBFS 一致）
- 日志还打印了 `play2`，但 0.64 秒之后监听是数字静音。本证据只覆盖这一次出声，不把第二次算成已录到

## 套件与提交

- 饥饿字节提交：`ff311a519849d09c0e28a9b9f5cd356a07f31262`
- 本说明在该提交之上。请按 PR #747 评论里的最终 head SHA 重听；该 head 的 `hunger.tres` sha256 仍是上一节的新值，第 11、12 条哈希不变
- Godot `4.7.2.stable.official.ed1daf0bf`，隔离 XDG，`run_verified_godot_suite test/meal_audio_suite.gd --headless --path .`
- 包装退出码 0
- `[meal-audio] PASS: 63 checks`

## 明确不声称

- 不写耳听通过。请 CODEX-LEAD 只重听第 13 条。
- 不写可合入，不推 `main`，不发布 Pages。
