# #456 换视口后普通回院一次提交 → 真实关页恢复（公开 Pages）

- Agent-ID：CURSOR-CLOUD；关联 #456 / PR #467（合入 `dbf6f5aa902ecefeb168657e81a3bb12d97dbcbd`）。
- 被测构建：公开 `https://narutojzm1-dot.github.io/youjia/`，`game-release.json` 的 `sourceCommit` 为 `175bfce8f9ef02991022188172de4cf3fec007d0`，`entry` 为 `game-175bfce`，`publishedAt` 为 2026-10-06T00:40:33Z（见 `run-pub1/build.json`）。`175bfce` 包含 `dbf6f5a`。
- 环境：Playwright 驱动 `/usr/local/bin/google-chrome`（Chrome 148）headless，SwiftShader WebGL，用持久化用户目录承载 IndexedDB。这是浏览器视口模拟，不是实体手机。
- 原件：驱动截的是 png，入库前用 ffmpeg 缩到最宽 640 并转成 jpg；webm 视频转成 640 宽的 H.264 `video.mp4`。存档 JSON 和 `events.json` 是原样复制的。`run-pub1/errors.json` 里有 2 条 SwiftShader 的 WebGL INVALID_OPERATION 警告，没有 pageerror。
- 输入：只用普通鼠标点击和键盘，脚本见 `driver_persist.py` 和 `cmd.sh`，每次输入的时间见各次的 `events.json`。没有注入种子、位置或时间。

## 过程与结果

存档读数是对 IndexedDB `youjia-save-host-v1` 里 `records/current` 的只读读取。

| 步骤 | 视口 | 存档读数 |
| --- | --- | --- |
| 进院 `01-save` | 1280×720 | generation 1，keepsakes 为空，exploration 为 null |
| 出门，按 E 看门口，走到树荫站按 E 看（`07-look-shade.jpg`） | 1280×720 | — |
| 按 T 带上松果，等 450ms 后截 `08a`，截完立即改为 390×844（`08b`） | 1280→390 | `08-save`：generation 5，会话 active，`carried=[pine_cone]` |
| 竖屏点“回院”（`09-home.jpg`，提示“回到院里了。松果收好了。”） | 390×844 | `09-save`：generation 8，`keepsakes={pine_cone:1}`，session 为 null，`exploration_committed_serial` 为 1 |
| 关闭整个浏览器上下文，用同一用户目录重新打开（`run-pub2`） | 390×844 | `01-save`：generation 8，`keepsakes={pine_cone:1}`，session 为 null，committed serial 为 1 |
| 先误点一次标题页空白处 `(195,560)`，再点“走进院子”（`03-yard.jpg`） | 390×844 | `02-save` 和 `03-save` 都同上，没有新的写入 |
| 翻开手帐（`04-notebook.jpg`），只有照片页，没有带回物 | 390×844 | — |

**resize 的确切时刻**（`run-pub1/events.json`）：按 T 在 t=107.081，`08a` 截图从 107.713 截到 109.005，用了约 1.3 秒；resize 在 109.005，也就是按 T 后约 1.9 秒（墙钟时间）。游戏里的展示总长是 0.35+0.9+0.4=1.65 秒，墙钟上能落在展示内，是因为截图时页面的帧被拖慢了，这一点只能靠视频证明。`run-pub1/video.mp4` 约 107.4～108.2 秒，每 0.2 秒一帧：松果在飞向篮子，下一帧画面已经是竖屏、松果已在篮里。所以 resize 落在**飞入阶段**，不在停留阶段。[PR #467](https://github.com/narutojzm1-dot/youjia/pull/467) 正文里本地构建那次“约 450ms 时改视口”也用的是同一个驱动和同一组输入，同样应理解为“截图后改视口”。

**结论：**
- 换视口后普通回院只提交了一次：`exploration_committed_serial` 为 1，松果计数为 1。
- 真实关页再打开后恢复的是同一条记录，没有重复授予，也没有残留会话。
- 两次运行都没有 pageerror。

## 未覆盖

- 院里目前没有展示带回物的界面，手帐里也只有照片，所以重开后的所得只能用存档读数证明，不能用画面证明。
- generation 从 5 变到 8，是回院收尾流程的多次写入，属于 #305 已有协议，这里不展开。
- 不扩称已覆盖 #305 全矩阵，也不扩称已通过听验。
