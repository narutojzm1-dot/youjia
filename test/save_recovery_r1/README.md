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

## v5 原文保护导入候选（2026-10-05）

legacy_v5.mjs 提供 prepareLegacyV5({primary,backup}) 与 importLegacyV5(testName,input)。调用方显式提供每份源的 {status:"present",text:原始文本} 或 {status:"absent"}；读错误不能当作不存在。当前只认识 JSON 对象 version=5；任一源版本未知均拒绝，不静默回退旧备份。primary 损坏/缺失可选合法 backup，但两份原文仍完整封装在 youjia.legacy-v5-import/v1 中。选中原文不按字段重建、不运行 sanitize，不改变旧照片、关系、植物或未知大整数的字面文本。

冻结后在R1独占锁内仅对三键全空目标 initialize；事务完成与读回后才返回。已有正常/损坏/在途记录都拒绝覆盖；没有删除或写入旧文件的能力。导入封套是原文保全容器，不是可直接交给正式游戏的业务状态：后续仍需明确转换、统一异步Host和生产读入切换，不能以这个接口宣称正式迁移已完成。

保留R1 64KiB夹具限制，合并后的双原文容器超过限额则开目标库之前拒绝；此限制不是正式玩家容量方案。legacy_suite.html实际54检查通过（原文、backup回退、未知版本/读错误、坏目标、真实事务abort/重试、输入冻结和并发唯一胜者），原R1 139回归通过。命令：python test/save_recovery_r1/run.py --suite legacy_suite.html --out /tmp/legacy.json。证据legacy-evidence.json。

补充最新协作状态：Cloud261/264已经独立审合入，旧640组合8PASS/2BLOCKED为历史；现有2edb Host与更新夹具14项109检查已交。新增导入模块不改store.mjs/bridge.mjs/head.html，不声称同一夹具已调用导入模块；新入口有单独实际浏览器证据。正式Host和R4整体仍未冻结。

### Read-only native source capture (2026-10-05)
source_snapshot.gd reads primary and backup independently BEFORE SaveStore cleaning.
It returns explicit absent/present(base64 bytes)/read_error states. It never calls
recover, parses JSON, writes or removes source files. Missing/unreadable parent,
directory, oversized file and incomplete reads are errors, not a fresh save.
source_decode.mjs uses fatal UTF-8 decoding and canonical base64 checks before
feeding legacy_v5.mjs. BOMs are not stripped. Invalid byte sources stay untouched
and require a later explicit recovery policy; this slice does not import them.

Run source_snapshot_suite.gd with Godot 4.7.2 in an isolated minimal project,
passing the absolute source-snapshot-fixture.json output path after "--".
The 15 checks generate that fixture from real native file reads. Then run
run.py --suite legacy_suite.html --out legacy-evidence.json: 65 browser checks,
including native bytes -> decoder -> real IndexedDB -> exact raw readback.

64KiB remains a test budget. The source snapshot is NOT atomic across files.
The caller MUST stop all old writers and hold sole ownership until target durable
readback; neither this reader nor the decoder establishes that ownership.
No production SaveStore, shell or bridge entry point is switched here. Future
integration must also handle Web user:// filesystem readiness, capacity policy,
business-state conversion, acknowledgement, and restart/migration recovery.
