# QA-EXP-20261006-004 公开构建中文字体复核（拾物短展示标签）

- Agent-ID：CURSOR-CLOUD；关联 QA-EXP-20261006-004（GAME-QA 0815 报告的"拾圆石时短展示物品小标签呈方框状"）、#456 / PR #467（修复 `dbf6f5aa902ecefeb168657e81a3bb12d97dbcbd`，`FindReveal` 改用打包中文字体）。
- 被测构建：公开 `https://narutojzm1-dot.github.io/youjia/`，`game-release.json` 的 `sourceCommit` 为 `267b0cb3df5842170877bf55e438917ad4253ce8`，`entry` 为 `game-267b0cb`，`publishedAt` 为 2026-10-06T01:55:24Z（见 `build.json`）。`267b0cb` 比 QA 原报告用的 `game-49596fa` 新，包含已发布的 `175bfce`，即包含 #467 修复。
- 视口：**1646×894**，与 GAME-QA 原方框样本的截图尺寸一致，排除"只有特定尺寸才复现"的疑点。
- 环境：Playwright 驱动 `/usr/local/bin/google-chrome`（Chrome 148）headless，SwiftShader WebGL，持久化用户目录。是浏览器模拟，不是实体手机。驱动 `driver_qa.py` 由已合入的 `2026-10-06-reveal-resize-return-restore/driver_persist.py` 改出（仅把录制尺寸改成命令行参数），输入只用电普通鼠标点击与键盘，逐次时间见 `events.json`；没有注入种子、位置或时间。
- 原件：驱动截的是 png，入库前用 ffmpeg 缩到最宽 640 转 jpg；视频为三段拾物展示剪辑成 640 宽的 H.264 `reveals.mp4`。`errors.json` 本次 0 条 pageerror、0 条 console 错误。

## 过程与结果

存档读数是对 IndexedDB `youjia-save-host-v1` 里 `records/current` 的只读读取。

| 步骤 | 时刻/读数 | 结果 |
| --- | --- | --- |
| 进院、出院门到近郊（`02-path.jpg`） | — | 提示文字、按钮全部清晰，篮子空着 |
| 门口停下按 E（`03-gate.jpg`） | — | "这里有圆石"提示与"带上圆石"按钮清晰 |
| 按 T 带上圆石 | `events.json` t=273.941 | `04-save.json`：generation 4，`carried=[brook_stone]` |
| 展示动画放大帧（`zoom-yuanshi-label.jpg`） | 视频 274.0s 附近 | **"圆石"两字用打包中文字体清晰可读，无方框**，纸色小底板正常 |
| 继续走到第二处按 E（`06-walk.jpg`） | — | "这里有松果"提示清晰 |
| 按 T 带上松果 | t=609.319 | `07-save.json`：generation 6，`carried=[brook_stone, pine_cone]` |
| 展示动画放大帧（`zoom-songguo-label.jpg`） | 视频 609.6s 附近 | **"松果"两字清晰可读，无方框** |
| 继续走到第三处按 E（`09-walk.jpg`） | — | "这里有落羽"提示清晰 |
| 按 T 带上落羽 | t=1023.281 | `10-save.json`：generation 8，`carried=[brook_stone, pine_cone, feather]`，三个物品都只计一次 |
| 展示动画放大帧（`zoom-luoyu-label.jpg`） | 原录像约 1023.30s（T 后升起阶段） | **"落羽"两字用打包中文字体清晰可读，无方框**。物件比圆石/松果小，标签也更小；从 1646×894 原帧裁切放大到 640 宽，与另两件同规格核对字形，不是另一次公开会话 |
| 三段展示连续剪辑 | `reveals.mp4`（10.1s） | 圆石/松果/落羽的飞入与收篮动画正常 |

## 结论与未覆盖

**结论：** 在与 QA 原样本相同视口（1646×894）的当前公开构建 `game-267b0cb` 上，未复现 QA-EXP-20261006-004 的方框现象：圆石、松果与落羽的短展示标签均为打包中文字形、清晰可读，无方框；动画、存档计数与普通输入流程正常，全程无 pageerror。原方框样本来自修复发布之前的 `game-49596fa`，与 #467 修复自 `175bfce` 起已发布的记录一致。

落羽放大帧来自同一次 Playwright 原录像（1646×894 webm）在 `t≈1023.30` 的裁切，不是新的公开构建会话。路边白羽发现阶段对比、#375 正式视觉接入仍归 Leader，本帧只核展示名字缺字。

**未覆盖（如实声明）：**
- 这是 Owner 侧复核，不替代 GAME-QA 的独立复测（PR #479）；不扩称覆盖 #305 全矩阵、真机或听验。
- 落羽展示标签偏小、贴浅色栅栏对比一般，不等于方框缺字，也不宣称发现阶段路边可读性已通过。