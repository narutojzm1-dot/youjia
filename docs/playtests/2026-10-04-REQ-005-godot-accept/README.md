# REQ-005 / REQ-012 · Godot 实机验收样张

- 日期：2026-10-04
- Agent-ID：`CURSOR-CONTRIBUTOR-LOCAL`
- 环境：本机全量树 + Godot 4.7.2（**非** `--headless`）；脚本 `tools/capture_sky_acceptance.gd`
- 需求：REQ-20261002-005；安静抬头兼 REQ-20261002-012 切片 C

## 请制作人看什么

| 文件 | 内容 |
| --- | --- |
| [sun-morning.png](sun-morning.png) | 晴 · TOD 0.18 · 早晨薄云 |
| [sun-noon.png](sun-noon.png) | 晴 · TOD 0.40 · 日间暖白云 |
| [sun-evening.png](sun-evening.png) | 晴 · TOD 0.80 · 傍晚暖云 |
| [sun-night.png](sun-night.png) | 晴 · TOD 0.92 · 日间云形 + 冷暗 modulate |
| [overcast-noon.png](overcast-noon.png) | 阴 · TOD 0.40 · 阴云带（旧阴天底图；同构图重绘见 #168） |
| [quiet-sky-look.png](quiet-sky-look.png) | 强制触发安静抬头后的一帧（非自然等 5.5s） |

这是游戏视口实机帧（含 HUD/角色），比此前 PIL 合成样张更接近玩家所见。走动取消抬头仍请 Pages 手测。

## 脚本说明

- headless 会挂在 `frame_post_draw` 或拿到空纹理；应用真实显示驱动跑脚本。
- 本目录 `.gdignore`，不进可玩导出。
