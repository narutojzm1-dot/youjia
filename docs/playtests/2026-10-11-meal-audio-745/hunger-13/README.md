# 饥饿第 13 条 R3 — 参考真实肚子咕噜后再合成

Agent-ID: GROK-CONTRIBUTOR  
Date: 2026-10-12 ~21:55 CST  
范围：只重做 `assets/holiday/audio/meal_grok/hunger.tres`（cue `meal.hunger` / `play_hunger`）。第 11、12 条锁定文件未改。未改 Main / house_sleep / #738 宿主。

## 回执

已读 CODEX-LEAD 2026-10-12T13:21:12Z：用户再听 R2（`e2b30e85` / hunger `e87ebdbb…`）仍认为肚子咕噜不对，要求先参考真实肚子咕噜再返修；R2 未批准，继续禁播。ENGINEERING-SUPERVISOR 已说明缺件 tone fallback 由 Leader 沿 #738 副本安静降级，本叶子本轮**不**重写 Main/Host、**不**开启 13 派发。

## 资源身份

| 文件 | sha256 | 本轮 |
| --- | --- | --- |
| `cook_loop.tres` | `2e9824a0be6cd199d4383d9593a4e184fb41ca9c558b5f91f340d7ef52f5ce1b` | 未改（第 11 条） |
| `cook_spoon.tres` | `b72eab1b9bf06842928aea36183a10f277b828cef21bfada150108b3ad700414` | 未改（第 12 条） |
| `hunger.tres` | `bc04bc71cd6152e77a5affda9fa063edc39c65fa7abad8217d9df86f743e1d89` | **R3 新**（第 13 条） |

R2 hunger sha256：`e87ebdbbd310b5aefa02d821affc3a217e634468771356688f6b1ed4d27aad1c`（已废，勿再送听）。

### 合成说明（原创，无外部采样）

参考真实 borborygmi 的可描述声学特征后程序合成：
1. 轻腹垫（支持，不再当主声部）
2. 四声错落湿腔咕噜：带通噪声 × 向下滑的腔体共鸣；时间不规则
3. 软起软收，无尖锐瞬态；约 0.92 s；峰值约 −8 dBFS

粗谱能量（合成后自检，非听感结论）：约 49% &lt;80 Hz，约 22% 在 80–200，约 25% 在 200–500，约 4% 在 500–2000。相对 R2 的「两声干净下滑气泡」，本版更偏湿噪声腔体。

## 听音材料

- `13-hunger-r3.wav`：与 tres 同源 PCM（22.05 kHz / mono / 16-bit）
- `13-hunger-only.ogg`：同内容 Vorbis，便于快速试听
- 本 executor **无 Godot / Pulse 实跑**；未写 Native 出声通过，未写耳听通过

## 套件

本小时未在本机复跑 Godot 套件（无 Godot 二进制）。叶子 API 与 11/12 字节未变；请 CODEX-LEAD / CI 实跑 `test/meal_audio_suite.gd`。预期仍为登记/播放契约级检查，不依赖 hunger PCM 波形哈希。

## 明确不声称

- 不写耳听通过。请 CODEX-LEAD **只重听第 13 条 R3**。
- 不写可合入；不推 `main`；不发布 Pages；不恢复 13 生产派发。
