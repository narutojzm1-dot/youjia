# REQ-005 / REQ-012 · 叠加云带 B · 实现记录

- 构建：`game-32ff2d1`（晴天暖白修正）
- 来源提交：`32ff2d1e77b9741784fa92f83f12daff2678ed74`
- Actions：[37106337532](https://github.com/narutojzm1-dot/youjia/actions/runs/37106337532)
- 首发：`game-31316aa`
- 需求：REQ-20261002-005 云带 B；REQ-20261002-012 切片 A
- Agent-ID：`CURSOR-CONTRIBUTOR-LOCAL`
- 日期：2026-10-03

## 用户确认

- 批准叠加云带 B，暂缓雨雪 / 火烧云
- 水彩笔触；缓移；低动效静止帧
- REQ-012 顺序 A→B→C/D；C 先无道具；D 延后

## 实现

- 资源：`assets/holiday/environment/cloud_band_sunny.png`、`cloud_band_overcast.png`
  - 阴天：自阴天天空色采样的半透明水彩云带
  - 晴天（2026-10-03 修正）：暖白薄纱，不采样蓝天；预乘 alpha 模糊，避免脏灰芯
- 运行时：`YardWorld` 双 Sprite 首尾相接缓移（`CLOUD_DRIFT_SPEED`）；`ui.reduced_motion` 时保持静止
- 阴天云带跟院子滤色；晴天云带单独提亮 modulate；不改存档字段

## 用户反馈与修正

- 问题：晴天叠加云发灰、像脏斑；阴天尚可
- 修正：重烘焙 `cloud_band_sunny.png` + 晴天 modulate 提亮；阴天帧保留

## 自动化覆盖

- `test/ui_interaction_suite.gd`：晴/阴云带换帧；晴天云带偏亮；低动效静止；允许动效时滚动增加

## 发布

- 首发 Web：`game-31316aa`
- 晴天修正 Web：`game-32ff2d1`（PR #96，Actions [37106337532](https://github.com/narutojzm1-dot/youjia/actions/runs/37106337532)）
- 公网 PCK：13,739,724 字节，SHA-256 `f8c022f4da78d6a28b316ac8b2ba64a1106512d3bfcc03377aa4f7f9384cc4e8`
- 公网抬头观云：硬刷新后看页面底部 `game-32ff2d1`；晴天应为轻柔暖白薄云，不再是灰蓝脏斑；阴天疏密与缓移仍可读；低动效下静止
