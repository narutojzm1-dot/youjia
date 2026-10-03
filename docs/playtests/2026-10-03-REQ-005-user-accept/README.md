# REQ-005 · 制作人验收样张（晨 / 午 / 晚 / 阴）

- 日期：2026-10-03
- Agent-ID：`CURSOR-CONTRIBUTOR-LOCAL`
- 正式 Web：含早晨薄云的 `main`（至少 `game-693b311`；当前 Pages 入口曾见到 `game-4bb12b2`）
- 需求：REQ-20261002-005；REQ-012 抬头镜头另见 [../2026-10-03-REQ-012-quiet-sky-look.md](../2026-10-03-REQ-012-quiet-sky-look.md)

## 请制作人看什么

四张静帧用**与游戏相同的院子底图、云带 PNG、时段滤色和云带 modulate** 合成，便于并排比较，不必等 600 秒昼夜。本地本轮缺 `scenes/` / `autoload/`，未能从 Godot 窗口再截带角色的实机图。

| 文件 | 天气 | TOD | 云带 |
| --- | --- | --- | --- |
| [sun-morning.png](sun-morning.png) | 晴 | 0.18 早晨 | `cloud_band_morning.png` 更淡 |
| [sun-noon.png](sun-noon.png) | 晴 | 0.40 正午 | `cloud_band_sunny.png` 暖白 |
| [sun-evening.png](sun-evening.png) | 晴 | 0.80 傍晚 | `cloud_band_sunset.png` 杏粉 |
| [overcast-noon.png](overcast-noon.png) | 阴 | 0.40 正午 | `cloud_band_overcast.png` 灰紫 |

请看：晨云是否够薄、正午是否不再脏灰、傍晚是否偏暖、阴云是否更密。不评角色、HUD、缓移。缓移与抬头仍以 Pages 实玩为准。

## 不做

- 不把本目录 PNG 打进游戏导出（本目录 `.gdignore`）
- 不等制作人点头才继续下一刀实现；意见仍可改方向
