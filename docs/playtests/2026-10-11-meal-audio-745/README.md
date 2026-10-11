# 2026-10-11 GROK #745 餐食音效叶子

## 范围

- 叶子：`scripts/presentation/meal_audio.gd`
- 资源：`assets/holiday/audio/meal_grok/`（原创程序合成，无第三方采样）
- 隔离演示：`scenes/presentation/meal_audio_demo.tscn`
- 套件：`test/meal_audio_suite.gd`
- AudioDirector 空路径 cue：`meal.spoon` / `meal.hunger`（运行时由叶子登记）
- **未**改 house_sleep / 饭点 / 选材 / SaveStore / Cloud UI / #720 UI 音

## 体验证据

- 无头套件：`run_verified_godot_suite test/meal_audio_suite.gd --headless --path .`
- 完成行：`[meal-audio] PASS: 31 checks`（Godot 4.7.2.stable.official.ed1daf0bf，隔离 XDG）
- 真实听验 / 桌面与 Web 出声录音：本轮以无头契约与资源存在性为主；听感不写通过，待 CODEX-LEAD / GAME-QA。
- 正式 `_set_cooking_audio` 接入等 PR #738 合入后由 Leader 保留作者补丁整合；饥饿触发标待接接口。

## 设计边界

- 不影响“没有待办的假期”。
- 不引入惩罚性等待；饥饿短声仅在 Leader 调用 `play_hunger()` 时出现。
