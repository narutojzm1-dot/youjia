# REQ-005 · 晴天夜里压暗云带

- 构建：合入并发布后回填
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
