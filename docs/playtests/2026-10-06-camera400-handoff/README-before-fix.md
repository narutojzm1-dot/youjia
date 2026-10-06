# #400 镜头交接组合：原代码确定性复现

这是 [Leader 协助范围 6005299861](https://github.com/narutojzm1-dot/youjia/issues/400#issuecomment-6005299861) 的原生组合诊断。#400 总体验收仍归 GAME-PRODUCER。此前只读报告 `/tmp/issue400-readonly-causal-review.md` 的“未运行”是该只读阶段状态；本文件记录随后获独占引擎窗口后的真实执行，不能混写。

生产基线 `b300da74bf157de3f152e63331096cb1eb28b3f7`；新增测试的唯一提交 `3cdd2439d4a33b7085e00f12b2c42c48c7604355`，tree `59240450110f9382503da55e62e84564626a0292`。该提交只加 `test/camera400_handoff_suite.gd`，生产代码未改。Main、World、两旧套件与只读分析的 9623 逐 blob 相同，比较在 `/tmp/issue400-readonly/b300-source-comparison.json`。

Godot `4.7.2.stable.official.ed1daf0bf`。23:28:27–23:28:51 UTC import 实际 exit 0；23:28:51–23:28:58 UTC 新 native suite **实际 exit 1**，完整完成行是 **FAIL: 160 checks**，30 条失败断言、42 条实际状态轨迹，没有 SCRIPT ERROR。外层 runner 同样以 exit 1 保留红测，不把“符合预期的失败”记为测试通过。

生产缺口已在受控真实 GDScript 路径中复现：Main._process 从 Input 动作读取移动意图，驱动真实 World.tick；原 focus/release 信号连接 Main 消费者。不是 Python 分支模型，也未对源码字符串下断言。测试为确定性设置 day、种子、位置、actor idle、天气/表达式计时，不能称普通浏览器或自然游玩。

| normal 与 reduced 都覆盖的场景 | 原代码实际结果 |
| --- | --- |
| 只有 quiet 的移动输入取消 | 所有该场景断言通过；收到 release，目标和插值偏移归零 |
| quiet 后短鹅马预热，再移动输入 | 预热清 quiet active/hold；没有鹅马 focus；取消预热未发 release，目标 `(19.25,-52.5)` 持续超过旧 hold；每模式 4 条失败 |
| quiet 后短预热，演员距离失去资格 | wait 清零但旧静观 hold 已丢；超过原 hold 仍没有 release，旧偏移保留；每模式 5 条失败 |
| 原静观 hold 应在预热内到期 | 原 hold 被预热清零，无法自然 release；后续移动仍残留；每模式 5 条失败 |
| 真正 phase 0 接管，再移动输入 | 预热保留 quiet 的一条新要求失败；实际 takeover 和后续 release 对照均通过。目标实际先变成 `(14.875,46.375)`，取消后归零 |

30 是这些情境中的具体断言数，不是 30 个新缺陷。全程固定宽屏 1280×720；本 fixture 的人物位置在障碍附近，移动输入不保证实际坐标发生位移，验证的是既有输入取消合同及真实相机消费者，不把它当走路舒适度验证。

原始退出、命令、UTC、日志 SHA 在 `process-results.json`；完整源身份在 `source.json`；逐事件轨迹与完成行在 `before-fix-result.json`；分场景摘要在 `before-fix-summary.json`；原始引擎输出为 `import.log`、`import-engine.log`、`before-fix-suite.log`。独立 data/config/cache 为 `/tmp/camera400-state`，`YOUJIA_TEST_ISOLATED_DATA` 与该 XDG data 相同，没有复用已有试玩存档。

本结果只证明 quiet 与 goose 预热交接的条件缺陷。用户 2444×1502 图的 URL/构建/操作仍未知，原图右偏成因、resize、天气、探索返回及其它相机情况都未验。不关闭 #400，不称已修复或已发布。等待 Leader 确认只在 `_tick_quiet_sky_look` 区分预热与实际接管的最小生产范围，再做同套绿测和必要回归。
