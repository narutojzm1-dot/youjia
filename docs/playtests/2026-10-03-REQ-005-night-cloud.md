# REQ-005 · 晴天夜里压暗云带

- 构建：`game-922be64`；源提交 `922be6483bdebb1a7e7b27d3bd2112e091118106`（[PR #158](https://github.com/narutojzm1-dot/youjia/pull/158)）
- 需求：REQ-20261002-005
- Agent-ID：`CURSOR-CONTRIBUTOR-LOCAL`
- 日期：2026-10-03

## 为什么做

晨/午/晚云形已经分开。傍晚结束后若仍用正午暖白 modulate，夜空上的云会发亮，像白天薄纱贴在蓝黑滤色上。

## 范围

- 不新画：晴天 `tod >= 0.87` 仍用 `cloud_band_sunny.png`
- modulate 改为冷暗（约蓝灰），阴天夜里仍用阴云帧
- `_sync_cloud_band_art`：贴图未变也刷新 modulate（正午与夜里共用晴天帧）
- 不改 600 秒昼夜、不改存档、不做雨雪

## 测试

`test/ui_interaction_suite.gd`：晴天夜里贴图仍是晴云、modulate 偏冷且 r<1；阴天夜里仍是阴云；回到正午恢复偏亮。

## CODEX-LEAD-ASSISTANT 集成与发布补验

2026-10-03 22:11（Asia/Shanghai）记录，保留原 Owner。独立子代理 `CODEX-LEAD-ASSISTANT-REVIEW-PR-158` 对完整 head `ef84b605999611daaecc42e999e15d13d44228f8` APPROVE，三方合并保留最新探索计划与其他代理分工；[合入前证据](https://github.com/narutojzm1-dot/youjia/pull/158#issuecomment-5969921263)。

- 原生：Godot 4.7.2 headless 导入及完整 `tools/verify_daily_life.sh` 均 exit 0，无 SCRIPT ERROR/ERROR/FAIL；这不是原生图形实玩。
- Web 专项：独立临时工作树加载真实 main 场景、开始假期后受控设置时段。直接调用 `_sync_cloud_band_art`，同贴图正午→夜里→正午、阴天贴图与低动效云带静止共 5 项通过，pageerror 0。正午色值 `(1.0038,1.0024,1.001,1)`，夜里 `(0.8128,0.834,0.9376,1)`。这是本地实际渲染和断言，不是自然等待整日或正式上线证明。
- 正常入口：恢复原 project 后本地正常 Web 导出，1280×720 鼠标与 844×390 横屏触摸均进入院子，无 pageerror。
- 自动回归/导出/发布：[Actions 37128477830](https://github.com/narutojzm1-dot/youjia/actions/runs/37128477830) success；[Pages 37128703115](https://github.com/narutojzm1-dot/youjia/actions/runs/37128703115) success。
- 公网：[游戏入口](https://narutojzm1-dot.github.io/youjia/) 的 `game-release.json` 实际返回上述完整源提交，entry `game-922be64`，发布时间 `2026-10-03T14:10:14Z`；实际下载 `game-922be64.pck` 为 19,182,164 bytes，SHA-256 `44af8db71fe64e674ad6f60624de4ed09f50ad7f2105bfd9c5dcf6697c37866a`，与 gh-pages 同名包逐字节一致。公网正常浏览器实际请求该新包 HTTP 200，点击进入院子并键盘移动，pageerror 0。

夜间自然等待、全游戏连续心流及制作人视觉认可仍未完成；本轮为小修专项回归与正式发布核验。REQ-005 父需求继续进行，雨雪及其他剩余范围保留，制作人状态仍为「待看图」。
