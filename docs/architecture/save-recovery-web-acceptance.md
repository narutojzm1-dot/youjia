# #150 R2/R3 真实浏览器验收驱动（#239）

Owner：CURSOR-CLOUD（仅测试侧驱动）。父单 #150，工单 [#239](https://github.com/narutojzm1-dot/youjia/issues/239)；协议候选见 [重载恢复与持久意图](save-recovery-contract.md)。R1 封套/持久意图/写入协调器/恢复入口与 R4 迁移仍归 CODEX-LEAD。本驱动不复制或重写存储实现，不接正式 SaveStore/Main，不建第二套 Host。

## 当前状态

驱动骨架可运行。R1 候选尚未接线，因此 R2/R3 各场景全部报 `BLOCKED`。**这不是 R2/R3 通过，也不是恢复已实现。**

## 运行

```sh
bash tools/verify_save_recovery_web.sh                     # 只跑驱动自检，R2/R3 报 BLOCKED，退出码 2
CANDIDATE_DIR=/path/to/r1-test-export CANDIDATE_SHA=<完整SHA> \
  bash tools/verify_save_recovery_web.sh                   # 对 R1 候选的隔离测试导出跑完整矩阵
```

- 依赖：Python Playwright，以及 Chromium（`/usr/bin/chromium`）或 Chrome（`/usr/bin/google-chrome`，可用 `CHROME` 指定）。
- 退出码：0 表示全部 PASS；1 表示有 FAIL；2 表示没有 FAIL 但有 BLOCKED。
- 证据写入 `$OUT/result.json`，字段包括驱动 SHA、候选 SHA、候选 PCK SHA256、浏览器版本、Playwright 版本，以及每个场景的状态、检查数、失败项、测试库名、耗时和证据（数据库前后快照、屏障停点、恢复结果、事件序列）。
- `test/save_recovery_web/` 带 `.gdignore`；正式导出已排除 `test/*` 与 `tools/*`。

浏览器 context 为 Playwright 持久化 context，profile 放在临时 user-data-dir 里，整次运行共用一个。“关页”指 `page.close()` 后在同一 context、同一 origin 开新页，不是 reload，不清库，也不换 context。运行结束后删除 profile 和临时站点；每个场景使用独立测试库 `youjia-recovery-test-<uuid>`，由候选的 `cleanup()` 删除。

## 驱动自检（不是 R2/R3）

自检用 `test/save_recovery_web/selfcheck/index.html` 直接调用浏览器 API，只证明驱动的观测手段可靠，共 10 项：

1. 同一 context 下，写入的记录在关页后由新页读回；
2. A 页持有独占 Web Lock 时，B 页 `ifAvailable` 取不到锁；
3. A 页关闭后，B 页取得锁，证明关页会真实释放锁；
4. 默认有 Web Locks，注入 init script 后 `navigator.locks` 确实消失；
5. 测试库删除后读回为空；
6. 非 `youjia-recovery-test-` 前缀的库名被拒绝。

## 测试侧接口候选 v1（待 CODEX-LEAD / ENGINEERING-SUPERVISOR 核对）

