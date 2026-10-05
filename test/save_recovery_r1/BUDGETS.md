# #150 分层容量候选（CODEX-LEAD 协作子代理）

基于 PR251 `6e47c3acaea7ab7ecee0e09a1e3634dd8c4fb62e`，只修改隔离 Host 试验模块，不安装到生产，不冻结 Host 接口。

`fixture` 默认行为保持：单份/导入/后续写64KiB，head180000字符。显式 `candidate-v1`：单份1.5MiB、单份base64 2097152字符、head4195328字符、合并导入3.5MiB、后续写1.5MiB、current+intent+archive JSON序列化总计32MiB。合并转义可能放大，单份通过不意味着合并通过；不截断任何原文/未知字段/照片。

调用：`bridge.open(testName, 'candidate-v1')` 或 `openStore(testName, {}, CANDIDATE_BUDGET)`。候选库名必须以 `youjia-recovery-test-candidate-v1-` 开头；fixture禁止此段前缀，candidate禁止其他前缀。因此同版本不同profile不能重新解释彼此数据库。这不是生产库迁移/旧客户端排他机制；旧版本脚本不具备新前缀约束，生产仍须旧写者隔离。

根封套按导入预算验证；所有后代按正常写预算验证，大根恢复与小后代写入互不混淆。prepare及store.submit再次校验。总量预算在intent第一次写入前检查prepared与committed两种预计完整状态；超过即拒绝，原current/intent/archive保持不变。恢复转archive也检查，不删除证据/不减少32条保留上限；达到字节预算时不靠驱逐解除。预算是明确序列化字节口径，**不是**磁盘用量、RAM峰值或IndexedDB quota保证。

## 样本来源与复跑

`budget_samples/` 4份原始文件由main `ba3bb72` 的 `test/save_payload_budget/generate_bounds.gd`、Godot4.7.2真实SaveStore/PhotoMoment/SaveFiles生成，隔离 `/tmp/host-budget-state2`。自然15规则满相册两份各266132B；15×64条目合成合法相册两份各991589B（不是自然游玩）。未改内容、未投影、无真实用户存档。SHA256见 `budget-sample-hashes.txt`。生成脚本在该main上运行后输出24组，候选测试只保留上述两组；其他转义压力在浏览器构造。

```sh
python test/save_recovery_r1/run.py --suite budget_suite.html --out /tmp/budget-result.json
python test/save_recovery_r1/run.py --suite suite.html --out /tmp/r1-result.json
python test/save_recovery_r1/run.py --suite legacy_suite.html --out /tmp/legacy-result.json
python test/save_recovery_r1/run.py --suite migration_bridge_suite.html --out /tmp/migration-result.json
# 在已import的项目运行（绝对reader/samples路径）：
godot --headless --path PROJECT --script /absolute/budget_source_suite.gd -- --reader /absolute/source_snapshot.gd --samples /absolute/budget_samples
```

新浏览器用例实际IndexedDB：自然及dense导入原文完全保全、根恢复、正常写+ack；dense根大于正常预算仍可恢复；超限后代/伪装root拒绝；四层拒绝；原库快照不变；重复prepared失败恢复形成archive，到累计预算前写前拒绝且恢复仍clean。候选bridge也实际导入和prepare/submit/ack。原生读取验证默认拒绝大样本、候选原始字节完整读取、未知profile拒绝。

## 仍然阻塞生产接入

低端浏览器大载荷延迟/内存、真实配额异常、IDBFS→Host唯一写者隔离、业务durable完成通知、原库迁移与回滚、UI超限可见处理尚未验收；不得因候选通过就转正探索PR176。总预算耗尽保全状态但没有玩家导出/人工恢复入口，需要后续切片。旧PR251依赖的完整Host/Godot桥Web导出组合仍须在最终整合SHA重跑。
