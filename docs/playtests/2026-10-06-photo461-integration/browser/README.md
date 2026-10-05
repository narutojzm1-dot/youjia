# 461 快门题词暖纸背景：普通首照候选 Web 验收

Agent-ID：CODEX-LEAD 委派 `hotspot36_qa`。实际运行 2026-10-05 23:20:14–23:23:49 UTC（北京时间 2026-10-06 07:20:14–07:23:49）。两尺寸各从全新 profile、普通首页入院、轻抚近羊，自然形成第一次羊照片。不是内部 PhotoArrival.play / locale / TuningStore 注入，也不是正式发布验收。

## 结果与准确边界

390×844 和 568×320 的本次中文普通动画路径均观察到：题词“旅人随手拍下了这一刻。”有暖纸底、文字在纸上清楚可读，完整相片仍正常显示；自然结束后的图中纸条和卡片均已消失，没有留下空纸片。普通手帐可看到对应羊照片，普通“合上”返回院子。

**短横遮挡必须按此实际样本表述：** 新题词纸条位于旧目标提示纸片的右半部，确实重叠该背景区域。本次提示为“目标：窗台花箱 / 看看花箱·空格/按钮”，字位于更左侧，完整显示帧中没有被新纸条遮住。不能把预审提出的“可能遮长提示”写成本次已经发生，也不能由此声称所有目标提示都能同时完整可读；长提示尚未覆盖。相片本体对其他HUD的既有覆盖不属于本切片新增纸条的归因。

生产初始化固定中文，实际标题/暂停没有面向玩家的语言和减弱动态开关；本次英文/减弱动态 UI 端到端未覆盖，没有为测试新增入口或内调状态。集成者另行执行的原生受控语言/动效矩阵不得写成本次普通 Web 覆盖。

## 候选来源

候选地址 `http://127.0.0.1:8461/`，metadata `candidate-release.json`。

- sourceCommit/source：`fd887ff8691b41edba305ab946c43df082e793f7`
- sourceTree：`382fc30536973f2809641a36fdc3a67fd20b145c`
- entry / 实际 HTML data-build：`index`
- 实际 HTTP 下载 PCK：**27,090,652 bytes**
- PCK SHA256：`6f84caeb3dc92d6d12a91f39f6cc766dcc521a26bdb70b2f8c99063384eb73a3`

每个 context 开始/结束实际 HTTP 读取候选 manifest、HTML、PCK、10 个 web/save 模块及 license，合计4次；源、entry、长度/哈希均匹配冻结候选。两次真实导航HTML匹配当次来源，actual loaded JS/WASM/PCK/modules response 均200，记录在 `result.json`。license只下载核文件，不冒外链点击。PCK下载核验后释放，不重复归档大二进制。

## 原图与操作

| 范围 | 390×844 | 568×320 |
| --- | --- | --- |
| 首照前真实院子 | `portrait-01-yard-before.png` | `landscape-01-yard-before.png` |
| 完整题词纸条与真实照片 | `portrait-02-arrival-03.png` | `landscape-02-arrival-04.png` |
| 自然退场后 | `portrait-03-after-natural-dismiss.png` | `landscape-03-after-natural-dismiss.png` |
| 普通相册同一张羊照片 | `portrait-04-album.png` | `landscape-04-album.png` |
| 普通合上返回院子 | `portrait-05-album-closed.png` | `landscape-05-album-closed.png` |

所有 **37张完整原图** 保留，包括各标题和两轮12/15张连续抓拍。点击与burst在同一实际输入批次执行；没有为了截图暂停游戏时钟或强制停住动物。每张截图请求/完成时序见 `inputs.json`，这些不是精确渲染帧时间，不能声称测得精确1.58秒或0.24秒曲线。

竖屏从标题 `(195,430)` 入院，实际近羊 `(236,474)`；横屏标题 `(284,160)`，近羊 `(205,113)`。都是在本次完整画面上校准后普通点击。动画自然退场后，分别 `(100,744)` / `(140,220)` 打开手帐；`(307,667)` / `(454,284)` 普通合上。完整驱动为 `run.py`。

两份 `*-04-album-db.json` 是相册展示后只读 current：各自 generation=2、album/photo_moments 仅含本次 `sheep_pet_gentle`。两个fresh context具有各自存档，不声称整个current跨context相同，也不把只读数据替代相册可见证据。

`analysis.json` 提供题词纸区域在显现/退场前后的少量像素辅助。纸片带原有设计透明度，采样不是固定色块断言；例如竖屏完整帧 `(195,232)` 为 `(251,240,224)`，退场后恢复现场 `(194,144,94)`。完整照片 mat样本为 `(243,227,203)`，用于区分完整显示与退场，不把淡入/淡出帧误判为纸底失败。其余原始帧全部保留，不冒逐帧精确计时。

## 资源控制与结束

同一 Chromium headless Linux 浏览器、DPR1、no-preference，始终最多一个 page/context，参数含 renderer-process-limit=1。root在执行前明确同意将原onecontext方案改成两个fresh context串行，以取得两次真正首照且不改存档。第一context于23:21:33 UTC明确关闭，第二于23:22:11 UTC完成正常首页加载；最后23:23:49 UTC全部context/browser关闭，驱动实际 **exit 0**，并交回窗口。

没有 pageerror / console error / driver_error。启动前cgroup 15,970,095,104 B，观测高点16,989,220,864 B，关闭后15,608,426,496 B。没有并行浏览器或引擎，也未以重复刷新掩盖未命中。

未覆盖：正式发布、英语/减弱动态UI、实体手机/触摸/真人听验、#459、长目标提示、全部照片类型、精确动画时长/完整淡出曲线、完整存档恢复/浏览器进程重启、所有重叠控件的输入穿透。`predeclared-plan.md` 为执行前计划；`SHA256SUMS` 覆盖除自身外所有文件。
