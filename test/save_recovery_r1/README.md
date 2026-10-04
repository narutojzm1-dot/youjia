# 隔离 R1 持久意图实现候选

Owner CODEX-LEAD，#150；实现基于 `docs/architecture/save-recovery-contract.md`，供 CURSOR-CLOUD #239 驱动接线。模块与浏览器测试位于 test/、带 .gdignore，不进正式导出，不改 SaveStore/Main/玩家数据库。不是正式 Host 冻结，PR190/176仍为Draft。

## 已实现

`store.mjs` 导出 `envelope(frozenJSON, parent)`、`validate(record)`、`openStore(testName, hooks)`。只接受 `youjia-recovery-test-` 测试命名空间；无Web Locks在开库前拒绝。字段完整身份与固定顺序UTF-8长度前缀SHA256、128bit随机ID、正int64 generation、冻结payload及64KiB夹具上限。摘要不是认证。未知schema/字段、畸形记录保留并quarantine，不自动覆盖或新建根。

store API：
- `initialize(frozenJSON)`：显式空夹具库建根，非空拒绝；recover不会自动建根。
- `snapshot()`：真实readonly事务一致读取current/intent/archive。
- `submit(candidate, {abort_stage})`：冻结输入，Web Lock下先准备intent事务oncomplete，再current+committed intent原子写入，完整读回后返回候选。可在intent/commit真实abort。pending intent要求先recover，不重复写。
- `recover()`：可信candidate+committed清理匹配intent；可信parent+prepared原子归档rejected并清槽；不一致隔离。诊断最多32项，满了隔离而非静默删旧记录。当前仅候选小夹具，不用于玩家导入。
- `close()`：释放连接。库清理由测试驱动在所有参与页释放后处理。

hooks.barrier(name, request_id) 是异步测试屏障，在 `intent_prepared_complete` 和 `candidate_committed_before_receipt` 阶段调用，均在事务完成后、持有同一Web Lock时。未释放Promise可由驱动直接关闭页面。hooks.event 提供序号与txn/lock事件；诊断回调异常不影响存储。

## #247 接线边界

同意候选Probe/Fixture分离及两个屏障位置。CURSOR-CLOUD可先适配上述真实API、在其自身Fixture维护业务水位/授予，不能复制Host。当前模块**尚未**包装window.YoujiaRecoveryProbe，也未接Godot Web桥/PR190 Gate；事件的page_id、request_id外层映射、丢/错/迟到回执注入由Leader下一接线补齐。因此不能宣称#247场景已解阻或R2/R3通过。Fixture与Host故障注入各自Owner保持。失败/不一致不当作授予失败可立即重试；必须先恢复并读取可信水位。浏览器锁只约束合作写入者，不是生产迁移证明。

## 实际验证

`python test/save_recovery_r1/run.py --out /tmp/r1.json`，依赖Python Playwright及Chromium，可用--chrome指定。

Chromium151.0.7922.173实际 IndexedDB 同页检查35项通过，证据evidence.json：完整身份/损坏/未知字段/大小、空库不重置、显式建根防覆盖、真实intent与commit abort、prepared归档清槽、candidate恢复、重复恢复、旧parent拒绝、调用方改对象不改提交、两个真实持久屏障。没有关页/双页/进程重启、配额、v5迁移或自然玩家体验声明；R2/R3交#247真实驱动执行，R4仍待。
