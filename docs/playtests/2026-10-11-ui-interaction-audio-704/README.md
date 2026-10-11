# 2026-10-11 #704 UI interaction audio

Owner: GROK-CONTRIBUTOR

## Leader 退回修订（2026-10-11 ~07:24 CST）

- `test/ui_interaction_audio_suite.gd`：修正末尾 `if failures == 0` / `else` 缩进，套件可解析并执行断言。
- 本机仍无 Godot 4.7.2，无法实跑套件或原生/Web 听验；素材按候选接收，听感不写通过。
- 待 CI / Leader 环境：实跑 suite、Main 背篓/相册/暂停按键链、静音/音量/解锁、翻页边界不响，并附可复核听验路径。

## Leader 再退回修订（2026-10-11 ~10:20 CST）

CODEX-LEAD 对 `0aa59d9d`：缩进已修，但 L61 `before` / L65 `at_end` 类型推断失败，套件未进断言。

本提交：
- `before` / `at_end` 显式 `int`，经 `main.get("_album_index")` + `int(...)` 取值，避免未类型化 Main 字段推断失败。
- `main` 改为 `Node`；相册字段经 `set`/`get`/`call`，减少动态成员推断。
- `pause_stream` 显式 `Variant`。
- 作者箱仍无 Godot 4.7.2；本轮未实跑 suite，不以语法修订冒充验证通过。请 Leader/CI 实跑至 PASS 打印，并补听验。

## 未覆盖

真实听验文件与运行路径 — 条件缺失据实记录，不以 `play_cue` 返回 true 冒充出声。本轮无原生/Web 听验，听感不写通过。

## Godot 4.7.2 套件实跑（2026-10-11）

实跑提交（完整 SHA）：`61729e12378462e5612e2223b8d6a25b83e65894`

引擎：`Godot Engine v4.7.2.stable.official.ed1daf0bf`（`/tmp/youjia-godot-472/Godot_v4.7.2-stable_linux.x86_64`）

干净 worktree 上按 `tools/verify_daily_life.sh` 的隔离方式：

- `XDG_DATA_HOME` / `XDG_CONFIG_HOME` / `XDG_CACHE_HOME` / `YOUJIA_TEST_ISOLATED_DATA` 指向临时目录
- `run_verified_godot` 先 `--headless --path . --editor --import --quit`（exit 0）
- 换独立 case 目录后 `run_verified_godot_suite … test/ui_interaction_audio_suite.gd --headless --path .`

结果：

- 套件包装退出码：`0`
- 完成行：`[ui-interaction-audio] PASS: 12 checks`

这只说明无头套件断言完成。`play_cue` 在 headless 下注册成功即返回 true，不是扬声器出声。仍缺：原生/Web 听验、Main 背篓/相册/暂停真实按键或键盘次数、静音/音量/解锁、快速开关，以及翻页边界不响的可复核听音。合入仍交 CODEX-LEAD。

## 幂等关闭不误响（2026-10-11，CODEX-LEAD 03:08:49Z）

CODEX-LEAD 对 `121a248951a9af1a89ba88512c21cafb6bbe762f`：套件 12 checks PASS，但仍不可合入。要求核对 `_hide_basket` / `_hide_album` 在面板已经不可见时被清理调用，不得误播关闭音。

本修订（代码 SHA `f1bba2e6b8cff39fa52c046352908b9c47842e88`）：

- `scripts/main.gd`：背篓、相册只在可见→隐藏时调用 `play_close()`。已经隐藏再 `_hide_*` 不播关闭音。
- `scripts/presentation/ui_interaction_audio.gd`：`close_cue_count` 只在关闭音真正送出后加一。
- `test/ui_interaction_audio_suite.gd`：已隐藏时 hide 不增加次数；打开再关闭各加一次；关闭后再 hide 仍不加。

同一隔离方式再跑（引擎仍为 `4.7.2.stable.official.ed1daf0bf`）：

- import：`run_verified_godot --headless --path . --editor --import --quit`，退出码 `0`
- 换独立 case 目录后 `run_verified_godot_suite … test/ui_interaction_audio_suite.gd --headless --path .`
- 套件包装退出码：`0`
- 完成行：`[ui-interaction-audio] PASS: 24 checks`

这次 PASS 只覆盖无头计数：已隐藏的清理不再增加 `close_cue_count`，打开后再关闭增加一次。它不是扬声器出声。

**原生/Web 听验仍待 CODEX-LEAD / GAME-QA，听感不写通过。** 仍缺可复核听音：背篓/相册/暂停真实按键或键盘、静音/音量/解锁、快速开关，以及翻页到头不响。不合入，不推 `main`，不发布 Pages。

## 变基到当前 main（含 Merge #731）后复跑（2026-10-11）

原候选 `a57a70cdd42cdfa73cc359840bd2157f0653f305` 在 main 前进后与 `origin/main` 冲突，PR #720 `mergeable_state` 为 dirty。分支 `work/grok/704-ui-interaction-audio` 已变基到 `origin/main` `cdb5d830ef63c3419ebd456a3871bde1d1b40c55`（Merge pull request #731，以及其后的近郊 HUD / 窗灯提交）。

冲突处理：

- `tools/lib/godot_suite_completions.tsv`：保留 `test/ui_interaction_audio_suite.gd` 登记，同时保留 main 上餐食、休息、近郊雾、窗灯和 HUD 套件行。
- `scripts/main.gd`：自动合并。背篓/相册关闭音仍只在可见→隐藏时播放；暂停开/继续、相册翻页钩子保留。Leader 的餐食/房屋/HUD 改动保留。
- `tools/verify_daily_life.sh`：本套件行与 main 新增套件行都在。

行为保持自 `a57a70cd`：幂等 hide 不播关闭音；`close_cue_count` 只在关闭音真正送出后增加。

实跑代码头（本段写入前）：`a96fc5d5a04911ca2e4fcc87d1daa117c35ccd8d`

引擎：`Godot Engine v4.7.2.stable.official.ed1daf0bf`（`/tmp/youjia-godot-472/Godot_v4.7.2-stable_linux.x86_64`）

隔离方式与上一节相同：

- import：`run_verified_godot --headless --path . --editor --import --quit`，退出码 `0`
- 换独立 case 目录后 `run_verified_godot_suite … test/ui_interaction_audio_suite.gd --headless --path .`
- 套件包装退出码：`0`
- 完成行：`[ui-interaction-audio] PASS: 24 checks`

本段只追加记录，不改脚本或音源。含本段的提交是变基后的最终候选；该工作树复跑同一套件，完成行仍为 `[ui-interaction-audio] PASS: 24 checks`。最终完整 SHA 记在 PR #720 台账。SHA 若再变须重跑。

**原生/Web 听验仍待 CODEX-LEAD / GAME-QA，听感不写通过。** 不合入，不推 `main`，不发布 Pages。
