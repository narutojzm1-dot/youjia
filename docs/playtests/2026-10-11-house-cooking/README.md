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


## 2026-10-11 午间返修：自主晚饭不转为睡觉

Owner CODEX-LEAD，PR #738；回应评审评论 6105288353。自主饭点请求使用独立 house_meal 意图，抵达门口重验饭点与食材；失效即取消，只有玩家 house_door 请求才允许夜间睡觉。HUD/键盘继续保留该用餐意图。

真实 World 路径回归从 20:59 附近出发，走到门口时跨过 21:00，确认没有进屋睡觉、没有扣食材/餐次记录、没有跨日或写入已睡状态；随后显式点门仍能睡到第三天。house_cooking_suite 50/50，house_sleep_suite 154/154。

同时将烟囱粒子延迟至首次真正做饭时创建，取消/普通夜景兼容未创建状态。原 b3f1a02 的 ground-food 测试本地与 CI 均复现四项失败；修改后原种子 0 的同一套真实觅食/持久化测试 75/75。此证据说明初始化改动解除该回归，不宣称穷尽所有动物随机布局。原失败和修复后完整日志分别保存；没有删除、放宽觅食断言。

本节为原生运行验证，未冒充普通 Web 三餐实玩。全量 CI、普通 Web 做饭和音频验收仍须另行记录。


## 普通 Web 用餐实玩与时钟补修

d6013889f8d0d39a38325718a05635c4043b08ca 的正常浏览器流程已走通：localhost:8767、1280×720，未注入游戏数据；正常进入小院、点击池塘抛竿/收竿，获得中鱼1，背篓确认后关闭。第二天午饭时自行沿正常路线回屋，关闭房门、出现正在做饭状态，随后阳台刷牙再从一楼回院；中鱼变0、麦粒2/玉米2不变，重开后仍为0。console error/warn为空。这是实际普通 Web 流程；原先 cook/balcony/out 原生夹具截图仍单独保留，不能混写。截图 web-cooking.jpg 实际捕获的是饭后阳台阶段，非烟雾清晰度证据。

本次重开发现餐次与食材已存，但时钟退到较早自动存档。继续修复：餐次提交同时捕获进屋时的时钟/天气，以同一队列事务确认；无效时钟整笔拒绝，不能只扣食材；更旧事件不覆盖队首更新的时钟。真实原生重读回归 cooking 51/51、meal ledger 85/85、rest context 43/43。新版普通 Web 时钟复验需补记录，当前不声称全量完成。合入 main c28246f14dd8bca837624699ca9447124e39d0d1 时，仅协调台账追加冲突，保留 Assistant #739 与 Cloud #741 原提交。


## 2026-10-11 15时：选材可见与最后一轮普通Web证据归档

旧头162aab19bb7f0bb79fb8bc2b73e1fa75675ac652的完整CI38115830287 / job114400412219现已success（含全量验证/Web导出）。本次新增表现尚须新头CI，不把旧CI冒作新头通过。

进屋前在旅人实际手部锚点显示所选小米/普通鱼，比例随景深/人物缩放，跟随翻转与入门透明度。进入房间、取消、出门均收起。它只是做饭计划表现，不写第二套手持账本，不提前扣料；已持物时不能再启动做饭形成叠物。没有新增走向实体背篓取物的动作，不能把当前门前出现食材写成完整取料演出。

- `ingredient-cooking.log`：60项真实Main/SaveStore回归，持物互斥、手锚点、鱼/小米选材、关闭/取消/返院清理及旧餐次/跨饭点边界均通过。
- `ingredient-food.log`：原地面食物回归75项通过。
- `ingredient-porch-controlled.jpg` / `ingredient-gpu.log`：RTX4070/OpenGL原画门前小米实渲染；明确为受控fixture，非普通玩家从背篓取料录像。鱼类型由回归覆盖，尚无普通Web手持鱼视觉验收。
- `web-clock-dinner.jpg` / `web-clock-reopened.jpg` / `web-phone-basket.jpg`：归档上轮普通Web实际晚餐、重开仍在晚餐之后、390×844背篓。该导出是在时钟修复后、CJK742整合前；重开时钟样本可能已有周期保存，不单独证明原子确认时点，原生51/85回归才覆盖该原子性。

#745已指定GROK-CONTRIBUTOR制作做饭声/饥饿短声叶子与事件接入，待本人回执；未称已开工或听验通过。声音、完整取料、磨盘/面食/蛋奶、AP实际劳动和经验仍待，#700保持开放。


## 2026-10-11 17时：实体背篓取材再回屋

