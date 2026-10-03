# H1a 写入协调器原型

CODEX-LEAD / #150；基线a5cc54a。候选原型，独立审核后仍保留Draft，不接SaveStore、不迁移玩家档、不合入正式探索。不是完整H1。

`save_write_gate.gd`以防御性深复制隔离working、confirmed与在途快照；一次只允许一笔写入。未知结果持有原身份，普通完成回调不能解除，只有可信平台适配器调用resolve_verified。返回值或getter的外部修改不影响内部；成功只推进confirmed与其revision，不覆盖更晚的working。调用者在dirty时重新begin_write，未内建自动队列或重试。

本片只负责写入生命周期，不含提案去重、授予、导航、校验封套、平台持久化核验或重启恢复。write_id为进程内身份；跨上下文稳定身份、序号溢出策略、完整宿主事务及可信适配器仍属H1后续/H2/H3门禁。resolve_verified不是安全证明API，调用方必须证明候选精确匹配，或可信父代匹配且旧操作已终止；不能用计时、水位或内存文件读回调用它。不得接入正式存档。

验证：Godot4.7.2最小隔离项目保留原始scripts/persistence及test相对路径，复制这两个文件运行`--headless --script test/save_write_gate_suite.gd`，退出0，SAVE WRITE GATE PASS 25，无错误。覆盖在途新照片/关系、失败与未知、旧ID/重复通知、快照隔离。首次直接在未导入游戏工作树执行出现类注册和字体导入错误，即使打印PASS也不计通过；隔离重跑仅证明本模块。

未跑完整daily、Web导出或浏览器，不宣称玩家版本验证或发布。后续接入前补严格标准回归、真实宿主/平台矩阵、最终SHA独立审查及必要Web证据。保留CURSOR-CLOUD核心与假宿主Owner，不把本原型覆盖其PR176。


后续测试固化：将CODEX-LEAD-ASSISTANT的8项边界复测转为正式断言，累计33项。使用`GODOT=/path/to/godot bash tools/verify_save_write_gate.sh`复制候选源码到最小项目、调用仓库严格wrapper，既检查退出码/错误日志，也必须匹配完整PASS33完成标记；保留临时项目和日志供诊断。本轮实际运行退出0，无错误。未改变原型源码或提升平台证明范围；新SHA须重新独立审查。
