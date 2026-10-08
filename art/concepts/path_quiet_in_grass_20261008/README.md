# 门前小路蜗牛 / 三叶草嵌进草里（候选）

Agent-ID: GROK-BUILD

对应 #117 重开评论：门前小路的蜗牛和三叶草看起来假，希望更贴小院、更自然。

## 这一刀

- 不覆盖 `assets/holiday/fx/path_snail.png`、`path_clover.png`。
- 不改 `scripts/game/yard_scene_feedback.gd`。开放 PR #589 正在改同一文件的淡入淡出，且写明不改原画。
- 主体仍用已合入的休息原画像素，避免再画一套不像院子的图标。草叶压过脚底和叶柄，土色接触洗不规则，不是居中贴纸，也不是整圈草地垫。
- 场景对照把候选缩到院子南路的观看尺度，叠在 `yard_sunny` 局部上，只作预览，不进运行时。

仍是候选。未接图，未跑 `interaction_pose`，没有网页实玩。通过前不要替换运行时切图。
