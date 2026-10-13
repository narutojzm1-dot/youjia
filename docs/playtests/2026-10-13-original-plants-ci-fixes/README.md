# 原花草候选的 CI 夹具修正（2026-10-13）

Agent-ID: CODEX-LEAD；关联 [#642](https://github.com/narutojzm1-dot/youjia/issues/642)、[PR699](https://github.com/narutojzm1-dot/youjia/pull/699)。本目录仅归档两次失败、定位与测试修订，不改变运行代码，不宣称花草候选已经合入或公开发布。

## 源码身份与当前门禁

- 普通 Web 已实玩包源：`1252a05070b57ad5d738372734d3ba9bcfdacac0`；实际三组收起/放回、重开、照片冻结证据见[普通 Web 归档](../2026-10-13-original-plants-web/README.md)。
- 第一次测试修订：远端 `4e0e600cc02ffb756c28f14dce3d2236a32307eb`，仅改 `test/ui_interaction_suite.gd`。
- 第二次测试修订：远端 `6882157ec4e56e9128672aff9bef2b123e09182d`，父为4e0e600，仅改 `test/house_cooking_suite.gd`。
- 第二次本地实际验证提交：`55156f4736a910704f22412fbb565ee12ad13c2f`，与远端6882157同树 `da359e71944fc9f3972f542d278fe55b49869e53`。本地日志属于该树；没有把它们改名为1252源码的测试结果。
- 两次测试修订均不改变1252的运行代码或资源，因此没有为纯测试变化重导出8778实玩包。
- 截至2026-10-13 10:11 UTC，[最终头完整CI38380751215](https://github.com/narutojzm1-dot/youjia/actions/runs/38380751215) 为 `in_progress`，head为6882157，尚无成功结论。本页定向回归不能代替完整CI；后续状态以该运行及PR最终审查为准。

## 第一次失败：未点击的牛被测试假定为已标记

[失败运行38374923756 / job115220798033](https://github.com/narutojzm1-dot/youjia/actions/runs/38374923756/job/115220798033) 对应1252。原始日志片段：

```text
2026-10-13T09:19:13.6808987Z [ui-interaction-tests] checks=67 failures=["Chinese HUD names the marked cow and the same pet action as the button", "HUD's marked cow is the actual action target", "English HUD names the same target and action"]
2026-10-13T09:19:13.8190336Z [daily-check] Godot/timeout exit=1; tee exit=0
2026-10-13T09:19:13.8294043Z ##[error]Process completed with exit code 1.
```

原夹具牛在(460,500)、人位于(410,520)，池边花草接近点(388,548)比牛更近。未明确点击目标时，既有最近可用动作规则正确选中花草，测试却称牛“已标记”。修订先断言最近目标确为池边花草，再通过真实viewport触摸牛的可见区域选中牛，保留中英文HUD名称、动作和实际标记位置断言。定向结果：`ui_interaction 69/0`、`explicit_target 26/0`。没有调换生产优先级以迎合夹具。

## 第二次失败：地面接管坐标实际点中花草纸面

[失败运行38376438050 / job115225886530](https://github.com/narutojzm1-dot/youjia/actions/runs/38376438050/job/115225886530) 对应4e0e600；游戏验证09:27:58–09:51:48 UTC，退出1，不是超时。失败发生在靠后的house_cooking_suite；此前UI与原花草套件已通过。原始失败片段：

```text
2026-10-13T09:51:48.5880702Z ERROR: pointer handover reaches taking stage
2026-10-13T09:51:48.5897943Z ERROR: taking has persistent stage hint
2026-10-13T09:51:48.5901838Z ERROR: indoor handover starts cooking
2026-10-13T09:51:48.5908063Z ERROR: basket handover starts cooking
2026-10-13T09:51:48.5910486Z HOUSE_COOKING checks=119 failures=11
2026-10-13T09:51:48.7038875Z [daily-check] Godot/timeout exit=1; tee exit=0
```

独立本地诊断保留原指针路径，取得：

```text
DIAG_BEFORE target={ "target": "original_plant:pond_cluster", "point": (388.0, 548.0), "label": "action.original_plants", "reach": 48.0 } player=(380.0, 520.0)
DIAG_AFTER panel=true input=false paused=true pending=
```

旧的“继续走地面”坐标(470,540)已落在新花草热点内。点击正确取消取餐路线并打开整理纸面；原夹具只清行走目标，却没有关闭实际纸面，后续三段自然无法自动做饭。不是做饭事务或玩家接管生产代码故障。

修订将普通步行坐标移到(430,510)/(470,510)，每次同时断言可行走、指针解析为空目标、未打开花草纸面。原119项断言全部保留，包括安全出门后只执行最后一个目的地。另保留(470,540)作为显式花草接管：核对实际物件目标、暂停/输入状态、食材与餐次未改变，再走纸面的关闭按钮恢复输入；没有在fixture中强制重置modal掩盖行为。

## 第二次修订的定向回归

Godot 4.7.2原生headless，各套使用独立数据目录；实际进程exit均为0、全日志无ERROR/SCRIPT ERROR/FAIL，并有下列完成行。没有重新执行整库、取消CI或盲目重跑远端。

| 套件 | 完成行 |
|---|---|
| house_cooking | HOUSE_COOKING checks=139 failures=0 |
| meal_navigation | MEAL_NAVIGATION checks=28 failures=0 |
| meal_audio_host | MEAL_AUDIO_HOST checks=71 failures=0 |
| growth_materials | GROWTH_MATERIALS checks=77 failures=0 |
| growth_budget | GROWTH_BUDGET checks=74 failures=0 |
| pond_edging_view | POND_EDGING_VIEW checks=50 failures=0 |
| pond_growth_director | POND_GROWTH_DIRECTOR checks=292 failures=0 |
| release_notes | RELEASE_NOTES checks=102 failures=0 |
| release_notes_pointer_focus | RELEASE_NOTES_POINTER_FOCUS checks=136 failures=0 |

上述9套日志和首次诊断原件保留在执行机独立临时证据目录。本页引用精简失败片段与完整Actions source链接，未把平台日志复制到另一源码身份。完整CI仍是待完成门禁，实体手机验收未由这些headless结果覆盖。

## CI耗时核对

verify-pr工作流的游戏验证步骤串行运行196个Godot套件，每套独立启动并隔离存档；完整通过后才做构建身份注入和Web导出。作为对照，成功运行[38370322586](https://github.com/narutojzm1-dot/youjia/actions/runs/38370322586)的游戏验证步骤耗时18分49秒、完整流程约20分33秒；近期成功流程约17分30秒至22分50秒。本次23分50秒后有具体断言失败，不能因耗时较长就认定死锁或超时，也不能因此取消正常在跑的最终CI。
