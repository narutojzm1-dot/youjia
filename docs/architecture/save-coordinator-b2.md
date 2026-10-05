# REQ-020 / #149 / #150：B2 生产存档协调器

Agent-ID：CODEX-LEAD（内部实现切片）。本切片仅提供协调器和确定性协议回归，不接管 SaveStore/Main、原生文件适配、Web Host 或 Cloud；端到端业务与真实持久化由集成门禁另验。

## 消费者接口

`initialize(backend, trusted_snapshot, trusted_token, expected_namespace)` 接收经宿主 open/initialize 验证及业务 codec 投影的 version 5 完整快照。namespace 默认为 `youjia-save-host-v1`，原生必须显式传 `youjia-native-file-v1`。初始化不是磁盘读取，也不将任意调用者数据变成可信数据。对象不得在未知写入尚未解除时替换。

`enqueue(Callable) -> String` 返回非空 op_id 仅代表接受；回调在 FIFO 队首获得最新 confirmed 深拷贝，并返回包含所有 owner 字段的完整候选。调用者必须传语义修改意图，不能捕获旧完整快照再整体替换。空 ID 表示当前未接受。首次 pump 延后，确保同步原生适配器也不会在 enqueue 返回前通知该操作结果。

`is_idle()` 仅在 ready 且当前操作和整个队列均空时为 true。标题切换/再入院应以此等待清空，不能把两项 queued 操作间的 ready 当作清空；unknown/blocked 返回失败供上层保留现场。

`confirmed(op_id, snapshot, token)` 才更新业务可见状态；`get_confirmed()` / `get_confirmed_snapshot()` 返回深拷贝。未确认照片预览由 Main 独立管理。`rejected(op_id, reason)` 仅用于非法本地意图/候选，或 resolve 已证明旧事务终止且可信 parent 保持不变。I/O 错误、超时、畸形回执均不等于 rejected。

`unknown(op_id, reason)` 后不接受新写入，已有队列保留；`retry_resolve()` 仅对具有完整 prepared 身份的未知操作重查。prepare 无可信身份时保持 blocked，不能凭空恢复或重发。确认后的 acknowledge 失败发 `ack_failed`，保持已确认快照且阻止后续 prepare；`retry_ack()`（或此状态的 retry_resolve）只重试清理，不再写业务。

## 统一 backend 协议

- `request(method: String, args: Dictionary, expected: Dictionary = {}) -> String` 返回本次调用 ID。
- `completed(request_id: String, method: String, reply: Dictionary)`；reply 为 `{status, code, wire}`。同步提前完成有缓冲处理；过期、重复、ID/method 不符回执发 ignored_receipt，不推进状态。
- prepare 参数 `{payload, parent_token, write_id}`。payload 是候选 JSON 文本。
- submit / resolve / acknowledge 参数 `{request_id, write_id}`，这里 request_id 来自 prepared；expected 是完整 prepared 字典。
- prepared schema `youjia.save-prepared/v1`：namespace、store_id、write_id、request_id、candidate_token、parent_token、payload_sha256、generation 共八个非空字符串，加 schema 共九字段。generation 是规范正十进制 int64 字符串，确认后下一代严格加一；首次代次及初始 token 的完整性由受信 backend 核验。store_id 在本协调器生命期固定。
- receipt schema `youjia.save-receipt/v2`：完整八项身份必须相同，加 observed_token、outcome、transaction_state、readback_verified、old_write_terminated，共十四字段。后两个必须是布尔 true。confirmed 必须 observed=candidate 且 complete；rejected 仅 resolve 可回，必须 observed=parent 且 terminated。
- ack schema `youjia.save-ack/v1`：namespace、request_id、write_id、status，共五字段；status 为 cleared/already_clear。

Web 候选 token 必须不同于 parent。原生 token 是真实文件字节 SHA256，字节不变的合法保存允许相同 token；请求、写入、代次身份及可信回读/事务终止条件仍必须满足。协调器不将 mock 回执当真实文件耐久性证据。

## 验证与边界

Godot 4.7.2 独立最小项目运行同一源码与 `test/save_coordinator_suite.gd`：80 checks、0 failures、无解析/运行错误。覆盖 FIFO 跨 owner 保留、接受与确认时序、同步回执、深拷贝隔离、超时未知、恢复可信 parent/candidate、终止证明、十四字段逐项不匹配、布尔伪装、重复/晚到回执、ack 失败后不倒退、非法候选、prepare 失败、原生 namespace 和相同 token no-op。

本切片未修改运行时入口，故没有冒称真实浏览器/原生业务已走协调器。集成仍须验证 Host 严格解析、真实 IDB/文件失败和恢复、业务 UI 未确认状态，以及现有存档迁移。队列仅存在内存；启动后的未决宿主事务须先由宿主恢复，再以可信快照初始化协调器。
