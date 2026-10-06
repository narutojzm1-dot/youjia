# camera400 候选普通站立与移动验收预案（未执行）

执行者：CODEX-LEAD委派hotspot36_qa。当前gate130_completion独占引擎，严禁先开browser/Godot。已只读camera400-code-prereview、issue400-readonly-causal-review，以及当前组合World quiet sky/Main camera流程。实际候选需等root给最终完整source/entry/PCK字节与SHA、完整manifest/依赖/URL并授权唯一browser窗口。准备source33bd42534d87ebd6e0cb0087d7ee0eaf258f548e不是已运行结论。

## 本次能证明和不能证明什么

只做有意义的普通相机回归：正常新开局、静止观察画面轻微取景、普通移动后画面回到非静观状态。**原生202checks里的quiet→goose预热/同tick接管是受控fixture；首个入院约10秒窗口尚未到鹅马的 `_day_elapsed >= 45.0` 真实秒门槛（不是假期第45天），且本次不安排鹅马/人物靠近条件，不能把这次普通站立取消称为故障状态链E2E复现/修复验收。** #400原用户2444×1502截图没有精确来源/先行操作，仍不归因、不标解决；Producer原Owner保持。

## 有限路径

- 单browser、renderer-process-limit=1，任何时刻仅一page/context；先390×844 DPR1 no-preference fresh。普通首页“走进院子”，不摸动物/不拍照/不发起携物或钓鱼，以免换成其它focus来源。
- 入院后约700ms保完整基线；依据现有真实5.5秒静止起点，在同输入批次等约4.7–5秒后保两张短间隔静站帧（截图开销与输入UTC均记实，不当精确引擎时钟）。若确有可见偏移，再普通ArrowRight短按约350–500ms，分别保输入后约300ms和1.5秒完整帧。点击/按键都不注入camera/World内部状态。
- 静态建筑/屋顶等地标的相对位置用于辅助肉眼判断视景变化，人物本身会移动，常规跟随带来的位移不与“旧camera offset必为零”混为一谈。没有读取Godot内部phase/active/target就不声称记录了这些数值。
- 按root最新限额：如果390第一次按计划没有抓到可辨的静观窗口，保原帧并记本路径NOT VERIFIED；仅可转入预定fresh1280横屏对照，不另开第二轮随机等待/刷新，也不设day/seed/clock。不能把自然4秒退场误记为移动取消。
- 如需要宽屏对照，仅加一组1280×720 fresh context，前一个明确after绑定/close后才new；短站立同样有限，可用普通可行草地点击作为移动输入，按实际画面校准非HUD非动物的位置。也可沿用键盘以免误触互动；报告写实际用法，不强求所有输入方式。
- 每视口仅一轮有限自然静站/移动窗口，不安排或等待鹅马稀有状态链；若第二有限窗口时间已超过45秒，也不能在没有实际事件证据时宣称经过预热/接管。正常无异常也只写本次普通路径通过，不升级为原截图成因被解。

## 来源和结束

每context before/after实读候选manifest/HTML/动态PCK/十存档模块/license，并核root source/PCK与manifest依赖哈希；记录实际loadedresponses、完整截图、按键持有/等待时间、page错误。若候选metadata格式与脚本不符，先只读校准，不能猜entry=data-build。结束所有context/browser并给root实际exit/关闭UTC和内存，之后只离线README/hash。

准备驱动：/tmp/camera400-candidate-browser.py（只compile未运行），输出拟/dev/shm/camera400-candidate-qa。普通click/key/hold/wait/shot/burst/只读DB，new必须先显式close旧context；无任意JS或业务setter。
