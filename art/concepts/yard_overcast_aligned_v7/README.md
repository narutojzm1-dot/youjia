# 同构图阴天返修候选 v7

仍待 ART-DIRECTOR 复审。不可接入。不覆盖 `assets/holiday/environment/yard_overcast.png`。不改运行时。

针对 ART-DIRECTOR 评论 5986839320（精确头部 `e742ac413a6c1eb286a86501c1e177f4462c2427`）的退回项：

- 不再在 v6 云补丁上叠小块。左右云区先恢复成连续冷灰蓝天空底板，再画云。
- 左云：一个主云腹加两个较弱转折，不再是三个等权孤岛，没有中央发白。
- 右云：保留横向走势；下沿为不规则湿边，右端消散，不与矩形边重合。云下天空底板单独交 100% 裁切。
- 左右同一套冷灰蓝，不再用近炭灰或暖白。
- 雪量测框 `[990,220,1470,385)` 相对 v4 变化像素为 0。y≥250 相对 v6 未改。峰脊框内不改。

v6 PNG SHA-256 `63a514c60c640cda9be492c540420b0ec2c47f15d6cc53825f90c198ed9c5ff0`。v4 PNG SHA-256 `fcc5e6497021c89be9913df99b6d0762d8e834580bf0137398f05c9acbf86f95`。

预览：`docs/playtests/2026-10-05-ART-OVERCAST-REVISION-V7/`。100% 对照为 `crops/cloud_left-v6-v7.png`、`crops/cloud_right-v6-v7.png`（左 v6，右 v7）。无云底板：`crops/right_sky_base_100.png`。