Leader接续738：用原可走路线先到实体背篓APPROACH(335,522)，在背篓前选定可执行食谱并短停1秒，然后带同一材料/修订号走回房门。1秒为制作细化，尚未新增弯腰取物专用动画。门前不再凭空生成新选材，直接点门也先取料。选择不预扣库存，不占用第二套持物账本；从背篓取材、持料走动到原子完成前仍可取消。

原生house_cooking82项通过，包括真正走到背篓、取材后原计划不重抽、手动走动取消、背篓前取消、途中库存改动、拿好材料后跨饭点取消与原有真实保存/显式睡眠对照。physical_basket与HUD72通过，先前同实现sleep154/food75通过。GPU basket-take/open.jpg与basket-gpu.log来自真实Main受控小米夹具，明确非普通网页或专用取物动画验收；原画脚点、食材手锚与屋门可见。普通Web新路线与最终CI另验，旧a24 CI38120865825 success不代替新SHA。

Grok已回执745并交747候选56272e4e20c4764bdb17a063dd7c4ce77674b8b4。Leader静态审核退回暂停饥饿/本叶子短音清理、自动伪手势解锁及daily未接套件（5482683568）；共享GitHub账号拒绝REQUEST_CHANGES，COMMENT明确不通过，不冒充运行或听验。叶子文件保留Grok Owner，Leader独立完成本取材切片。


## 本轮普通网页取材、用餐和重开验证

受测运行代码为0937d166e44ea753113618cf1be32010a97d238b（与本地6f08dcc15a1f04b01404919fabbc81784357fdf0同树），localhost:8769、1280×720，复用浏览器旧第3天档，未注入或清空游戏状态。正常垂钓获得小鱼1，第四天8:57出现自主回屋提示并走向背篓，随后房内“正在做饭”，10点角色从一楼回院。背篓小鱼1→0，麦粒2/玉米2不变；正常刷新、从标题重进后仍为0/2/2，console error/warn为空。

web-stock-before/after/reopened.jpg分别为上述真实库存；web-basket-route.jpg实际截到房内做饭阶段，文件名不代表捕获了背篓取材瞬间。此次未及时截到普通Web手上鱼、阳台刷牙分支或清晰烟雾，不据此宣称三者视觉验收。受控basket-take/open.jpg继续单独标记。本轮Web不包含其后main的相册布局合并；该合并的针对性回归及最终CI另记。


## 2026-10-11 19时：一次输入接管与连续闲置（#738 / 6107665083）

基线4588a2c CI38128841480 success；本增量另测。保留8秒连续闲置、8秒做饭、30秒取消冷却；面板/真实按键或点按/应用回前台重置闲置，第一段走向背篓也能取消并冷却。最新一个指针或背篓意图跨屋内安全退出保留，拿食材可立即交还；保存未决不改写原事务，确认后接管不重复消费。阳台接管立即释放镜头，减动效取消额外放大；阶段提示/动作按钮使用已有UI。

最终源blob及Web PCK哈希见handover-source.json。113项做饭回归、HUD指针72通过；同导演睡眠154、面板遮挡通过。误调用不存在hud_paper_suite的命令已排除，改跑真实hud_under_menu_suite通过。未替代完整CI、真机或声音验收。

普通Web localhost:8769、1280×720、原第4→5天档，不注入存档/时间/库存：
- 正常钓鱼得小鱼、房间吃晚饭；随后正常睡到第5天，早饭后出现阳台刷牙。web-brush-handover-before.jpg为真实刷牙阶段，点击一次背篓后安全出门打开面板（after），小鱼1→0属于已经确认的用餐，不当作取消保全证据。这两图在最终持续提示键增量之前，接管代码相同。
- 正常再钓到中鱼1。最终导出重进旧档，12:07自主开始取材；一次背篓点击取消首段，中鱼仍1（web-approach-cancel-stock.jpg）；关闭后9秒不重启（cooldown）。
- 在冷却内主动点门仍可做午饭；12秒后截到闭门、旅人隐藏、烟囱冒烟及“屋里正忙着做饭呢 / 回院子”（web-cook-cancel-before.jpg）。随后只点击一次背篓，7秒后安全出门且原点击打开面板，中鱼仍1、麦粒2/玉米2（after）。因此取消发生于未确认做饭，库存未扣。
- console error/warn为空。真正关闭30号页、新开31号页、标题进院打开背篓仍中鱼1/麦粒2/玉米2（web-cook-cancel-reopened.jpg），无error/warn；照片不代表连续录像、手机真机或已接入做饭声音。全成长#700仍未完成。
