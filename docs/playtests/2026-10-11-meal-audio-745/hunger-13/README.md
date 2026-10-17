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

按下方「真实参考来源」表的文字特征程序合成（**未采样**）：
1. 轻腹垫（支持，不再当主声部）
2. 四声错落湿腔咕噜：带通噪声 × 向下滑的腔体共鸣；时间不规则
3. 软起软收，无尖锐瞬态；约 0.92 s；峰值约 −8 dBFS

粗谱能量（合成后自检，非听感结论）：约 49% &lt;80 Hz，约 22% 在 80–200，约 25% 在 200–500，约 4% 在 500–2000。相对 R2 的「两声干净下滑气泡」，本版更偏湿噪声腔体。详见表内比对结论。


## 真实参考来源（公开文献；参考 ≠ 允许采样）

本轮**只读公开医学/声学论文的文字描述**，用于约束合成目标特征。**未**下载、未嵌入、未重采样任何第三方肚子咕噜录音或商业音效库素材。参考不等于采样许可。

| 来源 | 取用结论（文字特征） | 对本合成的约束 |
| --- | --- | --- |
| Nowak et al., *Biomed Eng Online* 2019 — [Data driven filtering of bowel sounds…](https://biomedical-engineering-online.biomedcentral.com/articles/10.1186/s12938-019-0646-1) | 肠音为非平稳瞬态；常见「短 click / 成串 burst」与更长的簇状咕噜；功率主要在约 100–500 Hz，>1000 Hz 功率很小 | R3 主能量落在 100–500 Hz 湿腔突发，避免做成纯低频嗡鸣或高频刺音 |
| Zhao et al., *Sensors* / PMC9787765 — [High-Sensitivity Bowel Sound Electronic Monitor…](https://pmc.ncbi.nlm.nih.gov/articles/PMC9787765/) | 实测肠音频谱「mainly focused in the 100–500 Hz band」；时域可见 single-burst / multiple-burst / random continued | 采用多声错落、时间不规则，而非两声对称下滑「干净气泡」 |
| Ching et al., *World J Gastroenterol* / PMC3435785 — [Spectral analysis of bowel sounds…](https://pmc.ncbi.nlm.nih.gov/articles/PMC3435785/) | 电子听诊下主导频率常落在约数百 Hz 量级（文中梗阻亚组中位约 288–440 Hz）；时长可到亚秒级 | 单次 cue 控制在约 0.9 s、以中低频腔体共鸣为主，不做长循环「肚子叫不停」 |

### 与 R2 的比对结论（工程自检，非耳听通过）

- R2（`e87ebdbb…`）：偏「两声干净下滑气泡」+ 过重的极低频垫，听感不像湿腔蠕动。
- R3（`bc04bc71…`）：按上表把能量移向 100–500 Hz 带通噪声×下滑腔体，四声不规则间隔；粗谱自检约 49%&lt;80 Hz / 22% 在 80–200 / 25% 在 200–500 / 4% 在 500–2000。
- **未**对任何外部 wav 做波形对齐或频谱拷贝；合成器参数手调，仅对照文献文字特征。

## 听音材料

- **唯一权威**：`assets/holiday/audio/meal_grok/hunger.tres`（R3，sha256 见上表）
- 请 CODEX-LEAD 用 Godot 直接 `load`/`play` 该 tres；若需独立文件，**从该 tres 现场导出 WAV**，勿用旁路历史文件
- **已删除** `13-hunger-only.ogg`（引入于 `ff311a51`，属 R2 旁路试听，sha256 `dd0bac537d1f769b2de75e4535fd3517c56a491d4718a0f2579934b5e3a767e5`）。**不可用于 R3 听验**
- 仓库内**从未**存在 `13-hunger-r3.wav`；旧总 README 曾误列该文件名，已更正
- 本 executor **无 Godot / Pulse 实跑**；未写 Native 出声通过，未写耳听通过
- CODEX 说明：R3 暂不作为成熟送听包；本修订只闭环源树/文档，不重复发送 R2

## 套件

本小时未在本机复跑 Godot 套件（无 Godot 二进制）。叶子 API 与 11/12 字节未变；请 CODEX-LEAD / CI 实跑 `test/meal_audio_suite.gd`。预期仍为登记/播放契约级检查，不依赖 hunger PCM 波形哈希。

## 明确不声称

- 不写耳听通过。请 CODEX-LEAD **只重听第 13 条 R3**。
- 不写可合入；不推 `main`；不发布 Pages；不恢复 13 生产派发。
