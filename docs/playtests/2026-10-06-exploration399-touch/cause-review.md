# #399 只读因果线索审查

Agent-ID: /root/horse180_repro。未实施修复，未认领 Main/Cloud 修改，未重跑公网或执行状态注入。

基线公开 ecea67dba1afc9b99b6097970e4965fbcd99c53a / PCK 2f3ef524dcd455bf2ffddc8aa064e1f6a707f3fef5fd08b8fb5254f7b33c8085。本地 HEAD b8831aa730540f16dc5e5e3953fadb4ead7f7b73；git diff ecea67d 对 scripts/main.gd、scripts/exploration/exploration_director.gd、scripts/exploration/near_path_scroll.gd 为空。读取了 /tmp/gate399-public-inputs/README.md 与 observed-retry/run.py。以下是代码约束，不是已复现调用栈。

## 已知事实与最窄线索

两次 fresh 触摸样本确实进入探索且最初未弹回。第二次 (706,500) 普通路面触摸后、点击门之前已出现初次入院文案。一次导航/DOMContentLoaded/引擎启动并不证明内部没有重建世界，但不支持浏览器重载解释。不能将返院画面作为正常门交互 PASS。

1. `Main._start_holiday` (949–1005) 是 scripts 中唯一显式 `_show_notice_key("notice.arrive")` 调用；对应“风很轻。你把行李放在门口。”。它会 interrupt 探索、flush、clear/new YardWorld、重设 camera/game UI，随后重新 `ExplorationDirector.attach`。正常 `_on_exploration_returned` (1053–1065) 恢复现有院子，默认显示“回到院里了”，不会调用 `_start_holiday`。
2. `_start_holiday` 只有 `_on_play_pressed` (862) 与已确认 restart (1133) 两个直接调用点。标题 `_play_button.pressed` 在565接入 `_on_play_pressed`。play 回调及 `_start_holiday` 都没有 title-only 或正在启动的防重入检查；后者 `await SaveStore.flush_pending()`，而 flush 在 coordinator 非空闲时逐帧等待。因此“多次进入启动/晚到 continuation”是具体可检查风险，但现有截图没有证明它实际发生。不可将普通路面坐标直接解释为隐藏标题按钮被点击。
3. `ExplorationDirector.attach` 新建 host 并执行 restore；host restore 对未结束 trip 提交 restored=true。`outcome_notice` 143 只有 committed、空物、restored=true 才返回“上次出门走到一半，已经回到院里了。”。这是恢复路径提示，不等价于正常门返回；它可能是后续异步 settled/retry 提示，截图时刻不等于恢复函数调用时刻。
4. 近郊 `press_at` (328) 只会命中自身按钮或计算路面 target/home；Director `_finish` 只 request_return、释放 scroll、emit returned。已读普通探索输入/退出链没有 `_start_holiday` 直接调用。这显著收窄为启动重入/跨层输入或生命周期时序候选，不能据此排除其他异步调用。

## 触摸分派的确定边界

Main `_input` 451–480 对 ScreenTouch pressed 手工 `.pressed.emit()`；音频按钮有 is_pressed 例外，标题 play 没有该例外。事件处理后 set_input_as_handled；合成鼠标仅对左键 pressed 且距 last_touch<400ms 吞掉，release 不在该过滤条件内。是否先发生 native GUI mouse press、是否留下 BaseButton 按压状态，必须观测实际事件顺序，不能从这段代码推定。

exploring 状态下 Main 手工候选数组落入普通 HUD else，但隐藏 HUD 按钮受到 is_visible_in_tree 过滤；Main `_unhandled_input` 又只处理 game。探索自己的 `_unhandled_input` 287–324 处理 touch 并记时间、400ms 鼠标去重，再调 press_at。因此正常架构应把探索路面交给 scroll，未发现直接把其触摸映射标题 play 的显式代码。

曾在 #382 确认过手工/GUI混合路由风险，但 #382 的 slider-first 证据不构成本问题因果证明。Assistant 正修改确认/暂停输入；本报告不要求他同时接受未证实的探索修复。

## 建议的一次最小观察（隔离诊断构建，不改公开业务状态）

由 Leader 协调 Owner 在隔离候选记录：

- Main `_input` 入口及返回、近郊 `_unhandled_input`：frame、tick、事件类/pressed/index/device/position、screen、handled 状态。
- 标题 play 的 button_down/button_up/pressed/gui_input，及其 visible-in-tree、rect、is_pressed；同时记录 `get_stack()` 于 `_on_play_pressed` 与 `_start_holiday`。
- 每次 `_start_holiday` 分配只用于日志的 call id，记录进入/flush前后/world实例/scroll实例/退出；不要加 guard 改变被测时序。
- `_on_exploration_entered`、Director attach/interrupt/_finish、returned 与 host restore/settled：精简记录调用序号、reason、restored、state，避免导出存档内容。
- 同步 notice key 与记录时间，分清“晚到 notice”与“世界重建”。

仅复用一次原始 title tap→出门→等候→(706,500) 路面，不增加找物矩阵。如果第二次 start 出现在标题首个 tap 的同帧/flush期间，查重复 GUI 启动；如果它出现在路面 tap，查实际 signal/stack；如果没有第二次 start，查 notice 队列和世界可见性/Director host替换。缺日志前不得宣布根因已找到。

修复验收条件应包括启动一次、近郊普通路面输入不创建 YardWorld/attach、不出现 arrive/restored 提示、真正门返回才走 returned；原触摸路线及已通过鼠标空篮路线都保留。携物/键盘/物理设备仍另行验收。该报告未证明当前具体根因，也未宣称修复。
