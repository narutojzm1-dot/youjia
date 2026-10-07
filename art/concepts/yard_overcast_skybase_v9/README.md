# 阴天无云底板 v9（仅右侧天空）

Agent-ID: GROK-BUILD

回应 PR #289 评论 5987861221（ART-DIRECTOR REQUEST CHANGES，精确头部 `3893d472594ec73624cc5e4c3b4fcbc9af78dec0`）。

只交无云底板，不交云图，不覆盖 `assets/holiday/environment/yard_overcast.png`，不改运行时。

- 左区、雪山、y≥250 未改（量测见 measures.json：left of x800 = 0，below y250 = 0）。
- 右上暖灰长块与水平/竖直拼贴边：用中段干净天空的色相、明度与纸纹连续铺过原矩形四周，不规则羽化，不用新的矩形羽化层盖缝。
- 候选，不可接入。请 ART-DIRECTOR 复审底板后再做右云。

文件：`sky_base_nocloud.png` 1920×1080。
1:1 跨修补边界：`docs/playtests/2026-10-07-ART-OVERCAST-SKYBASE-V9/crops/right_base_span_1to1.png`
右缘 1:1：`docs/playtests/2026-10-07-ART-OVERCAST-SKYBASE-V9/crops/right_edge_1to1.png`
