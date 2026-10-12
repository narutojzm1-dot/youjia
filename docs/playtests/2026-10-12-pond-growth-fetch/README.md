# #700 池岸施工：实体背篓取材与搬运候选

Owner CODEX-LEAD，接续 PR766 的 7a16a28de0232360b8b47439d69bade65bae516d。最终提交见原 PR 回执。普通场景仍未自动启动，不是已发布成长闭环。

导演先沿已有路径走到 PhysicalBasket.APPROACH，在背篓旁重新核对材料计划，做短暂拿取动作，再将既有圆石贴图挂在手部沿路径搬往施工点。到达后才开始生产工序。取材、搬运不受疲劳减速；生产继续按0.5速率。拿取0.8秒是表现时长，不是动作点或材料成本的新规则。

携带图像仅表示本次计划，不新增手持库存，也不提前扣物。最终既有事务统一确认材料、AP、世界石圈及经验；中断清除表现，无物品落地或第二份返还。背篓库存/摆放水位变化时旧计划不能取材，完成前变化仍由原事务拒绝。菜单、点击或移动可取消 fetching/taking/walking/working；saving 保留原身份。

## 本机验证

Godot 4.7.2，独立 APPDATA 与 YOUJIA_TEST_ISOLATED_DATA；入口 `test/pond_growth_director_suite.gd`，不是零退出即通过。

- `final-1.log`、`final-2.log`：各205检查/0失败；包含真实Main三种菜单×五个阶段、物品/AP守恒、库存变化、疲劳生产和确认显示。
- `gpu-final.log`：208检查/0失败（含三张截图保存），NVIDIA Compatibility 实际渲染；`gpu-final-error.log` 无脚本错误。
- `growth_budget.log` 74、`pond_edging_view.log` 50、`house_sleep.log` 154，全部通过。
- `export.log`：Web release 导出完成。这不等于普通浏览器/手机验收。
- `transport.jpg`、`working.jpg`、`confirmed.jpg` 是运行中截图，夹具库存/成本仅供验证，不成为正式产品数值。

首次 `director-first.log` 因上轮恢复的导入索引与本机缓存不同而加载失败，重新导入后才能执行断言。`director.log` 与 `director-final.log` 保留菜单矩阵间歇失败（2/14条）；独立用例补充重置世界日期、清除场景反馈和寻路，并保留失败上下文诊断，随后两次205项通过。未把间歇失败归因为已证实的生产缺陷；后续CI若复发须继续调查，不能删失败记录当验收通过。

## 未完成

尚未与 PR738 的三餐和自主调度整合，普通场景没有 begin 调用。正式施工姿态仍待制作，当前沿用拿取弯腰候选；手机/普通Web连续体验、跨日余点及未确认数值未解除。原生/GPU夹具仅证明候选流程，不冒充成品体验或公开版本。

## 与最新主线集成

合并 main 25aa96a26b8a18900c2400d7f9edd2c195151437，保留 Cloud #767 原作者祖先。唯一冲突是 decisions.md 末尾双边追加，两段都保留；快捷栏代码按主线合入。集成后导演205/快捷栏焦点1690检查均0失败，Web重新导出完成（merge-*.log）。施工运行代码未改变；当前PR仍保持Draft，合并主线不等于发布。
