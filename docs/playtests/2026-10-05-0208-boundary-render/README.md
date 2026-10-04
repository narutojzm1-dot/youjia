# REQ024集成基线与Web像素补证

CODEX-LEAD-ASSISTANT；候选PR159完整c92d92d44cd2742f6c7303d287ac3c67f8aff491，已由原GROK同步main c62。运行北京时间2026-10-05 02时，Godot4.7.2/Linux Chromium。独立代码审核引用PM精确c92 APPROVE5407334472，不复用旧a2审查。

## 原生

在任何测试入口改动前，独立候选worktree严格import、[边界44](boundary.log)、[主线保存恢复24](save.log)通过。随后[视口](viewports.log)失败：844×390继续按钮y=-21，是已登记#234主线音量裁切，不能将整体回归计通过。没有修改原Owner代码或分支，没有删除测试，未跑全daily。

## 受控实际Web渲染

临时本地入口[probe.gd](probe.gd)/[probe.tscn](probe.tscn)实例化生产Main和真实YardWorld。候选生产_draw/pose代码未改；入口替换project的main_scene，Main自动过程关闭以固定背景/相机，测试显式调用request_pointer_action与真实tick。桥接只供测试，未提交到游戏源码，不是自然玩家实玩。

按生产Web预设严格导入/导出后，Chromium取得同一不可达点屏幕坐标(868.4411,414.6644)，实际截图相同36×36区域，6张PNG原始像素不缩放。见[浏览器脚本](browser.cjs)、[状态/错误](browser.json)、[像素比较](pixels.json)。无pageerror/console error。

| 模式 | 早帧remaining1.2 / 晚帧0.2改变像素 | 早/晚相对到期背景RGB绝对差总和 |
| --- | --- | --- |
| 低动效 | 0 | 9996 / 9996 |
| 普通 | 189 | 9996 / 5703 |

[低动效早](reduced-early.png) · [晚](reduced-late.png) · [到期](reduced-expired.png)；[普通早](ordinary-early.png) · [晚](ordinary-late.png) · [到期](ordinary-expired.png)。背景与相机固定；早晚差与到期背景相减用于验证生产绘制保持/淡出，不将测试中手动推进1秒当自然运行1秒或绝对alpha测量。到期remaining0，无圈。此受控生产Web像素项已补齐。

## 剩余

原普通Web实操见253历史a2证据，不套为c92新实玩；完整游戏心流、真机、实听未验。当前公网仍game-fd2e9fe，不含本候选。234主线发布失败保持原GROK-BUILD Owner，未解除前不自动合入159或发布。保存/探索不接管Leader/Cloud范围，后续仅新布局head后适用集成回归。
