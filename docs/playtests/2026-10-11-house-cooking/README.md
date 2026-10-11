# #700 房间做饭候选（2026-10-11 11时）

Owner CODEX-LEAD。基于731候选db4704afe8100f56a5e2df225cfb69e5548e13ec，保留已复审Grok723 d58e65e272723e13782dc718e8da65f93735c2c5完整祖先。未发布，非完整成长验收。

## 实际实现

现有库存小米/小鱼/中鱼，50/50选材，小米粥或鱼汤；7–10/12–15/18–21为三餐窗，闲置8秒后沿原路径回屋。以上食谱/时间窗/8秒烹饪为制作人首版细化，非用户指定数值。手动走动/已有目标/牵行/钓鱼/持物/面板阻止自主抢控；用户输入可打断尚未提交的做饭，出门且不扣料。三餐不消耗AP。做饭事务确认后80%刷牙，20%直接出门；保存未知不换写入，业务拒绝出门不弹错误存盘框，真正写入失败保留同一计划与重试。

## 证据与边界

原生Godot4.7.2：house_cooking38、save_feedback50、house_sleep154、planner28、rest43均通过。涵盖真实Main/World门路、前后库存、疲劳早餐0、晚餐1、两种出门分支、取消、并发变动拒绝及native_load重读。使用隔离测试存档布置时刻/原料并直接推进World tick，不冒称普通鼠标完整体验。

RTX4070/OpenGL实际Main渲染cook/balcony/out三阶段，JPEG为直接引擎截图。截图来自受控8点小米用例，主界面在截图时刷新；不是网页、手机或自然玩到饭点的证据。首轮截在刚进阳台/刚出门，人物尚未显现，已调整为刷牙动作和出门中段再截，未拿早期帧作动作验收。

仍未完成：做饭声/肚子叫与真实听验、拿食材的手持表现、头顶饥饿泡、普通Web往返/刷新和手机做饭体验、磨盘/面食/产蛋采奶初期供应。未实现AP花费/结转、经验或自主世界劳动。早期面食方向保留，小麦未被当成直接可吃；奇怪鱼不入食谱。候选保持Draft，满足这些适用条件前不称整套玩法完成。


## CI follow-up / integration with Assistant #737

CI38108336924 on4238830 failed the old UI interaction fixture: fixed tap(780,480) hit the moving llama (759.46,525.38), releasing its rope. Six failures cascaded from that mistaken input. Local reproduction retained in ui-original-failure.log. The corrected fixture resolves an actual empty walkable point before real viewport touch, explicitly checks movement, and retains the lead/release assertions; it does not disable cooking or change gameplay to pass tests.

Integrated main3caeb1fe6082da0cf0db00e3bea20dc47eb50edf (Assistant #737) preserving original commits. Completion-table conflict retains both cooking suites and HUD pointer suite. Integrated native checks: cooking38, UI67, HUD pointer72 passed. A mistyped hud_mouse_input_suite invocation failed because no such file exists; the correct hud_pointer_input_suite72 then passed.

Ordinary local Web export of4238830: release export succeeded; CUA browser entered title and yard1280x720 and opened/closed the actual grid basket, with no console errors at that check. Fresh save contained wheat2/corn2, no millet/fish; no ordinary browser meal completion has been demonstrated. Native meal fixtures are not a substitute for the still-missing ordinary food-supply/cooking/phone/audio acceptance.
