# 2026-10-06 10:03 原生自动回归补充（供用户查看）

GAME-QA独立执行，未委派、未开发。**5项真实Godot专项通过；完整游戏发布关卡仍覆盖不足。** 这是09:49普通游玩报告之后的独立自动验证阶段，不把此前“自动测试0”改造成历史已执行。

## 实际来源与环境

本地source已恢复检出，detached HEAD `267b0cb3df5842170877bf55e438917ad4253ce8`；最初未检出HEAD无效，安全fetch后Git HTTPS首次传输中断，按单命令TLS后端/HTTP1.1重试成功，没有关闭证书验证。排除docs/art的稀疏检出节省测试取源，但探索套件依赖art内JSON，后续仅补回该原始输入。未直接推main或改变游戏代码。

被测为原生工程main 267b0cb3，**不是浏览器C game-d21030d的同一SHA**，不将原生结果冒公开PCK重跑。引擎Godot4.7.2.stable.official.ed1daf0bf，Windows headless、Git Bash执行仓库tools/lib/verified_godot.sh。最终开始/结束UTC见results.json（北京时间10:06:27—10:07:26）；首次import在10:03:50开始，各尝试单独留原件。目录1005/1008为运行资产名，实际时间以JSON为准。

profile-probe真实引擎输出确认user data在本地QA目录；Windows APPDATA与XDG_DATA_HOME及YOUJIA_TEST_ISOLATED_DATA为一致的正斜杠绝对路径。最终每一套件使用独立case目录，不访问浏览器IndexedDB，不重置用户线上档。

## 最终真实运行

|入口|精确完成结果|门禁结果|
|---|---|---|
|import|资源导入，进程退出0、无ERROR|通过，不计套件断言|
|exploration_slice_suite.gd|EXPLORATION SLICE PASS 278/278 failures=[]|通过|
|fish_carry_consistency_suite.gd|[fish-carry] 94 checks []|通过|
|audio_button_input_suite.gd|AUDIO_BUTTON_INPUT checks=648 failures=0|通过|
|camera400_handoff_suite.gd|[camera400-handoff] PASS: 202 checks []|通过|
|camera400_backdrop_suite.gd|[camera400-backdrop] PASS: 44734 checks []|通过|

5套件、45,956断言检查；数字包含参数/布局枚举，绝不是45,956次用户游玩。门禁读取仓库唯一登记的整行完成正则、要求正计数/零失败、进程退出与完整日志无ERROR，不以一个PASS字样放行。导入单列，未执行完整daily全部套件。

## 未通过的先前尝试与环境修正

1. 第一尝试原探索日志含JSON解析失败及Nil→Dictionary脚本错误，虽然打印268/268 PASS，包装器退出1拒绝。原因是稀疏检出省略`art/concepts/producer_world_20261005/near_path_anchors.candidate.json`；只补回原JSON，没有改suite。属于取源不全，未登记产品BUG。缺失的10个检查不能补作第一轮通过。
2. 第二尝试探索278通过，但携鱼套件因YOUJIA_TEST_ISOLATED_DATA与XDG_DATA_HOME不一致安全拒绝（engine退出2，wrapper1），没有执行携鱼断言。此前QA目录已隔离，但字符串约定不符；只修QA驱动环境并逐套件分目录。保留拒绝日志，不称是携鱼功能失败。
3. 最终重新执行上述适用5套件，均按原门禁通过；未改任何游戏或测试断言代码。导入造成5个已有.import参数变化，已保存原差异并恢复这5个明确由本轮引擎生成的文件，最终tracked diff为空；139个生成的未跟踪UID文件保留、不提交，不覆盖其他人文件。

## 适用边界与BUG

这些是原生夹具/确定性测试，不是浏览器普通游玩。探索种子与直接方法、携鱼时间缩短/固定随机及场景驱动、音频模拟输入/状态、相机属性/参数枚举都按各套件原注释解释，不冒自然事件、Web事务失败或真实听验。声音可听性、真实携鱼界面成功流程、全部P1、移动真机、多DPR、完整存档故障和长期稳定性仍未补齐。

004已有独立普通Web圆石可读样本通过，见[09:49报告](../2026-10-06-0949-game-qa/README.md)。音频648项只支持控件确定性回归，不关闭QA-AUDIO-20261004-001的听验缺口；鱼94项不替代原#231普通线上体验。既有BUG不重复编号/认领开发Owner。整体仍不足以判定全量发布通过。

## 原始日志与驱动

evidence中first-import-failure、marker-refusal、isolated-final三目录包含原始引擎/包装器日志、results和profile输出。最终QA驱动脚本及各调用shell保留，仅用于测试环境，不是生产代码；路径为本机绝对路径，复用需按真实工作区调整，不能直接认定可移植。生成参数差异只作取证，不是修复补丁。

