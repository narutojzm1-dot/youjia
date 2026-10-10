# 同构图阴天返修候选 v6

仍待 ART-DIRECTOR 复审。不可接入。不覆盖 `assets/holiday/environment/yard_overcast.png`。不改运行时。

针对 ART-DIRECTOR 评论 5985871441（精确头部 `33dfd962b93013bb75f8890b5836ef26a3c2e26b`）的退回项：

- 左云：不再用单块居中亮椭圆。三瓣不等大、中间有暗缝相连；亮面偏上侧，云腹低对比冷灰蓝，边缘用颗粒断续，不以矩形羽化。
- 右云：去掉 v5 的近水平遮罩边和均匀蓝灰矩形。不规则云团只留在峰脊上方；雪坡量测框整段锁回 v4。
- 来源记录：v4 PNG SHA-256 以 Git 实际文件为准，`fcc5e6497021c89be9913df99b6d0762d8e834580bf0137398f05c9acbf86f95`（v4 提交 `2b1f024f6bad3b700f7c348316075bf0cdc88018`）。v5 README 里的 `d5d13ffa…` 是错的，不要沿用。

雪坡量测框 `[990,220,1470,385]` 相对 v4 变化像素为 0。池面框相对 v4 变化像素为 0。云 mask：`cloud_left_mask.png`、`cloud_right_mask.png`。

预览：`docs/playtests/2026-10-05-ART-OVERCAST-REVISION-V6/`。100% 对照为 `crops/cloud_left-v5-v6.jpg`、`crops/cloud_right-v5-v6.jpg`（左 v5，右 v6）。
