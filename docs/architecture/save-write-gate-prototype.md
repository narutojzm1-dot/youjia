# H1a 写入协调器原型

CODEX-LEAD / #150；基线a5cc54a。候选原型，独立审核后仍保留Draft，不接SaveStore、不迁移玩家档、不合入正式探索。不是完整H1。

`save_write_gate.gd`以防御性深复制隔离working、confirmed与在途快照；一次只允许一笔写入。未知结果持有原身份，普通完成回调不能解除，只有可信平台适配器调用resolve_verified。返回值或getter的外部修改不影响内部；成功只推进confirmed与其revision，不覆盖更晚的working。调用者在dirty时重新begin_write，未内建自动队列或重试。

本片只负责写入生命周期，不含提案去重、授予、导航、校验封套、平台持久化核验或重启恢复。write_id为进程内身份；跨上下文稳定身份、序号溢出策略、完整宿主事务及可信适配器仍属H1后续/H2/H3门禁。resolve_verified不是安全证明API，调用方必须证明候选精确匹配，或可信父代匹配且旧操作已终止；不能用计时、水位或内存文件读回调用它。不得接入正式存档。

验证：Godot4.7.2最小隔离项目保留原始scripts/persistence及test相对路径，复制这两个文件运行`--headless --script test/save_write_gate_suite.gd`，退出0，SAVE WRITE GATE PASS 25，无错误。覆盖在途新照片/关系、失败与未知、旧ID/重复通知、快照隔离。首次直接在未导入游戏工作树执行出现类注册和字体导入错误，即使打印PASS也不计通过；隔离重跑仅证明本模块。

未跑完整daily、Web导出或浏览器，不宣称玩家版本验证或发布。后续接入前补严格标准回归、真实宿主/平台矩阵、最终SHA独立审查及必要Web证据。保留CURSOR-CLOUD核心与假宿主Owner，不把本原型覆盖其PR176。


后续测试固化：将CODEX-LEAD-ASSISTANT的8项边界复测转为正式断言，累计33项。使用`GODOT=/path/to/godot bash tools/verify_save_write_gate.sh`复制候选源码到最小项目、调用仓库严格wrapper，既检查退出码/错误日志，也必须匹配完整PASS33完成标记；保留临时项目和日志供诊断。本轮实际运行退出0，无错误。未改变原型源码或提升平台证明范围；新SHA须重新独立审查。


## 候选回执接口修订（未冻结）

回应工程督导5973958459：begin_write现在要求非空且不同的candidate_token/parent_token，随快照冻结；resolve_verified改收结构化回执，核对write_id及候选/父代token。observed_token精确匹配候选才确认成功；精确匹配父代且old_write_terminated为true布尔值才拒绝并释放；其余保留unknown。42项严格隔离测试通过，包括同ID错摘要、父代无终止、旧flight、重启复用ID、空/相同身份。

token是可信适配器提供的**不透明封套身份**，不是Gate产生的哈希证明。适配器必须绑定确定字节、generation/parent和提交身份，保证不同提交/上下文不能误复用；具体格式仍待H2/H3冻结。本类只验证回执与冻结身份一致，无法验证调用者关于持久化读取或终止的真实性。不得以人工设置token/terminated的模型测试声称平台P1已解除。当前只完成结构化身份比较，真实证明仍阻挡正式API/合入。

上述早期说明中的二参resolve_verified及PASS25/33为历史，当前命令不变、预期PASS42；没有调用正式SaveStore或改变玩家档。


## 2026-10-04 回执类型防御

在任何字符串比较前要求三种token为String，畸形或缺失字段干净拒绝。严格隔离suite现为168项：数组/字典/null/bool/int/float/空串及缺字段均拒绝，unknown、flight、working、confirmed保持，后续写继续阻塞，原合法回执仍能收尾且保留较新working。此为PR190正式API晋级阻断修复，不解决H2/H3/H4，不接入玩家存档；Draft保留。


## JSON边界候选（2026-10-04）

`resolve_verified_json`在Gate内提供可测试的候选解码入口，schema固定`youjia.save-receipt/v1`，write_id为规范正十进制字符串，范围1..9223372036854775807；JSON数字不接受，以免JavaScript浮点精度改变写入身份。超长值必须在to_int之前拒绝，不能把引擎报错后的返回值当成功防御。三token与旧写终止语义继续走现有结构化回执验证。

严格suite现199项，新增坏JSON、顶层类型、schema类型/版本、数值ID/前导零/符号/超界ID、token漂移与重复合法回执。首轮捕获超长数字to_int日志ERROR，已加转换前长度/上界检查；只有修复后严格runner exit0才算通过。此接口是候选wire格式，不是可信来源认证或平台终态证明；不接生产JS/SaveStore，unknown与迟到/跨进程路径仍待H2/H3/H4。
