# #36：公开三热点在浏览器低动效偏好下的有限体验

Owner：CODEX-LEAD；执行：独立只读 QA 助手 `hotspot36_qa`。原单认领 [6002251146](https://github.com/narutojzm1-dot/youjia/issues/36#issuecomment-6002251146)。本次只补已有首批三热点的低动效表现和普通走动退出，不新增热点、不改运行代码、不关闭父单，也不重复 PR416 的携鱼范围。

## 运行与来源

- 实际输入：2026-10-05 20:30:46–20:33:04 UTC（北京时间10月6日04:30–04:33）。浏览器20:33:19 UTC关闭，驱动退出0。
- Chromium，Linux headless，1280×720，DPR1，新 profile。**上下文创建时模拟** `prefers-reduced-motion: reduce`，首页前 `matchMedia` 返回true。这是浏览器媒体偏好模拟，不是物理手机或真实操作系统设置实测。
- 固定加载公开 `game-089d453`，完整源 `089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21`。实际加载 JS/WASM/PCK URL 与 HTTP 状态见 [result.json](public/result.json)。前后获取的公开 manifest 和 HTML 都仍为同源；期间没有重载游戏页或混用后台新版本。
- 前后分别实际下载公开 PCK：**27,088,396 bytes**，SHA-256 **fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8**，均HTTP200；保存计算结果，不把响应头当实际哈希。原始 manifest/HTML、完整输入与时间在 `public/`。本切片没有独立复核十个存档模块字节，不套用其他轮次的验证结论。
- 只用真实鼠标与键盘；没有注入游戏位置、种子、时间、库存、反馈状态或存档，也没有调用内部成功反馈接口。唯一初始化探针记录普通首帧事件；媒体查询只读。驱动保留了未执行的只读DB命令，但本次输入没有使用它。
- 本次主运行无 `pageerror`、浏览器崩溃或 console error；不等于所有平台无缺陷。

## 实际体验结论

| 范围 | 普通操作与截图 | 结论 |
| --- | --- | --- |
| 花箱静态反馈 | 点击院子二楼花朵 `(350,240)`，旅人本来已在花箱安全站位附近；[00](public/02-flower-reduce-00.png)、[01](public/02-flower-reduce-01.png)、[02](public/02-flower-reduce-02.png) | 花瓣与蝴蝶出现，专属短句可读；三帧中外形/位置肉眼稳定。后续[03](public/02-flower-reduce-03.png)、[04](public/02-flower-reduce-04.png)自然到期消失，不能把这轮稍后的走动当作在途取消。 |
| 花箱普通退出 | 再次点击，先拍到[有效花瓣](public/04-flower-repeat-active.png)，再按住ArrowRight 350ms，[走开后](public/05-flower-cancelled.png)旅人位移、花瓣不再显示 | 实际走动退出观察已覆盖；截图不是逐帧记录，不能声称测出了取消延迟。 |
| 岸石静态反馈 | 普通点击地面 `(550,470)` 走近，HUD显示“水塘岸石·拨一拨水”；按Space，记录[00](public/07-shore-reduce-00.png)、[01](public/07-shore-reduce-01.png) | 可见宽水纹及专属短句；两帧外形/位置肉眼稳定。本次使用可见HUD主键目标，没有重复证明每一种岸石鼠标命中路径。 |
| 岸石普通退出 | 等前轮结束，再Space，拍到[有效水纹](public/08-shore-repeat-active.png)，ArrowLeft 250ms，拍[走开后](public/09-shore-cancelled.png) | 旅人移动、水纹退出；不涉及钓鱼中/持鱼中优先级，也不声称逐帧取消延迟。 |
| 栅栏静态反馈 | 普通点击地面 `(800,450)` 走近，再点真实栅栏 `(886,404)`，记录[00](public/11-fence-reduce-00.png)、[01](public/11-fence-reduce-01.png) | 门边弯草画与专属短句可读；两帧外形/位置肉眼稳定，没有开门或穿栏。 |
| 栅栏普通退出 | 再次点栅栏，[有效弯草](public/12-fence-repeat-active.png)，ArrowLeft 250ms，[走开后](public/13-fence-cancelled.png) | 旅人位移、弯草退出；不声称已覆盖触屏或所有在途阶段。 |
| 自然偶遇 | 不刷新概率，走近岸边时[拍到蜻蜓](public/06-near-shore.png)，走近栅栏时[拍到棚羽](public/10-near-fence.png) | 两者各一帧，只证明本次自然走近能遇见；**不能用单帧证明其跨帧静止**。花箱蝴蝶则有三帧。没有强制收集或为彩蛋无限等待。 |

[像素比较](public/pixel-comparison.json)以原PNG中的明确矩形比较花箱、岸石和栅栏反馈区域；所有比较最大RGB通道差均为1（不是零），因此**不宣称像素完全相同或色调完全冻结**。花箱三帧截图完成时刻跨度约1.970秒；岸石两帧约0.918秒；栅栏两帧约0.710秒。截图本身耗时，`interval_ms`只是额外等待，并非真实帧率。动物仍正常活动，天气也按原逻辑变化；不把背景或动物自然活动当成反馈摇动。

[派生操作时间](public/timing-analysis.json)保留输入调用时刻：第二次花箱/岸石/栅栏方向键分别在触发调用后约0.890/0.996/0.974秒发出，小于代码名义反馈窗1.8/1.65/2.0秒；此前一帧都有反馈，后续帧均无反馈且旅人位移。不过截图完成和实际渲染时刻不同，尤其截图完成可能晚于自然到期，**证据只支持普通走动退出观察，不单凭两张图断言退出完全由取消而非到期造成**。这不是毫秒级实时门禁或立即消失的严格证明。名义时长来源为同源[反馈代码](https://github.com/narutojzm1-dot/youjia/blob/089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21/scripts/game/yard_scene_feedback.gd)。

## 明确保留的问题与未覆盖

本轮自然切到旧阴天底图：[花箱第二轮](public/04-flower-repeat-active.png)花瓣位于窗旁空处，而非晴天同一花箱构图。这是仍开放的[#51](https://github.com/narutojzm1-dot/youjia/issues/51)/[#168](https://github.com/narutojzm1-dot/youjia/issues/168)同院子构图与锚点问题；本次没有修复，也不把“静态反馈可见”当作阴天美术验收通过。岸石仍按原世界锚点反馈。Producer已有资源在途，本QA不接管绘画或接入。

没有覆盖真实听验（headless且mute audio）、音效舒适度、物理设备、触屏、全部携物/钓鱼组合、运行中切低动效、重开存档、所有天气/昼夜/缩放、其它热点、新资源或完整#36。原#36保持开放；低动效可读表现仅上述观察点有新证据。

## 启动控制失败保留

第一次独占窗口启动已加载首页，但执行工具会话句柄未保留，尚未进行游戏输入。为恢复可控输入，只对本驱动发出SIGINT，并由finally关闭所属浏览器，20:29:37 UTC结束；原记录完整保存在 [startup-control-failure](startup-control-failure/result.json)，包括 `KeyboardInterrupt`、首页PNG、前置来源和原驱动。随后主运行才建立另一个新profile；两次浏览器没有并行。此为QA工具控制失败，不是游戏崩溃，不把它删掉或列作游戏通过。没有以重开刷彩蛋。

## 材料与复核

- `public/`：20张原始PNG、驱动、完整输入、before/after manifest与HTML、比较与时间派生记录。
- `startup-control-failure/`：第一次无游戏输入的控制失败原记录。
- [analyze.py](analyze.py)：只读取归档PNG/JSON，重算像素和操作时间，绝不改变游戏状态。
- 原始HTTP HTML保持取回字节和末尾空行；不为消除diff空白提示改写证据。
- [SHA256SUMS](SHA256SUMS)：归档文件哈希（不含清单自身）。`.gdignore`使本纯文档证据不进入Godot资源导入。

本证据独立分支PR完成最终SHA审查后归档；未审核前不称已合入。没有新的运行时功能或发布，不触发普通里程碑邮件。
