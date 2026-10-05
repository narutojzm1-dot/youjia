# 探索已提交会话的 cleanup 提交契约（#150）

Agent-ID: CODEX-LEAD（内部实施 host_budget_impl），原单认领5995152650。本切片只提供共享存储接口；没有修改或启用 Cloud Host 的 cleanup 重试，没有修 Main 的 cleanup 提示，不宣称公开同页恢复完成。

## 接口和责任

`SaveStore.request_exploration_cleanup(expected_record, expected_watermark, target_idle, cleanup_id) -> String`

- `expected_record` 必须是 `get_exploration_record()` 的完整原值副本，不能由会话重建、删字段、JSON往返或规范化后冒充原值；其中JSON读回的数值类型也保留。
- `expected_watermark` 是同一次读取的可信已提交水位；只接受范围内整数（含JSON解析的精确整数浮点），拒绝布尔/字符串/未知值。
- `target_idle` 是本次已提交formal会话依现行纯恢复契约合法close后的空闲记录，必须恰为version、next_trip_serial、session三字段，session为null、序号精确匹配。不是任意null。
- `cleanup_id` 是调用者持有的本次领域身份，非空、最长128字符。调用者负责维护 `returned op_id → cleanup_id`，不保存到磁盘；本接口不建立常驻历史，也不宣称已接好跨op UI关联。
- 返回非空只表示队列受理。终态仍走现有`commit_confirmed(op_id, "exploration_cleanup")`、`commit_rejected(op_id, kind, code)`、unknown/ack信号；确认与ack不能混为同一步。初始化/队列拒绝受理仍返回空。

## 校验与写前拒绝

受理时冻结全部参数。预检只接受现行v1、结构合法、formal、非隔离的已提交会话；拒绝未来版本、未知顶层、会话或结构子项扩展字段（started_clock、proposal、每项items、failure均逐层白名单）、fixture、未提交水位、错误序号、任意不匹配target。复用`ExplorationContract.validate_session_structure`及纯`ExplorationSession.restore`，仅`HOST_CLOSE`可成为目标，不复制另一套探索状态机。`proposal`/`failure`须显式存在（可为null），避免旧纯validator允许缺键而restore直接索引；受支持的legacy `taken`省略继续按纯恢复契约处理。

真正到FIFO队首才比较最新confirmed的完整`exploration`与冻结原记录，以及已提交水位。任何差异都明确拒绝，不调用prepare/submit，不以原current作为no-op成功。匹配时只更新current.exploration，院子、照片、带回物等所有其他字段采用队首最新值，不使用旧全档覆盖。即使新trip先排队但未落盘，轮到旧cleanup时也会看到新记录并拒绝。

Coordinator仅增加内存`IntentRejection`类型，pump在构造payload之前处理。可用代码固定为：

- `EXPLORATION_CLEANUP_INVALID_ARGUMENT`：参数或原记录不在本接口可清理范围。
- `EXPLORATION_CLEANUP_PRECONDITION_CHANGED`：队首原记录/水位已变化，包括已经清理；不伪造confirmed。

非法typed拒绝码降为既有`INVALID_LOCAL_INTENT`；普通非version5 builder仍为`INVALID_LOCAL_CANDIDATE`。不修改Host wire、数据库、envelope或磁盘schema。

## 后续 Cloud 接入条件（尚未实施）

Cloud应登记cleanup op和其领域身份，保留unknown/resolve/ack原语义。明确reject后，只有当前会话仍对应同一cleanup才可重交冻结请求；新trip开始后不得盲目重放。实际提交仍必须经过本接口队首CAS。Main解除旧提示还需绑定同一cleanup及精确失败revision、耐久确认与ack/idle，不得任意null或任意新成功清除。旧记录已被更新时保守保留问题，由领域Owner决定后续动作，不能靠本接口声称已经恢复。

## 验证边界

见[专项与门禁](../playtests/2026-10-05-exploration-cleanup-contract/README.md)。真实Native文件证据覆盖成功清理与失败原字节不变；受控backend证明失配不prepare、FIFO/未知/ack顺序。这里不是已接入的真实Web cleanup恢复体验。

## 2026-10-06 领域调用者的无效参数终态

PR427接入后曾在INVALID_ARGUMENT回退普通record写，绕过未知扩展保护。Leader保底修订仅令该码与PRECONDITION_CHANGED都终止本次自动重交，保留权威记录与失败；不得把INVALID解释为安全直写授权。支持范围内的普通写故障有限重试、unknown等待与Main精确失败快照不变。此项不会让不支持的记录自动恢复，也不新增重置/删除入口；后续需要能理解该记录的恢复方案。
