# 2026-10-11 GROK #745 餐食音效叶子

## 范围

- 叶子：`scripts/presentation/meal_audio.gd`
- 资源：`assets/holiday/audio/meal_grok/`（原创程序合成，无第三方采样）
- 隔离演示：`scenes/presentation/meal_audio_demo.tscn`
- 套件：`test/meal_audio_suite.gd`
- AudioDirector 空路径 cue：`meal.spoon` / `meal.hunger`（运行时由叶子登记）；`stop_cue` / `get_stop_cue_count` / `is_cue_voice_active` / `get_cue_stream`
- **未**改 house_sleep / 饭点 / 选材 / SaveStore / Cloud UI / #720 UI 音

## 体验证据

- 无头套件：`run_verified_godot_suite test/meal_audio_suite.gd --headless --path .`
- 真实听验 / 桌面与 Web 出声录音：听感不写通过，待 CODEX-LEAD / GAME-QA。
- 正式 `_set_cooking_audio` 接入等 PR #738 合入后由 Leader 保留作者补丁整合；饥饿触发标待接接口。

## 设计边界

- 不影响“没有待办的假期”。
- 不引入惩罚性等待；饥饿短声仅在 Leader 调用 `play_hunger()` 时出现。

## 2026-10-11 ~17:20 CST 督导 P2 返修

针对 ENGINEERING-SUPERVISOR 对 `56272e4e` 的 P2：

- 暂停拒绝新 hunger；停饭停 spoon；暂停停 spoon+hunger（`AudioDirector.stop_cue` 窄接口）
- 叶子不再 `unlock_audio`；演示仅在真实按键栈解锁
- `tools/verify_daily_life.sh` 增加 `test/meal_audio_suite.gd`
- 事件级 missed-meal 去重仍属 Leader（本叶子保留 0.35s 防抖）

隔离套件曾记：`[meal-audio] PASS: 35 checks`（Godot 4.7.2）。

## 2026-10-11 ~18:20 CST CODEX-LEAD 增量复核返修

针对 head `55adff10` 仍待修订两点：

1. **宿主播放许可** `set_playback_allowed`：与 `set_paused` 独立；默认拒绝；拒绝时停 loop+短音；恢复只重建仍有效 cook，不补播短音。
2. **`_exit_tree` 清理**：退出时 `stop_cue` spoon+hunger，并停本地 loop；套件种植 Autoload SFX 声部后断言 `is_cue_voice_active` 在退出后为 false，且 `get_stop_cue_count` 递增。

听验/主流程接线仍待 Leader/#738；本记录不写听感通过。

隔离套件复跑：`[meal-audio] PASS: 63 checks`（Godot 4.7.2，本轮许可/_exit_tree）。

## 2026-10-11 ~20:30 CST Native Pulse 听验证据（GROK）

- 路径：`docs/playtests/2026-10-11-meal-audio-745/native-listen/`
- 基于 SHA `023d8000`：非 headless Godot 4.7.2 → PulseAudio `auto_null` → `ffmpeg` 录 `auto_null.monitor`
- 已切 OGG：cook / hunger+spoon / pause 静音 / unpause / mute 静音 / unmute / deny allow 静音 / reallow
- **未**冒充 Web 听验；**未**写合入通过。详见该目录 README。

## 2026-10-11 ~21:28 CST Web 听验 blocker（GROK）

- 路径：`docs/playtests/2026-10-11-meal-audio-745/web-listen/`
- 本小时尝试 HTML5 导出听验：**未能捕获**。
- 原因：本机 Godot 4.7.2 export templates 目录为空；官方 tpz ≈1.28GB，本小时未下载。Chrome 154 + Pulse `auto_null` 可用，但无 WASM 构建可录。
- **未**伪造 Web 通过；**未**写合入通过。详见该目录 README。

## 2026-10-12 饥饿短音 13 返修（GROK-CONTRIBUTOR）

用户听感：第 11 条 cook loop、第 12 条 spoon 已通过并锁定；第 13 条肚子饿「听起来不像」。Leader 已在 Draft #738 停止派发 13。本叶子只重做饥饿短声，不改 Main / house_sleep / #738 宿主。

- 只替换 `assets/holiday/audio/meal_grok/hunger.tres`（cue `meal.hunger`，API `play_hunger()`）
- 叶子接口未改：`set_cooking` / `set_paused` / `set_playback_allowed` / `play_hunger`
- 新声音约 0.64 秒，软包络。低频蠕动加上两声向下的空腔气泡，避免旧版几乎只有 80 Hz 以下闷响
- 无尖锐点击；原创程序合成，不是 Minecraft / 塞尔达采样
- 第 11 条 `cook_loop.tres` sha256 `2e9824a0be6cd199d4383d9593a4e184fb41ca9c558b5f91f340d7ef52f5ce1b` 未改
- 第 12 条 `cook_spoon.tres` sha256 `b72eab1b9bf06842928aea36183a10f277b828cef21bfada150108b3ad700414` 未改
- 新 `hunger.tres` sha256 `e87ebdbbd310b5aefa02d821affc3a217e634468771356688f6b1ed4d27aad1c`（旧文件为 `3bc6aaa9a12104999da54139d5560067b639af09207b83fbf3636d755a20c27e`）
- 引入该资源的 git SHA、套件复跑结果：见本目录 `hunger-13/README.md`（资源提交之后回填精确 SHA）
- **不**声称耳听通过，**不**声称可以合入。请 CODEX-LEAD 只重听第 13 条
