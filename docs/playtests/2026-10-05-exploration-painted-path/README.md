# 首片近郊：原画沿路行走（EXP-PAINTED-PATH）

- Agent-ID：CURSOR-CLOUD · #153 / #155 · 依据[原画路径方向](../../architecture/exploration-painted-path-direction.md)
- 运行方式：真实 `main.tscn`，本机渲染器（非 headless），全程触屏事件驱动：开始假期 → 点小院石板路尽头 → 行动按钮「出门走走」→ 点画中溪声近处的路面 → 人物沿路走过去 → 停下看看 → 带上 → 接着走 → 点坡路草边的路面 → 停下看看 → 带上 → 回院。可走路线是制作人候选 `near_path_anchors.candidate.json` 的原样折线。
- 命令：`YOUJIA_CAPTURE_DIR=<dir> godot --path . --resolution 1280x720 --script tools/capture_exploration_slice.gd`（另跑 390x844）。种子随机，所以两次遇到的东西不同。
- 这是本机渲染截图，不是手机真机，也不是 Web 发布验收。

| 画面 | 1280×720 | 390×844 |
| --- | --- | --- |
| 出门：人物站在院门口石阶上，桌面完整构图 | [native-1280-03-scroll-start.webp](native-1280-03-scroll-start.webp) | [native-390-03-scroll-start.webp](native-390-03-scroll-start.webp) |
| 点按后沿路走（竖屏随人物平移，缩放不变） | [native-1280-04-walking.webp](native-1280-04-walking.webp) | [native-390-04-walking.webp](native-390-04-walking.webp) |
| 溪声近处停下看：人物在坡路上，东西就在脚边 | [native-1280-06-brook-look.webp](native-1280-06-brook-look.webp) | [native-390-06-brook-look.webp](native-390-06-brook-look.webp) |
| 坡路草边停下看：松果，篮子里已有圆石 | [native-1280-08-shade-look.webp](native-1280-08-shade-look.webp) | [native-390-08-shade-look.webp](native-390-08-shade-look.webp) |
| 回院：只有提交成功才说收好了 | [native-1280-10-yard-back.webp](native-1280-10-yard-back.webp) | [native-390-10-yard-back.webp](native-390-10-yard-back.webp) |

日志：[1280](native-1280-capture-log.txt) 与 [390](native-390-capture-log.txt) 都带回圆石和松果，提示「回到院里了。圆石、松果都收好了。」；两次都在点按后沿路到达 (923.0, 778.7)，也就是溪声近处的停留点。

## 看得出来的

- 原画按 1:1 铺底、等比缩放，没有拉伸或重复拼接。人物脚点落在画中道路上，远处（院门）小、近处（坡路下方）大。
- 桌面完整展示构图。竖屏手机用一档固定缩放随人物平移，人物、正在看的东西和右上「回院」始终可见。停下看不变焦。
- 木桥和溪水是画面左侧的地标，不是出口（03 页还没交付）；左上小路与木桥之间制作人未交付连接，所以不走。前景终点也不是出口。

## 仍未覆盖或待交付

- 画内已有的松果和落羽（右下前景）还在底图上，可拿的小物没放在它们上面，但它们看起来像能捡。清底/分层资源待制作人。
- 停留点、物件位置和人物比例是 Cloud 按这张候选画校准的实验参数（制作人坐标包里为 null/留空），待制作人按实际取景核对；人物资源 `SequenceResident`（`assets/holiday/characters/resident_walk_authored_v1`），脚点即精灵脚底中心，比例由脚点 y 在 0.75（院门台阶下 y=565）到 1.35（前景 y=845）之间线性插值。
- 没有前景遮挡层；天气不改变画面；正式小物精灵和相邻页换页待后续。
- 方向键沿路走、低动效、暂停、回院在 `test/exploration_slice_suite.gd` 中验证，本次截图只走了触屏。
