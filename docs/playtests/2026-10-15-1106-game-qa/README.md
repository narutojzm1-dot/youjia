# GAME-QA 2026-10-15 11:06 需求验收

**需求整体未通过：新雾仍隔离候选；自主建筑已改灶台方向但当前生产仍旧池岸；磨盘可见不等于磨粉闭环验收。** 本轮没有把发布构建变更当作功能已交付。

## 增量验收矩阵

|需求|Owner|验收标准|证据|结论|
|---|---|---|---|---|
|#749/#644 雾与云|ASSISTANT正式近郊 / GROK-BUILD候选|可见连续动态且水面局部遮罩正确|PR803明确仅art/concepts隔离候选、未接near_path_mist；候选合入不是实际功能发布|尚未发布（本次新雾候选）；旧动态整体仍证据不足|
|#700/#801 灶台|CODEX-LEAD|取石搬至院内施工点，打造动作与分阶段灶台形成；阶段持久化和去重|有效方向已改，PR801仅策划文档；生产growth_schedule仍POND_RECIPE、rim站点|尚未实现新方向，旧垒石不能替代验收|
|#700/#797 磨粉|CODEX-LEAD|物品与AP支持的磨粉/入库/用面粉计餐，普通玩家完整闭环|旧第7天能看到磨盘；本轮未获得计餐食材/AP并实际完成磨粉|部分实现证据；完整需求证据不足|
|#642 花草|CODEX-LEAD/ASSISTANT|外采→携回→重新布置、保存/取消边界|沿用PR800原花草开关的已确认差距；本轮未重复收放|部分实现，未关闭|
|#704/#745 声音；动物运动|原Owner|可听真实输出；持续运动无短周期左右卡死|未完成听验/连续复现，不把组件通过当验收|证据不足|
|main背篓首次纸片修复|CURSOR-CLOUD|首次打开贴合布局|main f29b056，受测页面7d79ae6，不混同|候选未按本轮发布验收|

实际页面game-7d79ae6，完整SHA `7d79ae681a2acc21aabfce9b1db36b772d513f28`；gh-pages相同。main f29b0563f195c91833127da17c0a9cb9aac714b0另含背篓修复，未混作受测。Release/tag空数组。PR800 OPEN无新评论/评审。源工作区修改保留，独立qa-checkout-7d79运行自动专项，不开发实现。

## 实际体验与限制

Windows/IAB tab1，874×645。刷新加载页显示新构建，标题点击一次工具发送超时，下次观察已进入旧第7天21:31、草槽1；截图01-mill-oldsave.png。磨盘实际出现于院内牛马间。点击磨盘位置没有观察到独立手动磨粉菜单，不据此判BUG，因为现行设计为自主行动。没有注入物品/AP，没有跳时间；本轮没有完成食材→计餐→磨粉→面粉计餐闭环，不能记通过。最终暂停保留测试现场。

静态核对PR803：明确未改生产资源、未接near_path_mist，候选虽合入也不能说新水雾在玩家页面出现。PR801已确认用户新方向取石→院内施工点→打造动画→灶台阶段形成；此PR仅文档，生产growth_schedule仍保留POND_RECIPE和rim站点。这是需求交付差距，不是新发现崩溃BUG。两原件pr801.json/pr803.json已留档。

## 自动结果（不等同体验验收）

官方Godot4.7.2，隔离APPDATA/XDG且profile-probe验证，目标完整SHA同线上。各项实际执行结果：
- import: 0 []
- growth_production: 0 ['GROWTH_PRODUCTION checks=132 failures=0']
- milling_director: 0 ['MILLING_DIRECTOR checks=162 failures=0']
- flour_meal: 0 ['FLOUR_MEAL checks=24 failures=0']
- yard_mill_view: 0 ['YARD_MILL_VIEW checks=21 failures=0']
- growth_budget: 0 ['GROWTH_BUDGET checks=77 failures=0']
- growth_carried_photo: 0 ['GROWTH_CARRIED_PHOTO checks=39 failures=0']

null/未运行不算通过；环境超时与产品BUG分开。原生检查不能证明动画自然、声音可听或在线玩家完整流程。原有无变更历史问题未重跑。完整步骤、失败边界、存档兼容等缺口见每日矩阵。

下一轮先补磨粉正常玩家闭环及新版需求对应的施工实际实现；灶台未实现不沿用旧池岸通过结论。新雾待正式接入后按水面遮罩与连续动态验收。声音、动物卡住继续保留用户反馈，不以本轮未复现否认。记录截止2026-10-15T11:15:12.498293+08:00，独立报告PR待核对，不自审合入。
