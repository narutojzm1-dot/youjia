# #400 补齐仍 active 的同 tick 镜头接管与新完成格式

独立 reviewer `relationship45_qa` 指出旧 160 项中静观在 6.25 秒取样，剩余 hold 约 3.25 秒，短于鹅马预热 3.5 秒；所谓实际接管对照已经先发生自然 release。旧原始红/绿日志完整保留，`README-green.md` 已修正其覆盖声明，不把旧证据改成新结果。

新增 `live_quiet_same_tick_takeover` 正例在静观启动较早的 5.6 秒取样，normal/reduced 各执行一次。随后沿真实 Main._process / World.tick 推到预热边界前，实际读到：

- phase `-1`、wait `3.49999999999999`；quiet active=`true`，focus_seconds=`0.400000000000009`；事件数组仍只有旧静观 focus，目标 `(19.25,-52.5)`。
- 下一真实 tick：phase `0`，quiet active=`false`、focus_seconds=`0`；事件数组只追加鹅马 focus `(682.5,492.5)`，没有 release；Main 目标成为 `(14.875,46.375)`。
- 后续移动输入再发 release，目标归零，原 Main 平滑收敛后的实际偏移小于 0.01；位置与事件轨迹完整保留。两设置均通过。

这次新增测试 `.gd` blob 为 `2a4da8d81264db1e5e902e5502ef27cfd49d35da`。它在以下一对源码中逐字相同：

| 源与执行 | 实际结果 |
| --- | --- |
| 原生产字节的对照 `96612f759eb51c50eebe2f2a4eaf14c6b8ade1e4` | 23:38:16–23:38:25 UTC，exit **1**，**FAIL: 202 checks**、34 条失败；新增前置 active 断言揭示原预热已丢静观所有权 |
| 最小修正 `95b11e8255ee1c9532b6428a0b2914574dec6e97` | 23:38:59–23:39:08 UTC，exit **0**，**PASS: 202 checks []**；54 条完整状态轨迹 |

runner 起初把新增总数估为 204，原生红测完整结束后，runner 在错误的计数预期断言上停止，未进入绿测。`runner-count-correction.json` 如实记录：实际应为 202；保留红日志且没有重跑，只独立续跑绿色与 mock。没有更改测试断言凑数量，不把 runner 数量估算错误说成引擎异常。

`test/godot_gate_test.sh` 永久增加此新完成行的 **14 个轻量 fake executable 例**：最小正数、合格正数、零计数、非空失败、缺标记、其它 suite、前缀、后缀、同一行重复拼接、两个独立合法行、非零进程退出、后续 ERROR、后续 FAIL、截短标记。真实调用既有 wrapper，不是读取 regex 后镜像断言。

23:39:08–23:39:09 UTC mock 实际 exit0：`CAMERA400 COMPLETION CONTRACT PASS 14`，**总计 `GODOT GATE CONTRACT PASS 64`**（原 50 + 新 14）。旧 50 日志仍对应旧版本，不能用它声称新增格式已验证。fake 输出中 204 是正计数样本，不是原生断言数。

边界明确：既有通用 wrapper 要求至少一条严格完整的合法完成行；**两条分别合法的独立完成行仍被接受**，这例按实际语义记录 pass。相同一行重复拼接因整行不匹配而被拒。未修改通用 helper 以增加唯一性承诺；后续日志中“每 suite 一条完成”是实际观测，不能说成 wrapper 保证。

本报告仍只是受控 native/轻量 fake 证据；没有自然浏览器或用户原截图根因结论。完整组合源、daily/Web、最终审查与公开状态另记，不关闭 #400。
