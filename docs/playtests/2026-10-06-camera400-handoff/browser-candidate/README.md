# camera400 候选：普通静观与移动返回

执行者：CODEX-LEAD 委派 `hotspot36_qa`。仅普通浏览器兼容回归；不是 #400 原截图成因结案，也不是受控交叉状态链的 Web 端到端证明。

- 候选源码：`33bd42534d87ebd6e0cb0087d7ee0eaf258f548e`；tree：`d629f692a58a2abfb847078fb8e9bac472833b49`。
- 实际入口：`http://127.0.0.1:8462/`，`index`。候选本地 HTTP，不称已发布 Pages。
- 实际下载 PCK：27,090,748 字节，SHA256 `89e2e1e3b0b224a1ccd9e9e245addab2233eb3b351a01b1efb25f871f15556e3`。
- before（23:52:34Z）及 after（23:53:13Z）实取 manifest、HTML、PCK、10 个存档模块和许可证，均通过源码/长度/哈希校验。实际导航 HTML 与 before 字节哈希一致，data-build=index；实际 loaded JS/WASM/PCK/10模块 response 均 200。许可证单独 HTTP 校验，不声称实际打开许可 UI。
- 运行日期：2026-10-05 UTC；23:52:22Z 启动，23:53:14Z context 关闭，23:53:29Z browser 关闭；交互驱动实际退出码 0。

## 执行与结论

同一 Chromium browser 仅一 fresh context/page，390×844、DPR1、系统偏好 no-preference，实际 matchMedia reduce=false。正常中文标题点“走进院子”，静站两帧，真实 ArrowRight 按下 450ms 后松开，保输入后和回稳帧。全套为预定连续输入批次，截图真实耗时及 UTC/单调时钟见 result.json，不能把配置等待值当引擎精确时钟。首个点击执行本身约 3.79 秒，此耗时也保留。

| 原图 | 普通路径证据 |
| --- | --- |
| portrait-title.png | 实际标题与走进院子入口 |
| portrait-01-entered.png | 基线院子、站立角色 |
| portrait-02-stillness-a.png | 站立后建筑向画面下方移动，视野抬向天空 |
| portrait-03-stillness-b.png | 第二静观帧继续显示该位移 |
| portrait-04-after-movement.png | ArrowRight 实际输入后，角色移动，院屋高度接近基线 |
| portrait-05-settled.png | 院屋高度回到基线附近；常规横向跟随仍在 |

**有限普通路径 PASS**：可见静观后，普通移动有响应，院子画面回到非静观高度。不是从页面空白、冻结或内部设定 camera 得到的结果。未检测到 page error/crash，console 仅引擎信息与加载时序。

离线原图固定烟囱纹理匹配（landmark-analysis.json）给出的图像位移辅助值为：02 `(0,+112)`、03 `(0,+138)`、04 `(-27,+7)`、05 `(-28,0)` 像素。MAE 非零，系截图近似地标匹配，不是读取 Godot camera offset；横向变化不能误记为仍残留静观。图像未裁剪、未重绘、未替换。

**遗留自然构图缺陷（与返回路径分列）**：静观 02/03 中院子背景上边缘移至约 y=112 / y=138，HUD 下方出现浅纸色空带；移动后 04 上边缘约 y=7，05 顶部恢复背景。该顶部空带不通过自然构图验收。root 已独立亲看并决定在 #400 留新复现，由原 Owner Producer / Leader 协作后续处理；不临时扩大本 PR 的 World 交接修复范围，也不据此推断 #400 原截图同因。

## 覆盖边界

- 不读取/修改 camera、quiet_active、goose phase、随机种子、存档、日序或时间；不强制业务状态。驱动只用实际鼠标/按键，初始化只监听 first-frame 完成事件及只读系统偏好。
- 这次初次入院短窗口未覆盖 `_day_elapsed >= 45.0` 秒的自然鹅马预热，更没有普通同 tick quiet→goose 接管证据。原生受控 202 checks 是其他执行者的独立工程证据，本包不冒充其执行或 Web 等价覆盖。
- 依 root 最新资源限额，390 路径足够，未追加 1280×720、未刷新重试随机事件。原 #400 用户 2444×1502 画面及前置操作未复现，保持未结案。
- 未覆盖触屏真机、降低动态、英文、声音听验、存档全链、后台恢复或总体玩法质量。没有本包 DB 断言。
- 普通输入后确有可见回稳；未读取引擎内部信号来证明此刻退场具体分支，不能仅凭图像排除所有自然计时因素。

## 可复核原件与资源

`run.py` 为实际执行驱动，`result.json` 包含所有命令、截图请求/完成时刻、来源前后校验、实际资源 HTTP responses、console/errors 和关闭 UTC。`execution.json` 保存执行器退出与内存观察。`predeclared-plan.md` 是执行前原案，保留其“未执行”措辞作为历史计划，不代表本报告状态。`SHA256SUMS` 覆盖除此清单本身以外全部文件。

Chromium 使用 SwiftShader/renderer-process-limit=1，资源观察：启动前 15,785,652,224 B；可见峰值样本 17,043,763,200 B（非连续监测，不称严格峰值）；关闭后 15,681,351,680 B。没有新增第二 browser 或 Godot。
