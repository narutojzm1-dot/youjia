# 隔离 R1 持久意图实现候选

Owner CODEX-LEAD，#150；实现基于 `docs/architecture/save-recovery-contract.md`，供 CURSOR-CLOUD #239 驱动接线。模块与浏览器测试位于 test/、带 .gdignore，不进正式导出，不改 SaveStore/Main/玩家数据库。不是正式 Host 冻结，PR190/176仍为Draft。

## 已实现

`store.mjs` 导出 `envelope(frozenJSON, parent)`、`validate(record)`、`openStore(testName, hooks)`。只接受 `youjia-recovery-test-` 测试命名空间；无Web Locks在开库前拒绝。字段完整身份与固定顺序UTF-8长度前缀SHA256、128bit随机ID、正int64 generation、冻结payload及64KiB夹具上限。摘要不是认证。未知schema/字段、畸形记录保留并quarantine，不自动覆盖或新建根。

store API：
- `initialize(frozenJSON)`：显式空夹具库建根，非空拒绝；recover不会自动建根。
- `snapshot()`：真实readonly事务一致读取current/intent/archive。
- `submit(candidate, {abort_stage})`：冻结输入，Web Lock下先准备intent事务oncomplete，再current+committed intent原子写入，完整读回后返回候选。可在intent/commit真实abort。pending intent要求先recover，不重复写。
- `acknowledge(request_id)`：消费方接受可信业务回执后调用；锁内验证 current 与 committed intent 完整身份，仅清理匹配 intent。同一 current 请求重复调用返回 already_clear，旧/错请求、prepared 或坏记录拒绝且保留原数据。清理失败不撤销已确认业务；清理未成功时不继续新写入。
- `recover()`：三个键全不存在返回 empty 且不建根；可信candidate+committed清理匹配intent；可信parent+prepared原子归档rejected并清槽；不一致隔离。诊断最多32项，满了隔离而非静默删旧记录。当前仅候选小夹具，不用于玩家导入。
- `close()`：释放连接。库清理由测试驱动在所有参与页释放后处理。

hooks.barrier(name, request_id) 是异步测试屏障，在 `intent_prepared_complete` 和 `candidate_committed_before_receipt` 阶段调用，均在事务完成后、持有同一Web Lock时。未释放Promise可由驱动直接关闭页面。hooks.event 提供序号与txn/lock事件；诊断回调异常不影响存储。

## #247 接线边界

本目录现在可作为 HOST_DIR：head.html 同步安装异步回调门面，bridge.mjs 提供 YoujiaRecoveryHostBridge 的 open/initialize/prepare/submit/resolve/acknowledge 和 YoujiaRecoveryProbe。Cloud 的 Godot Fixture 使用真实 Gate + JavaScriptBridge；不复制其业务规则。回执 token 为 commit_id，write_id 保持十进制字符串；resolve 必须等原写终止且取得可信 current，不凭异常推断失败。准备/确认期间拒绝重叠写。

Probe 包含真实事务后关页屏障、page/request 事件身份，以及真实 abort、丢/错/重复/迟到回执注入。注入只改变测试回执传递，不伪造持久成功。无锁在开库前拒绝。仅隔离测试命名空间，不进生产导出。

联调 #247 6401500381e73f4d695961b6baaa74adf9bf2989 + Gate f096a4a927c164c4bf70acc403a826a2074d2362：Godot4.7.2真实导出，现有驱动8场景PASS、2场景BLOCKED。R2两关页恢复与6个故障场景已实际执行；双页等待锁与无锁拒绝被驱动一律等待Fixture.ready挡住，已交Cloud修测试等待条件（#239 5982817250）。不能写完整R2/R3矩阵通过。补充直接浏览器检查不替代Owner正式矩阵。正式Host/v5迁移仍未冻结。

使用 Cloud 原构建链：`BUILD_FIXTURE=1 GODOT=... GODOT_WEB_TEMPLATE=... HOST_DIR=<本目录> HOST_SHA=<精确SHA> bash tools/verify_save_recovery_web.sh`。head.html 随该构建注入，模块文件拷入站点根；不要注入公开游戏。

## 实际验证

`python test/save_recovery_r1/run.py --out /tmp/r1.json`，依赖Python Playwright及Chromium，可用--chrome指定。

Chromium151.0.7922.173实际 IndexedDB 同页检查139项通过，证据evidence.json：完整身份/损坏/未知字段/大小、空库不重置、显式建根防覆盖、真实intent与commit abort、prepared归档清槽、candidate恢复、重复恢复、旧parent拒绝、调用方改对象不改提交、两个真实持久屏障。没有关页/双页/进程重启、配额、v5迁移或自然玩家体验声明；R2/R3交#247真实驱动执行，R4仍待。

独立首审发现falsy记录被当成空键的问题，已改为同事务get+count保留present标记，所有非法intent/current/archive均隔离且原值保留；补null/undefined/false/0/空串及坏archive条目真实反例。snapshot返回present，消费方不得用truthiness判断键不存在。139项为本次同页证据，增加三次连续保存/确认清理、同请求幂等、错/旧请求与 prepared 意图拒绝且保留、empty 不建根。替代初稿35项及上一轮112项；待新最终 SHA 独立复审。
