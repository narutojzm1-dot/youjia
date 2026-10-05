# REQ-20261006-039 新照片快门行小纸片 原生渲染前后

- 记录人：`GROK-CONTRIBUTOR`，2026-10-06
- 基线：main `a0bb75e`；Godot 4.7.2，`xvfb-run` + `--rendering-driver opengl3` 原生渲染。新存档（隔离 XDG），`scenes/main.tscn` → `_start_holiday(false)` → 用 Main 自己的 `_photo_arrival`（在 UI 层里）播放「第一次钓到鱼」照片（第 12 天，低动效静帧），中/英各拍 1280×720、390×844、568×320、844×390。
- 只是原生截图，不代表真实浏览器、DPR 或手机。本通道只能经 GitHub 接口推文本文件，截图 PNG 未入仓；合入方按上面条件可原样复现。

## 观察

| 视口 | 改前 | 改后 |
| --- | --- | --- |
| 390×844 中/英 | 快门行落在屋顶深色木梁和窗台花上，3px 奶油描边糊成一圈，墨字对屋顶取样约 2.5:1，英文整句几乎读不出 | 字后一张贴合文字的暖纸小条，细杏边圆角，屋顶被盖住，字清楚；相纸位置不变 |
| 568×320 中/英 | 快门行横穿左上目标纸片：英文「The traveler caught this little moment.」与「Target: Window flowers」两行字叠在一起，两边都读不出 | 纸片盖住下面那截目标文字，快门行完整可读；目标纸片露出的部分不受影响，相纸消失后恢复原样 |
| 844×390 中/英 | 快门行压在目标提示第二行「看看花箱（空格/按钮）」末尾附近，字色混在一起 | 同上，纸片只覆盖文字宽度，不挡整条顶部 |
| 1280×720 中/英 | 雪山上，勉强能读 | 纸片同样贴合，样式与通知/标题纸片一致，不显突兀 |

普通模式下纸片跟着快门行一起淡出（它是这行字的子节点），由 `test/photo_arrival_shutter_paper_suite.gd` 的淡出检查覆盖，未逐帧截图。

## 回归

完整 `GODOT=Godot_v4.7.2 bash tools/verify_daily_life.sh`（隔离 XDG，未登记新 suite）exit 0，尾部 `LEGACY_BRIDGE_PASS 22`、`Loading shell PASS`、`MOTION PREFERENCE JS PASS 21`。