接口只存在于隔离测试导出，由 head_include 注入，正式 shell 不含。原始提议见 [#239 接收评论](https://github.com/narutojzm1-dot/youjia/issues/239#issuecomment-5981415664)。下列方法可以同步返回，也可以返回 Promise，驱动统一 `await`。

**`window.YoujiaRecoveryProbe`**（R1 Host 侧提供）

| 成员 | 约定 |
| --- | --- |
| `schema` | `"youjia.recovery-probe/v1"` |
| 存储命名 | 只取 URL 参数 `recovery_store`，必须以 `youjia-recovery-test-` 开头，否则拒绝启动 |
| `capabilities()` | `{web_locks, indexeddb, barriers: [...], injections: [...]}`；驱动按 `barriers` / `injections` 判断是否 BLOCKED |
| `arm(name)` | 屏障：`intent_prepared_complete`（第一笔 readwrite oncomplete 后、第二笔开始前）、`candidate_committed_before_receipt`（第二笔 oncomplete 并读回校验后、回执 Gate/业务前）。到点停住，不继续也不超时 |
| `paused` | 停住时为 `{name, request_id, page_id}` |
| `inject(opts)` | `{abort_stage: "intent"|"commit"}` 在真实事务里调 `transaction.abort()`；`{drop_receipt}`、`{receipt_identity: "wrong"}`、`{duplicate_receipt}`、`{delay_receipt_ms}` 作用于真实终态之后的回执。`injections` 名称依次为 `abort_intent`、`abort_commit`、`drop_receipt`、`wrong_receipt_identity`、`duplicate_receipt`、`delay_receipt` |
| `events()` | 有序列表，每条含 `type`、`page_id`、单调序号；`type` 至少包括 `lock_requested`、`lock_acquired`、`lock_released`、`txn_complete`、`txn_abort`（含 stage、request_id）、`receipt_delivered`、`receipt_dropped`、`recovery_result` |
| `recovery()` | 恢复完成前为假值；之后为 R1 `recover()` 的结果 `{verdict, current, intent, archive}`，另加 `no_web_locks`（`openStore` 拒绝时）。`verdict` 取 `restored_candidate`、`restored_parent_intent_rejected`、`clean`、`quarantined`、`no_web_locks` 之一 |
| `snapshot()` | R1 `snapshot()`：readonly 事务读出 `{current, intent, archive}`，`current` 为完整封套，`archive` 条目为完整意图并带 `state: "rejected"`；不持锁、不修改。驱动从 `current.payload_bytes` 解析业务水位与授予列表 |
| `cleanup()` | 只删除本测试库 |

**`window.YoujiaRecoveryFixture`**（测试场景侧，由 CURSOR-CLOUD 在 R1 公开 API 上编写）

| 成员 | 约定 |
| --- | --- |
| `ready` | 场景就绪 |
| `grant(serial)` | 发起一次业务授予写入；`serial ≤ watermark` 时直接确认、不再授予，与探索契约的 `last_committed_trip_serial` 语义一致 |
| `business()` | `{watermark, grants: [...], pending, confirmed_serials: [...]}`；`pending` 表示有写入尚未得到可信回执 |

R1 若没有支撑 Fixture 的公开入口，会在 PR 中列出缺口，不另造 Host。

## R1 store.mjs 消费映射（对照 PR #251 `ad6cfc0`）

| Fixture 动作 | 使用的 R1 API | 说明 |
| --- | --- | --- |
| 页面启动 | `openStore(recovery_store, hooks)` → `snapshot()`：三项都为空时 `initialize(根 payload)`，否则 `recover()` | `recover()` 遇到空库会判为 `quarantined`，因此空库必须先显式建根；`openStore` 抛出 `no_web_locks` 时，Probe 报 `no_web_locks`，Fixture 不写入 |
| `grant(serial)` | 读取可信 `current`，从 payload 取出水位：`serial ≤ watermark` 时直接确认，不写入；否则 `envelope(新 payload, current)` → `submit(candidate)` | 新 payload 为 `{watermark: serial, grants: [..., serial]}`。每次 `envelope` 生成新的 `request_id`，重试天然换身份 |
| 确认 | `submit` 返回的记录与提交的 candidate 完全一致后，解析 payload，更新 `confirmed_serials`，清除 `pending` | 只认返回的可信记录，不认调用方本地对象 |
| 失败 | `submit` 抛出（真实 abort、`stale parent`、`recovery required`、读回不一致）时保持 `pending`，先 `recover()` 读出可信水位，再决定是否以新的 envelope 重试 | 不把失败当作授予失败立即重试 |
| 屏障 | `hooks.barrier(name, request_id)` 由 Probe `arm(name)` 返回永不完成的 Promise | 两处屏障都在事务完成后、持有同一把 Web Lock 时触发，与驱动约定一致 |

**发现的接口差异（请 CODEX-LEAD 处理）**

1. **确认后的意图清理没有入口（会阻塞第二次写入）。** `submit` 成功后，状态为 committed 的意图留在槽里，只有 `recover()` 才清理；下一次 `submit` 遇到槽里有意图会抛 `recovery required`。因此同一页面上的连续两次授予（R2-b 重复授予、R3-c 重复/迟到回执，以及任何正常游玩）必须每次都插一次 `recover()`，而这会把正常确认也报成 `restored_candidate`。协议第 6 步要求“本地已记录确认后，可在独立事务清理匹配 request_id 的 intent”。建议增加 `acknowledge(request_id)`：在锁内比较 current 与 committed intent 的完整身份后清槽，失败也不影响已确认的提交。它必须在 `candidate_committed_before_receipt` 屏障与业务记录之后由消费方调用，R2-b 的关页窗口才保持有效。
2. **空库的判定。** `recover()` 对全空库返回 `quarantined`，和真正的损坏无法区分。建议返回独立的 `empty`（不建根），或在文档中明确由调用方先 `snapshot()` 再决定是否建根。驱动目前按后者处理。
3. **Probe 包装尚缺**（Leader 已列入下一接线）：`page_id`、事件里的 `request_id`、丢/错/重复/迟到回执注入，以及 `capabilities()` 的 `barriers`/`injections` 列表。在这些就绪前，驱动维持 BLOCKED。
4. **Fixture 放在哪一层。** R2 要求“实际 Godot Web 桥接”。请确认：Fixture 是做成 Godot 场景，经 Gate 和 JavaScriptBridge 调用 store；还是先做 JS 层，等 Gate 接线后再换成 Godot。无论哪种，驱动接口都不变。

## 场景矩阵

| 场景 | 操作 | 通过条件 |
| --- | --- | --- |
| R2-a | 停在 `intent_prepared_complete` 时关页，开新页 | `restored_parent_intent_rejected`；current 仍为 parent；活动意图已清除；该 request_id 以 rejected 状态归档；水位不变；重试同一 serial 只授予一次，且使用新 request_id |
| R2-b | 停在 `candidate_committed_before_receipt` 时关页，开新页 | `restored_candidate`；current 的 request_id 等于停点 request_id；水位包含该 serial，只授予一次；再次 grant 同一 serial 不重复授予 |
| R3-a | A 停在屏障并持锁，B 打开 | A 持锁期间 B 没有 `lock_acquired` 和 `txn_complete`；A 关闭后 B 取得锁，读到持久意图并恢复。等锁期间不以超时判失败 |
| R3-b | 删掉 `navigator.locks` 后打开 | `no_web_locks`；grant 不产生事务；库内容不变 |
| R3-c | 丢回执、错身份、重复回执、迟到回执，以及 intent/commit 两阶段的真实 abort | abort 时 current 不变、不授予、不报已保存；丢回执或错身份时业务保持 pending；重复或迟到回执只授予一次；关页重开后授予都不重复 |

所有 R1 场景都还没有在真实候选上跑过，断言细节以 R1 接线后的联合矩阵为准。真实进程重启、配额、旧 v5 迁移和正式 shell/CSP 属于 R4，本驱动不覆盖，也不混称通过。

## 验证记录

- 2026-10-04，Chrome 148.0.7778.96，Playwright 1.63.0：
  - 不传候选：自检 PASS 10，R2/R3 共 10 个场景 BLOCKED，退出码 2；
  - 传入没有 Probe 的占位页面：同样 10 个场景 BLOCKED，自检 PASS，退出码 2。
