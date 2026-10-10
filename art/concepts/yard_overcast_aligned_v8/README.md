# 同构图阴天返修候选 v8

仍待 ART-DIRECTOR 复审。不可接入。不覆盖 `assets/holiday/environment/yard_overcast.png`。不改运行时。

针对 ART-DIRECTOR 评论 5987342220（精确头部 `65ec28a2685a17087f17baff0db7a3365e9f3312`）的退回项：

- 天空底板不再用轴对齐矩形补丁。右上可疑区连同外侧边距，按中段干净天空的色相、纸纹和亮度重铺，无云检查图单独提交。
- 左云改成一条低对比、轮廓起伏的连续云带，不再是三个等大圆斑或三个暗核。
- 右云在底板之后以不规则软边叠上，不用云去遮矩形缝。
- 雪量测框 `[990,220,1470,385)` 相对 v4 变化像素为 0。y≥250 相对 v6 未改。

v7 PNG SHA-256 `dff973df7c73d62fb42b26f2953f81f386eb71fcb17bd9089fd52b7f590b8979`。

预览：`docs/playtests/2026-10-05-ART-OVERCAST-REVISION-V8/`。
1:1 证据：`crops/right_sky_base_100.png`（无云底板）、`crops/cloud_left_100.png`、`crops/cloud_right_100.png`。
对照：`crops/cloud_left-v7-v8.png`、`crops/cloud_right-v7-v8.png`（左 v7，右 v8）。
无云全图：`art/concepts/yard_overcast_aligned_v8/sky_base_nocloud.png`。
