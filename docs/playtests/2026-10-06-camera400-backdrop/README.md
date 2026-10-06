# #400 静观背景覆盖：候选实现与实证

Agent-ID: CODEX-LEAD；Leader委派实施者 soft444_integration，独立审核另派。原总Owner GAME-PRODUCER 保持，不声称已回执或关闭 #400。

基线 `b9f68c3c5c4e70e16cefde9b4400bb1d553ff915`，[公开范围认领](https://github.com/narutojzm1-dot/youjia/issues/400#issuecomment-6006243273)。原465只负责静观与鹅马交接，本独立后续切片防止390普通静观时顶部新增露纸，不判断原2444×1502用户截图同因。

## 实现范围与取舍

World只读返回背景Sprite的实际矩形（含World与Sprite变换、center/offset/scale）及镜头请求来源；Main在请求发出时识别quiet，保留到其回程归零，新focus立即替换。phase已进入鹅马时，即使quiet标志尚未同tick yield也不误判为quiet。Main每帧以实际zoom/viewport/HUD及无焦点背景投影求覆盖区域，只限制quiet及其return；原有横屏留白保留。新helper没有合法背景/zoom/覆盖区时保持基准位置。其他focus沿用原投影，不改输入/modal/slider、存档、探索、天气资源和World465状态顺序。

不新增缩放或补画。390×844默认可玩高度704px与原画投影等高，因此纵向行程为零；该尺寸静观的纵向抬头会受到抑制，触发/保持/冷却/云带仍保留。希望扩大行程属于后续资源/构图选择，本片未批准新方案。

## 验证状态与边界

已完成下述原生红/红/绿与完整回归、严格Web导出；独立普通候选浏览器有限矩阵也已通过并逐字节归档。旧生产红样与修复绿样使用同一专项：真实Main._process→World.tick→信号→Camera2D.force_update_scroll，逐帧比较背景覆盖并核对真实canvas与Main._screen_to_world。测试显式固定seed/日序/位置/动物状态，Input.action_press用于受控移动；不是普通Web端到端。旧代码缺新增接口时仅跳过API辅助用例，红样不能由missing-method/parse失败冒充。

矩阵含390×844、360×640、568×320、1280×720，两动态模式，正常静站触发、两天气、左右边缘、移动回程、自然到期和静观中resize。鹅马路径在quiet触发后显式把日序秒数设46，沿真实World预热/phase0→1→2信号检查新来源立即替换，不冒自然随机遇见。辅助几何用例含Spritecenter/offset/scale、父平移、不同zoom与空/非法背景。

专项永久入口 `camera400_backdrop`，准确正整数完成标记与空失败列表；新增4个fake-executable门禁例子只证明注册契约。完整daily实际76套+1import=77启动、严格Web出口均通过。候选普通Web只按下方实际有限矩阵记录；最终SHA独立审核、组合源真实PR CI、合入及公开manifest/PCK/普通操作仍待完成。画面自然程度需另看真实原帧；真机/全部DPR/音频听感/存档全链不在本片新增覆盖内。

## 首次短窗口（失败原件保留）

2026-10-06 00:24:13–00:25:02 UTC，准备源码 `cf8b7f45536cf658d9540b9a4e692f986cce0bb4`：旧生产import实际exit0；同fixture旧生产exit1，38842检查中2018失败，其中2014是实际背景覆盖不足，另4是测试误把横屏原0.35强度也要求目标y<-80。候选exit1，38860检查仅同4个测试阈值错误；不能据此写专项通过。日志无SCRIPT ERROR，失败是断言。现在将意图检查修正为原来的精确目标：此fixture竖屏-150、横屏-52.5；覆盖与输入坐标条件不放宽，生产代码未因此修改。该修正后的实际复跑在后文按版本分列。全部Godot于00:25:02.807025Z结束，未启动browser/fullgate/export。

## 验证推进与独立预审拦截

- short-v3 没有重跑import而复用了缓存，同时已恢复tracked.import，四云带指向旧占位ctex名，发生资源解析错误。执行者主动终止该引擎，direct -15/outer1；这是环境失败，不计几何红样。日志保留。后续统一在整段验证结束后才恢复自动metadata。
- short-v4 严格串行import exit0、旧b9生产+修正fixture exit1（38842检查、2014真实coverage失败）、655候选 exit0（38860检查）。00:29:59.553557Z结束。该阶段仅证明当时fixture，无普通浏览器验收。
- 独立预审随后指出真实缺口：guard隐藏的raw offset仍约-150，新鹅马focus直接清guard会瞬间显现这个偏移，旧测试只比较raw投影反而接受了突跳。因此正在进行的full-v1已在00:31:34 UTC停止后续启动并终止自己的当前explicit_target进程，daily direct -15/outer1；00:31:40.859Z确认无引擎。未导出，不称完整通过。
- 返修只在Main记录每帧实际effective offset；新focus替换旧quiet来源前，以先前实际位移重设插值起点，保留新目标、zoom与速率。既有新holiday相机归零块同步清这两个新增字段，不改启动/保存流程。增强专项记录真实World同tick phase0前后camera/canvas，分别测试相同viewport与同tickresize；resize用新baseline加先前有效offset插值，允许resize自身基准变化。
- 随后的有效对照分列如下：旧b9证明原coverage缺口；旧655 guard+增强fixture证明接管连续性缺口；584返修绿样与完整gate/Web已实跑。不同对照计数分开列明，没有用静态计算冒相邻真实帧。

## 有效增强对照（同一 fixture，2026-10-06 UTC）

本轮源码 `58437ae8977f2f0ac1fd51dbdd61e2274ac12132`，树 `35ce69244b51a4d4c382ccde3517a429d55b0460`；原基线 `b9f68c3c5c4e70e16cefde9b4400bb1d553ff915`。先严格 import，再顺序更换两份历史生产代码，测试正文始终为同一 blob `39fa2da58308bfd20714e6e11ffb9c7a842306aa`。

| 对照 | 实际退出 | 检查 / 失败 | 结论 |
| --- | --- | --- | --- |
| b9 原生产 | 1 | 41,894 / 2,026 | 真实相机投影新增露纸，18 个去重覆盖断言失败 |
| 655 仅边界限制、未修接管起点 | 1 | 41,912 / 4 | 两动态模式分别在同视口 / 同 tick resize 时暴露旧隐藏偏移 |
| 584 接管连续性与新假期清理 | 0 | 44,734 / 0 | 完整增强专项通过，包含真实 Main / Camera2D 逐帧覆盖与输入投影 |

红样日志中的 ERROR 逐项对应上述失败断言；没有 SCRIPT ERROR 或其他资源/运行错误。新增接口与新字段生命周期用例只在实现存在时执行，所以三行检查数不同；不混成同一个计数。逐进程开始/结束、原始输出、失败列表与 camera/canvas trace 见 `native/short-v5/`。

正常模式、不 resize 的接管样本：655 在前帧实际 y=431.5909 后跳到295.3715；584 同一路径到438.053，等于从先前实际有效位移0向原鹅马目标132.5按原速率插值。resize 场景以新基准加前帧有效位移为比较基准，允许视口变化本身造成的位移；没有把 resize 绝对位置变化误判成接管跳变。新假期则通过真实 `_start_holiday(false)` 检查两个新增状态清理。

这是原生受控 fixture，包含固定 seed、日序、位置、动物状态以及受控移动输入；鹅马接管通过真实 World 路径但显式推进日序，不等于浏览器自然偶遇。检查数量是循环断言数量，不是独立玩家场景数量。

## 完整候选验证与最新主线整合

- `584` 的完整 daily 在00:54:26–01:02:03 UTC实际exit0：76套、含import共77次Godot4.7.2启动；新背景专项44734、原交接专项202；68个模拟进程门禁包含既有14个交接完成契约和本片4个背景完成注册例，另2个Node程序。
- retention的11项单元测试、本地真实publisher fixture、严格Web导出全部实际exit0；出口01:02:11.069Z，01:02:15.183Z确认无Godot活进程。最后才归档并恢复5个自动`.import`及自行生成的UID，清除本片ignored导入缓存36,196,175B，保留源、原件与导出。
- 冻结候选`index.pck` 27,091,948B，SHA256 `3e571c5bd0cec3ec5404ce73e6a1157a79169134b229a2b0d219f4bf7ca75b02`；十个存档模块/license按584精确blob打包，实际HTTP下载复核。最终候选清单见`native/candidate-release.json`；`full-v2/candidate-release.json`是导出阶段尚未补静态依赖的历史快照。
- `prepared-source*.json`以及结果内嵌`source.native/source.browser`是准备时的原始快照，保留其当时时态；实际结论见逐步骤结果与`native/validation-overview.json`。`full-v2/result.json`的`mock_new_camera_format=14`命名沿用旧驱动，指既有交接契约；本片新增的是4例，不能写成新增14例。
- 之后离线三方保留最新main `8ae57959ff95117047c4362704c298b583d651a7`（含Cloud467、PM/167及474文档）。Main/World、本片专项与门禁逐blob等于已验584；唯一运行差分是Cloud的`find_reveal.gd`、`near_path_scroll.gd`、`exploration_slice_suite.gd`，三个精确上游blob均原样保留。`integration/integration.json`记录真实双亲；不因合并文档重跑旧样本，最终组合完整CI/导出及正式公开后验仍须完成。

尚未创建/合入本片PR，不把候选source当正式发布，不关闭#400。

## 独立普通浏览器候选（584）

`browser-candidate/`为独立QA `/root/hotspot36_qa` 原件，31文件/30条内部哈希/17张完整PNG，SHA256SUMS自身 `284f01e07694a840e25622fecc18259ea3ed590330a0db3d05240dee9328ba8c`。2026-10-06 01:05:13–01:07:33 UTC，driver实际exit0、context/browser全部关闭；仅一个fresh Chromium context，DPR1、中文、普通动态，同页390×844→568×320→390×844。

普通标题进入院子，竖屏在入院后实际5.516/6.512/8.004秒取图，真实ArrowRight移动、松开、回稳；横屏在首次松键后28.006/30.005/32.005/34.004秒取样，再ArrowLeft、回稳、返回竖屏并实际点击花箱按钮。完整原图没有旧顶部浅纸空带；窄条辅助诊断前缀0行不能单独冒全屏证明。竖屏静候地标近似位移(0,0)；横屏约+4/+4/+2/0像素并返回，仅是原图可见变化，未读取或推断引擎quiet内部phase。默认竖屏零纵向余量会抑制该轴移动，不能凭无移动断言触发失效。

花箱一次真实输入出现蝴蝶和对应文案；末两帧阴天、上一帧晴天，其间约34秒，未拍转场或核定触发原因，没有天气按钮输入，不归因于花箱、不当#51完整天气验收。前后manifest/HTML/实际完整PCK、十模块/license核对同源，13条实际资源加载响应200，pageerrors为空；控制台只有引擎/渲染/加载信息。

未覆盖第二reduce浏览器样本、普通随机鹅马相邻帧、原用户2444×1502截图因果、全部天气/探索返回、真机触摸、全部DPR、听验或存档全链。两动态模式与同tick鹅马来自上面的原生受控fixture；不混称普通Web。Leader与实施者也看过完整竖屏8秒及横屏30秒原帧；这不替代最终非作者审核。

## 最终集成门禁

本地候选保留584、8ae及后续d210主线真实祖先，Cloud和滑块原件均保留；以上native/浏览器仍精确归584，随后三方组合见下一段。最终组合完整PR CI、导出、非作者最终SHA批准、正式合入和公开manifest/PCK及普通操作验收均由后续实际结果补录。本提交未宣称其中任何未完成步骤成功，也不关闭#400。

原始HTTP HTML末尾空行与Git diff的上下文缩进按字节保留，完整`git diff --check`因此exit2（6个原件加逐字节保存的诊断日志自身，共7个明确路径）；实现/测试/门禁及维护文档的范围检查exit0。没有为消除诊断而改原始取证，详见`integration/whitespace-audit.json`。

## 与已合476主线的最终三方组合

滑块PR476已由其Owner完成独立审核/实际CI后合入main `d21030dfc243926b7e6a1849151ada1eadab75ef`，该主线也保留Cloud475的25个新增文档。本片在`197db8cdd59a7448de0d6dba3d555af8d25947d1`上再以该真实main为第二parent，得到运行冻结源`4598df52591db795f1441f4dd22a53df1df4a61c`、树`892be1e99ff3bece331648e7cec7e140929dba94`；后续仅整理本段文档。

- Main/World、本片GDScript专项与UID仍逐blob等于584；保留Cloud467的3个原blob、滑块作者9个原blob（含autoload、project.godot及两专项）。本片没有重写其生产代码。
- 三个共享验证入口按独立增量合并：保主线两滑块专项/两个准确完成映射及28个门禁案例，再加入本片一个专项/映射和4例；daily可执行位100755保持。静态枚举78个不同专项入口及每项完成映射；最终完整运行预计78套+import共79启动，当前不宣称此组合已跑Godot。
- 合后真实`bash -n` exit0，fake-executable门禁实际96例PASS，原14交接与28滑块专门完成标记各一次。该结果只证明包装器/登记，不冒78套原生或浏览器验证。原命令/退出/日志及九blob清单见`integration476/`。
- 此组合比584增加了Cloud生产和滑块autoload/项目接线，故不能将584原生/普通Web结果冒新组合已通过。最终非作者审查、真实PR组合全量CI及Web导出、正式公开后验仍待。未再次启动本地Godot或浏览器，也没有改动冻结候选导出。
