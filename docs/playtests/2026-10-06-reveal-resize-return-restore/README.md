# #456 换视口后普通回院一次提交 → 真实关页恢复（公开 Pages）

- Agent-ID：CURSOR-CLOUD；关联 #456 / PR #467（合入 `dbf6f5aa902ecefeb168657e81a3bb12d97dbcbd`）。
- 被测构建：公开 `https://narutojzm1-dot.github.io/youjia/`，`game-release.json` 的 `sourceCommit` 为 `175bfce8f9ef02991022188172de4cf3fec007d0`，`entry` 为 `game-175bfce`，`publishedAt` 为 2026-10-06T00:40:33Z（见 `run-pub1/build.json`）。`175bfce` 包含 `dbf6f5a`。
- 环境：Playwright 驱动 Chromium headless，SwiftShader WebGL，用持久化用户目录承载 IndexedDB。这是浏览器视口模拟，不是实体手机。
- 输入：只用普通鼠标点击和键盘，脚本见 `driver_persist.py` 和 `cmd.sh`，每次输入的时间见各次的 `events.json`。没有注入种子、位置或时间。

## 过程与结果

存档读数是对 IndexedDB `youjia-save-host-v1` 里 `records/current` 的只读读取。

| 步骤 | 视口 | 存档读数 |
| --- | --- | --- |
| 进院 `01-save` | 1280×720 | generation 1，keepsakes 为空，exploration 为 null |
| 出门，按 E 看门口，走到树荫站按 E 看（`07-look-shade.jpg`） | 1280×720 | — |
| 按 T 带上松果，约 450ms 展示仍在时改为 390×844（`08a`、`08b`） | 1280→390 | `08-save`：generation 5，会话 active，`carried=[pine_cone]` |
| 竖屏点“回院”（`09-home.jpg`，提示“回到院里了。松果收好了。”） | 390×844 | `09-save`：generation 8，`keepsakes={pine_cone:1}`，session 为 null，`exploration_committed_serial` 为 1 |
| 关闭整个浏览器上下文，用同一用户目录重新打开（`run-pub2`） | 390×844 | `01-save`：generation 8，`keepsakes={pine_cone:1}`，session 为 null，committed serial 为 1 |
| 重开后点“走进院子”（`03-yard.jpg`） | 390×844 | `03-save`：同上，没有新的写入 |

**结论：**
- 换视口后普通回院只提交了一次：`exploration_committed_serial` 为 1，松果计数为 1。
- 真实关页再打开后恢复的是同一条记录，没有重复授予，也没有残留会话。
- 两次运行都没有 pageerror。

## 未覆盖

- 院里目前没有展示带回物的界面，手帐里也只有照片，所以重开后的所得只能用存档读数证明，不能用画面证明。
- generation 从 5 变到 8，是回院收尾流程的多次写入，属于 #305 已有协议，这里不展开。
- 不扩称已覆盖 #305 全矩阵，也不扩称已通过听验。
