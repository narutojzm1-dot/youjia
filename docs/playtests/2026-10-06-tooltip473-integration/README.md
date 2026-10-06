# PR473 暖纸工具提示：集成证据

Agent-ID: CODEX-LEAD（内部工程助手 `gate130_completion`）；原实现 GROK-CONTRIBUTOR。原单接收：[6007126801](https://github.com/narutojzm1-dot/youjia/pull/473#issuecomment-6007126801)。

## 当前状态：组合原生、严格导出与普通候选体验通过，最终远端门禁待完成

从已合入 main `8ae57959ff95117047c4362704c298b583d651a7` 建隔离分支 `work/codex-lead/tooltip473-paper-integration`，真实双亲保留 GROK 原提交 `4ab54d7ab0dbbb902baebd123eaa4b18459a52d6`。原作者的 `paper_tooltip_style_suite.gd`、UID 和 capture 脚本保持原字节。原专项 104、断开接线 30/104、原生图片及旧 full daily 为作者报告，原 PR 未含对应原始日志/PNG；本批不把这些旧数字称为独立复验。

只接入原作者共享 TooltipPanel / TooltipLabel 主题；`PAPER alpha=0.97` 保持，说明修为近不透明（仍有 3% 底层贡献）。未改 Main、project、相机、滑条、输入模态、存档或探索。原始 style 套件和新增 interaction 套件分别进入 daily 与准确完成表。

## 已执行的轻量门禁

[原始日志](offline-gate.log)、[直接退出及哈希](offline-gate-result.json)：实际 Bash fake-process 包装器测试退出 0，总计 92，其中本片两种完成格式各 14、合计 28；旧 64 保持。这些是包装器正反例，不是 Godot 或浏览器体验。零计数、错误套件、缺行、前后缀、拼接行、非零退出、末尾 ERROR/FAIL、日志读失败均拒绝；既有契约接受两条独立合法完成行，不声明完成行唯一性。

## 新增真实引擎夹具的实际范围

`test/paper_tooltip_interaction_suite.gd` 独立保留原 104 测试的边界。使用隔离 XDG 检查、真实 Main 与手帐按钮、实际引擎 tooltip timer；通过 Viewport 分发鼠标移动/按下/释放，不伪造 Popup、不发 pressed 信号、不直接调用打开/关闭手帐。五尺寸 1280×720、390×844、568×320、844×390、640×300 × 中/英：完整文案与全部非空白码位字体、文字最小框/标签框、悬停消失/再次出现、真实点击开合且只触发一次。

[几何源码审计](geometry-source-audit.json)记录 Godot 4.7 参考版本的 API 和源码；不是已安装 4.7.2 二进制逐字节证明。

新夹具显式设置 `root.gui_embed_subwindows=true`，验证 Web 类嵌入路径，日志实际记录 root position/size/transform、popup embedded、popup/bounds/label/chip 矩形。嵌入 Popup 的位置属于父 Viewport；实际内部 Panel body/Label 的局部框经过 popup final_transform 和 position 转到 root，再与 root visible_rect 比较。原生 OS Window 的 position 是绝对屏幕坐标，引擎约束是屏幕 usable_rect，不可拿 (120,684)+172×42 与 1280×720 直接断言裁切或完整包含。PopupPanel 会在约束纸面位置后为 shadow 扩大 Window；v3 以真实纸面和全文作为包含对象，完整 Window 另列。1280×720 与 844×390 的中英四例，外扩阴影窗口超底 6px，纸面底边恰为视口底、字框底保留 5px；不声称阴影完全可见，实际 Web 图片另验。


## 原生真实运行与保留的失败

原始退出记录及源码绑定：[汇总](native-summary.json)。五个实际 Godot 进程（import、原 style、新交互 v1/v2/v3），每次独立 XDG，直接 Godot exit 和严格 wrapper exit 均单列。原生范围是程序分发鼠标事件的集成夹具，不等于人在 Web 操作。

| 版本 / 本地受测源 | 实际结果 | 解释 |
| --- | --- | --- |
| [v1 原件](native-v1/execution.json) / `309b87c59f98455def267245c7a31601765b31ff` | import 0；原样式 104/0；新交互 29/46 失败，直接及严格退出 1 | 首次夹具把含 shadow 的整个 Window 当纸面；开手帐后仅 4 帧即点关闭，落在既有 400ms 去重窗内，后续例串污。保原红，不能改成 PASS 或游戏已证裁切。 |
| [v2 原件](native-v2/execution.json) / `5c1efc77404607b9b4343b2df296b08e7e67c1fa` | 新交互实际 210/0 | 每例独立 Main、实际纸面/字框、0.45 秒再关闭通过；但逐 trace 检出英文标签实际仍为中文：`Main._ready` 明确固定 `zh-CN`，覆盖启动前设置的夹具语言。本版不能当双语覆盖。 |
| [v3 原件](native-v3/execution.json) / `a3cae472d7774445ae8add3ea23528e0af7c9399` | 新交互实际 230/0，严格退出 0 | 启动后设语言，增加实际 locale/翻译断言；10 trace 中 5 中/5 英，英文实际为 `Open the polaroid journal`，正文宽 182。真实 hover、leave、rehover 和鼠标开合手帐通过。 |

这三版生产 Theme hook/helper 完全相同；仅夹具改正。原 style suite 的原作者 blob `db7b25d4f467f420d3e7d27c16d69b487472ea5b` 保持，v1 104 是本轮独立执行，原报告的断开接线 30/104 仍只是作者自述。每版保存受测 fixture 文本和 blob，不把本地 Git SHA 伪链接为远端已存在。

手帐关闭输入等待真实 0.45 秒避开既有 400ms 去重窗，**不覆盖快速连续点击**，不改 Assistant #382。这批专项原件已冻结；当时引擎于 `2026-10-06T01:20:24.227648Z` 关闭，当时未运行浏览器，后续组合与普通体验分列如下。相关未跟踪 UID 见[生成元数据清单](generated-metadata-inventory.json)，仅本新增套件的 UID 纳入，其他不盲目提交。

## 精确共享组合与全量验证

原受测源 `a0a856f64e7764fbab5270412025e62b8e34cafd` / tree `0945747d4680e899bbfe5253a60ca5c0f8cf92e1` 以本片 `355aa2b7137a49779ea9239c17450fc15e5df5a0` 与相机候选 `4598df52591db795f1441f4dd22a53df1df4a61c` 为真实双亲；后者已保留实际 main `d21030dfc243926b7e6a1849151ada1eadab75ef`（滑条476和Cloud475）。这是运行时的候选依赖组合，不追认相机当时已经合入或发布。全部依赖非本片路径逐个 blob/mode 保持，五处共享记录按双方增量合并，[组合证据](combined-native-web/combination.json)。本片不修改 Main、project、相机、滑条、存档或探索的生产行为。

[每进程真实直接退出](combined-native-web/engine-processes.jsonl)、[外层严格命令退出](combined-native-web/process-results.json)、[完整 daily 原件](combined-native-web/daily.log)、[结果](combined-native-web/result.json)：实际 80 套 + import 共 81 次 Godot 启动，每次直接退出 0；两条工具提示分别 104 与 230，Bash fake 共 124（本片格式28、滑条28，原camera等68），两个 Node 程序通过。Python retention 实际 11 个测试、真实临时Git publisher fixture 和严格 Web 导出均外层退出 0；另一次导出 Godot 直接退出 0；publisher fixture 还实际查询两次 `Godot --version`，全 recorder 共84个进程（81 daily +2 version +1 export）。这不是84个游戏套件，version行沿用外层 `phase=daily` 字段但实际args已逐条分开。日志原文的进程结果和计数优先于旧候选的92/78等数字。

引擎关闭时间 `2026-10-06T01:39:42.756923+00:00`；候选 PCK `27097128` bytes / SHA-256 `91028b52ee7c2d4441ce2e368b600a3fb2a70dfeaf8a309229611709bccd1207`，manifest SHA-256 `a215f2e3ad3c228080148298272402eb767971fc340a09e89268aa37139615f5`。只读重新核 `20` 个实际静态文件、十模块与许可字节、PCK `404` 个成员的 MD5，以及4个根元数据、tuning与双语文案都匹配该受测源；[完整源和哈希](combined-native-web/offline-export-verification.json)。这里是本地严格导出，不冒公开发布。

导出前保留真实生成元数据。之后仅移除清单中的 `36` 个未跟踪 `.gd.uid`，没有盲目提交 import 或 UID；本次 full/export `WARNING:` 行实际 `0`，早期 import 日志仍保留自身警告。[生成清单](combined-native-web/generated-metadata-after-export.json)。原受测 fixture文本逐字节归档；收尾只把一条误写“恢复存档偏好”的测试注释纠正为 Main 固定中文，逻辑不变，不把修后注释冒原运行源码。

## 语言与普通体验边界

`Main._ready` 调用 `I18n.set_locale("zh-CN")`；I18n 自动检测与 Web 加载页也固定中文，当前没有普通语言切换控件。上表 v3 英文是受控原生鲁棒性检查，不能写成玩家在正式设置中切换了英文。旧 v2 说明错误归因为存档偏好，本页及汇总已更正；v1/v2/v3原日志、当时fixture源码和旧源码SHA完整保留。

普通 Web 标题入院 → **中文**悬停 → 移开 → 点击开合手帐，已经由独立 QA 在同一 fresh 页面中按 1280×720→390×844→568×320、DPR2 完成有限路径，并保全部原图/鼠标命令和前后完整 HTTP 包绑定，见下节。纯触摸产生 hover 不在本片承诺内，手机连接鼠标可以使用提示。桌面纸面贴底、文字完整，外扩阴影没有完全包含在视口中；不把纸面/正文完整写成全部阴影完整。

最终独立 SHA 审查、真实 PR CI、合入、Pages/manifest/公开 PCK 及正式体验均仍待完成。无新增语言设置、提示文案、玩法或未确认资源方案。

非作者 `pr130_validation` 已独立逐段核80套完成行/84进程分类、20文件流式hash、源码与59项历史档案清单；[预审原报告](independent-review/combined-prereview.md)及[独立数据](independent-review/summary.json)原样保留。这是原生与导出证据预审，不替代最终远端SHA批准。PCK404成员解析仍单列为实施助手实际离线核验，不冒审阅者重复执行。后续纯docs以真实双亲保remote相机`6eac2cc10c2060e4ee02a41b78a09acecafde20e`和全部PM/QA文档，[源等价证明](camera-dependency-docs-integration.json)；该时点仍候选未合，不宣称正式发布。

相机后续已经实际合入 `main267b0cb3df5842170877bf55e438917ad4253ce8`，其 tree 与已测试的最终候选相同；本片以真实双亲 `[41d4cb22a44cba446ec888e491fba2cde55b4c28,267b0cb3df5842170877bf55e438917ad4253ce8]` 生成 `51fc996fb36ec6ff061025e7b1e3a5c8fecabfd9`，tree 未变。[实际主线与源码等价证明](merged-main-source-equivalence.json)保留原4ab作者真实祖先及逐parent边哈希验证；稀疏对象库首次`merge-base`被无关旧对象缺失中止也单列，未执行大历史fetch。全部生产与tools字节仍等于a0导出；仅测试注释纠偏，不再重复引擎。这里确认依赖已合入，不追认其Pages部署状态。

## 独立普通中文候选体验

原运行者 `soft444_integration` 在 `2026-10-06T01:47:48Z` 启动唯一浏览器，`01:55:33Z` 正常 CLOSED，session86621实际退出0；无脚本/控制台错误，前后 source/tree、完整PCK、HTML、十模块及许可一致。一个fresh context同页真实resize三尺寸、实际DPR2/正常动效、普通鼠标，三次hover/leave/rehover及打开空手帐→“合上”回院路径通过。17张完整原PNG包括最后短横返回帧均保原字节；[QA原说明](ordinary-candidate/README.md)、[实际输入及来源](ordinary-candidate/result.json)、[真实退出](ordinary-candidate/execution.json)、[冻结接收与逐文件hash](ordinary-archive-receipt.json)。

图片工具HTTP503使原运行里的最后关闭操作延后，也中断了后续取图上下文；不是游戏错误，长时间停留也不是有意压力测试。root明确中止旧审图会话后，独立 `qa478_recovery` 只离线逐张亲看同17图并复核原绑定，没有重跑或改变游戏状态。运行者与接续离线验收者分列；原始analysis、JSON、run.py、HTML、PNG均未重写。本轮点击实际最小间隔约8272ms，driver下限550ms；不冒快速双击或#382验收。

视觉限于纸面和完整中文可读、提示消失/再现及手帐操作可达；桌面贴底阴影部分在视口外，不称完整shadow都可见。root另亲看桌面hover、竖屏rehover、短横rehover与返回四帧，仍保上述边界。没有普通英文入口、触摸/真机、键盘焦点、低动效普通浏览器、听验、存档故障或全部UI验收；候选体验不冒公开发布。只有这批473原件归入本功能，476公开证据单独归档。

只读接收28文件/17PNG/42,512,633bytes，内层清单SHA256 `794d558fc113135a45f58dfc6b3326d0fc42ec500d134d36e1fae8ddcb5db408`；对已冻结原图使用硬链接并逐文件64KiB流式复核，不复制大图或改变原始图。完整普通路径与原生细粒度边界互补；最终远端SHA非作者独审、真实CI、合入及公开后验仍由Leader按门禁完成。

最终root逐mode检查发现共享`test/godot_gate_test.sh`在整合时从真实基线100755误降为100644；已只恢复100755，文件blob仍为原受测a0的`3f1a8443bdfe7922f7262fdce4be7eed8ba32de4`。原full通过显式`bash test/godot_gate_test.sh`执行，原始受测mode/日志保持；恢复后实际直接`./test/godot_gate_test.sh`退出0、124mock（本片28）。[修正记录与准确退出](mode-correction.json)单列此可执行位修复，不把最终所有mode冒称与a0相同，也未为此重跑引擎/导出或改冻Web包。
