# #700 / #797 普通 Web 磨粉、重开恢复与面粉进餐

本档记录在正常游戏入口、正常 UI 下走过的候选链路：**麦粒 2→1、面粉 0→1；真正关闭页面后新开同源页面，麦粒 1 / 面粉 1 恢复；次日早餐后面粉 1→0，最后一把麦粒仍为 1。** 操作者为 CODEX-LEAD；没有向运行游戏注入库存、时间、游戏 API 或存档，也没有清理存储。

实际 Web 导出源为 `a97966998d759a2ccf8cbe722ee3ab00f173a2b8`，tree `e44b08fd99b8c101cafb0502bafe5f71de5b78f7`；与远端候选 `7d16a4e9fa1131629489a8bcf8725b1e6b16577f` 同树。当前本档的五张普通 Web 图都属于这个版本，不改写为之后的纸条修复版本。入口 `game-a979669`，PCK 89,004,548 bytes，SHA-256 `ae138bb8fbad7f856e0473a604fc344a6d00894b9b89daaa21d3e478625b2dcb`，详见 `build-identity.json`。这是本地候选证据，不是公开 Pages 发布证明。

## 选存的真实操作节点

| 原始文件编号 | 归档文件 | 能证明的实际状态 |
| --- | --- | --- |
| 07 | [01-day9-1921-autonomous-milling.png](01-day9-1921-autonomous-milling.png) | 第 9 天 19:21，角色在磨盘旁做实际劳动；原文件名误写为晚餐出门，此处按可见画面纠正。 |
| 09 | [02-day9-milling-result-wheat1-flour1.png](02-day9-milling-result-wheat1-flour1.png) | 正常打开背篓，麦粒 1、面粉 1，产物已经进入实际库存。此前起始数量 2 / 0 来自本轮操作记录，当前选图保留结果关键帧。 |
| 10 | [03-day9-flour-paper-excess-space-failure.png](03-day9-flour-paper-excess-space-failure.png) | 首次点面粉，只有短说明及两个按钮的纸条却约 473px 高。保留真实失败现场，不能把这张写成已修 UI。 |
| 11 | [04-day9-real-reopen-wheat1-flour1.png](04-day9-real-reopen-wheat1-flour1.png) | 正常关页、再新开同源页面进入院子后，背篓仍为麦粒 1、面粉 1。不是仅隐藏/显示面板。 |
| 13 | [05-day10-breakfast-flour0-last-wheat1.png](05-day10-breakfast-flour0-last-wheat1.png) | 第 10 天自然早餐结束后，背篓面粉为 0，麦粒仍为 1；没有把最后一把播种用麦粒一并磨掉或吃掉。 |

原始 `02-caught-fish-auto-dinner.png` 和 `12-flour-carried-for-breakfast.png` 实际画面是刷牙，**不是做饭或携粉证明**，未选入本档。原始 `03-after-dinner-autonomous.png` 属于早先失败阶段，也没有选作成功证据。这里的“原始 03”与归档文件 `03-day9-flour-paper-excess-space-failure.png` 不是同一张图；逐项来源、改名和原始哈希见 `sources.json`。

五张普通 Web 图均保留原始 1280×720 像素。此次流程中使用过的 390 宽模拟视口属于浏览器布局检查，不能称为硬件手机或真实触控验收；本档并不以这五张桌面图证明完整窄屏玩法链。

## 面粉纸条返修：与普通 Web 原版本分开记录

`ui-hug/` 保存真实 Web 发现问题之后的限定修复证据。它仅针对选中 `flour` 的纸条：在最终宽度已设置后，丢弃自动换行标签及父容器沿用的旧最小高度，再按当前内容收拢。没有重做其他 UI、改变库存行为或添加固定纸条高度。

- 旧实现的定向回归为 **17 / 1700 失败**，完整 `before.log` 保留。首次直接打开面粉时，中文高度 473px、英文高度 1348px；原测试先打开其他物品，掩盖了首开问题。
- 修复后 `after.log` 为 **1700 项通过**，覆盖五个尺寸、两种语言、首次打开、物品切换与保存状态文案切换。
- 四张 `after-{zh-CN,en}-{1280x720,390x844}.png` 是正常 BasketPanel 组件的受控原生 GPU 渲染，不是普通 Web 实拍。中文纸条为 204×148，英文为 204×173，底部空隙均 10px；当帧与稳定帧一致。图像未缩放、重编码或补画。
- 这份修复随后提交为 `321735f6a7f17cf368cb7740f2690ac9024f79e6`、tree `e4f6fa5e41a075ebac0c317be3e3af6b8e5125a2`。创建本档时，其普通 Web 重验与新完整 CI 尚待完成。旧 Web 截图仍按原实际版本保留。

原生 GPU 使用 Godot 4.7.2 stable / OpenGL Compatibility / RTX 4070 Laptop GPU，独立 APPDATA。`ui-hug/summary.json`、失败/通过/GPU 日志与四张 PNG 都按原字节归档。`summary.json` 中 `capture.gd` 的哈希指向真正执行的私有原版本；公开 `capture.gd` 只把固定私人输出路径换成 `YOUJIA_FLOUR_PAPER_CAPTURE_DIR` 参数并加空路径保护，渲染操作未改，公开版本没有再运行。原执行版本 SHA-256 `8019a20e991999d4e7a8ddd1cce47ce22ef50e0961b9350f2ddcf0f305d599a0` 与公开版本哈希分列在 `sources.json`，不能混同。

需要复现 GPU 组件证据时，使用相应源码与 Godot 4.7.2，给新建临时目录设置 `APPDATA`、`YOUJIA_TEST_ISOLATED_DATA`、`YOUJIA_FLOUR_PAPER_CAPTURE_DIR`，执行 `--path <repo> --script res://docs/playtests/2026-10-13-milling-web/ui-hug/capture.gd --rendering-method gl_compatibility --audio-driver Dummy`。这仍是受控组件测试，不替代普通游戏体验；不要使用玩家实际存档目录。

## 完整性与边界

`manifest.json` 列出本目录全部文件的 SHA-256 与字节数（清单本身不自包含）；`.gdignore` 避免归档夹具参与项目扫描。没有复制浏览器存储、APPDATA、私人邮件、用户名路径或凭据。

本档没有视频、硬件听验或实体手机证据，也没有新增肖像链普通 Web 验收；这次选存画面不证明完整三餐、所有生产任务或全部动物干扰组合均已验收。最终候选 CI、纸条新版本 Web 复验、合入及公开 manifest/PCK 核验由原 PR 与后续证据记录。
