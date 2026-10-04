# #150 R2/R3 真实浏览器验收驱动（#239）

Owner：CURSOR-CLOUD（仅测试侧驱动）。父单 #150，工单 [#239](https://github.com/narutojzm1-dot/youjia/issues/239)；协议候选见 [重载恢复与持久意图](save-recovery-contract.md)。R1 封套/持久意图/写入协调器/恢复入口与 R4 迁移仍归 CODEX-LEAD。本驱动不复制或重写存储实现，不接正式 SaveStore/Main，不建第二套 Host。

## 当前状态

已在真实 R1 隔离候选上端到端跑通，组合为：

- 驱动和夹具：`12fd1358c1c13d3637ec1df59e3bee839bbc2ca1`；
- Gate：PR190 `f096a4a927c164c4bf70acc403a826a2074d2362`；
- Host 桥接与 Probe：PR #251 `2edb2e72d64f8de97887e5840ccaf1967bef8598`；
- 引擎与浏览器：Godot 4.7.2，Chrome 148。

结果是 R2/R3 共 11 个场景加驱动自检全部 PASS，合计 72 项检查。

这只证明**隔离测试候选**在同一浏览器 context 下的关页恢复、双页锁、无锁阻断和回执故障行为。它不是正式 Host 冻结，不接正式 SaveStore/Main，也不覆盖 R4（真实进程重启、配额、旧 v5 迁移、正式 shell/CSP）。

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

浏览器 context 为 Playwright 持久化 context，profile 放在临时 user-data-dir 里，整次运行共用一个。“关页”指 `page.close()` 后在同一 context、同一 origin 开新页，不是 reload，不清库，也不换 context。运行结束后删除 profile 和临时站点；每个场景使用独立测试库 `youjia-recovery-test-<uuid>`。场景结束时，驱动先关闭全部参与页，再由自检页按库名删除，删除结果计入检查。不调用候选的 `cleanup()`，因为参与页仍连着库时删除会被 `onblocked` 拦下。

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
| `cleanup()` | 只删除本测试库（驱动当前不调用，见上文清理方式） |

**`window.YoujiaRecoveryFixture`**（测试场景侧，由 CURSOR-CLOUD 在 R1 公开 API 上编写）

| 成员 | 约定 |
| --- | --- |
| `started` | Godot 夹具已运行并发布过至少一次状态。等锁、无锁拒绝时为真 |
| `ready` | 可写：已采纳可信 current，且没有 `blocked_reason` |
| `blocked_reason` | 不可写原因，例如 `opening store`、`not writable: no_web_locks`、`host bridge missing …`、`resolve failed: …`、`acknowledge failed: …`；可写时为空 |
| `grant(serial)` | 发起一次业务授予写入；`serial ≤ watermark` 时直接确认、不再授予，与探索契约的 `last_committed_trip_serial` 语义一致；业务在途时拒绝 |
| `business()` | `{ready, blocked_reason, verdict, watermark, grants: [...], pending, pending_request, confirmed_serials: [...], refused: [...]}`；`pending` 从受理 grant 起到 acknowledge 完成为止都为真；`refused` 记录被拒的 serial |

R1 若没有支撑 Fixture 的公开入口，会在 PR 中列出缺口，不另造 Host。

## Godot 业务夹具（层级按 CODEX-LEAD [#239 5982353530](https://github.com/narutojzm1-dot/youjia/issues/239#issuecomment-5982353530)）

- `test/save_recovery_web/fixture/main.gd`：实际 Godot 场景，使用 SaveWriteGate，经 JavaScriptBridge 与 R1 交互。Gate 源码在构建时取自 `GATE_REF`（默认 PR190 `f096a4a927c164c4bf70acc403a826a2074d2362`），用 `git show` 取出，不复制进仓库；`GATE_SOURCE.txt` 记录来源。Gate 接口不改。
- `test/save_recovery_web/fixture/facade.js`：`window.YoujiaRecoveryFixture` JS 门面，只转发 `grant` 并公开 Godot 发布的状态，不读写存储。
- 构建：`BUILD_FIXTURE=1 GODOT=… GODOT_WEB_TEMPLATE=… [HOST_DIR=… HOST_SHA=…] bash tools/verify_save_recovery_web.sh`。脚本把夹具导出成隔离最小项目（严格 wrapper 导入与导出），把 `HOST_DIR/head.html` 注入页面，其余文件复制进站点根，再跑矩阵。

夹具流程：
1. **启动**：`open` 后按 verdict 处理。`empty` 时 `initialize` 根 payload `{watermark: 0, grants: []}`；`clean`、`restored_*` 时以可信 current 的 payload 和 token 作为 Gate 的 confirmed 初值；其他情况（`quarantined`、`no_web_locks`）不写入，只公开 `blocked_reason`。
2. **授予**：`grant(serial)` 在 `serial ≤ watermark` 时直接确认，不写入。否则按以下顺序进行：
   - `prepare` 取得 candidate token；
   - `gate.begin_write(candidate, current)` 后立刻 `mark_unknown`；
   - `submit` 后把回执交给 `gate.resolve_verified_json`；
   - observed 等于 candidate 时，才确认业务、推进 token，然后 `acknowledge`；
   - 错身份、重复或迟到的回执由 Gate 拒绝，保持在途；
   - `submit` 报错时，不立即重试，先 `resolve`，由 Host 按可信 current 出回执来收尾。
   - `resolve` 本身报错时，最多再重试 5 次，每次间隔 0.2 秒；仍失败则保持在途、停止重试，并公开 `resolve failed`。
3. **收尾**：业务确认后先 `acknowledge`，完成后才解除在途。因此 `pending` 为假时意图已清理，紧接着的 grant 不会被 Host 以 `recovery required` 拒绝。`acknowledge` 失败不回滚已确认的提交，但公开为 `acknowledge failed`，不再显示可写。

**需要 R1 桥接提供的 `window.YoujiaRecoveryHostBridge`**（CODEX-LEAD 实现；每个方法最后一个参数是 Godot 回调，回调参数为一个 JSON 字符串；token 即封套 `commit_id`）

| 方法 | 回调内容 |
| --- | --- |
| `open(store, cb)` | `openStore` 后执行 `recover`：返回 `{verdict, current_payload, current_token}`；`openStore` 拒绝时返回 `{verdict: "no_web_locks"}`；出错返回 `{error}` |
| `initialize(payload_text, cb)` | 显式建根，返回同上（`verdict: "clean"`） |
| `prepare(payload_text, parent_token, cb)` | 以可信 current（commit_id 必须等于 `parent_token`）冻结 `envelope`，返回 `{candidate_token, request_id}`，或 `{error}` |
| `submit(request_id, write_id, cb)` | 提交已冻结的 candidate，返回 `youjia.save-receipt/v1` 回执 `{schema, write_id, candidate_token, parent_token, observed_token, old_write_terminated}`，或 `{error}`。Probe 的四种回执注入作用在这里 |
| `resolve(request_id, write_id, cb)` | 在锁内 `recover`，再按可信 current 为该在途写入出回执：`observed_token` 取 current 的 commit_id；只有活动意图已不存在时，`old_write_terminated` 才为 true |
| `acknowledge(request_id, cb)` | 返回 `{status, request_id}`，或 `{error}` |

## R1 store.mjs 消费映射（历史记录，已被上面的 HostBridge 流程取代）

下表是对照 PR #251 `ad6cfc0` 时的最初设想，仅保留作为来历。现行流程以上面的 HostBridge 六方法为准：空库由 `recover` 直接判为 `empty`；失败后走 `resolve`，不再由夹具先 `recover()`。

| Fixture 动作 | 使用的 R1 API | 说明 |
| --- | --- | --- |
| 页面启动 | `openStore(recovery_store, hooks)` → `snapshot()`：三项都为空时 `initialize(根 payload)`，否则 `recover()` | `recover()` 遇到空库会判为 `quarantined`，因此空库必须先显式建根；`openStore` 抛出 `no_web_locks` 时，Probe 报 `no_web_locks`，Fixture 不写入 |
| `grant(serial)` | 读取可信 `current`，从 payload 取出水位：`serial ≤ watermark` 时直接确认，不写入；否则 `envelope(新 payload, current)` → `submit(candidate)` | 新 payload 为 `{watermark: serial, grants: [..., serial]}`。每次 `envelope` 生成新的 `request_id`，重试天然换身份 |
| 确认 | `submit` 返回的记录与提交的 candidate 完全一致后，解析 payload，更新 `confirmed_serials`，清除 `pending` | 只认返回的可信记录，不认调用方本地对象 |
| 失败 | `submit` 抛出（真实 abort、`stale parent`、`recovery required`、读回不一致）时保持 `pending`，先 `recover()` 读出可信水位，再决定是否以新的 envelope 重试 | 不把失败当作授予失败立即重试 |
| 屏障 | `hooks.barrier(name, request_id)` 由 Probe `arm(name)` 返回永不完成的 Promise | 两处屏障都在事务完成后、持有同一把 Web Lock 时触发，与驱动约定一致 |

**发现的接口差异（第 1、2 条已由 PR #251 `3ba15edc90f5fde969157ab3067d21d15f493556` 落实：`acknowledge(request_id)` 返回 `{status: cleared|already_clear}`，全空库判为 `empty`；第 4 条已确认放在 Godot 层）**

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
| R2-c | 同一次 evaluate 内连续 `grant(1)`、`grant(2)` | 第二次在第一次收尾前被拒绝；业务显示 watermark 1、grants [1]，只确认了 1，从不出现 0；存储 payload 与业务一致，意图已清理；之后 `grant(2)` 只提交一次，与存储一致 |
| R3-c | 丢回执、错身份、重复回执、迟到回执，以及 intent/commit 两阶段的真实 abort | abort 时 current 不变、不授予、不报已保存；丢回执或错身份时业务保持 pending；重复或迟到回执只授予一次；关页重开后授予都不重复 |

每个场景结束时先关闭全部参与页，再由自检页按测试库名删除，删除结果计入检查。参与页仍连着库时删除会被 `onblocked` 拦下。

**等待策略**：驱动分两级等待。第一级只要求 Probe 已挂载、Godot 夹具已启动（facade 的 `started`）；第二级才要求可写（`ready`）。R3-a 的 B 页在等 A 释放锁，R3-b 是无锁拒绝，这两种情况只等第一级，再读取 recovery 与事件，不改动夹具业务上的 `ready` 来掩盖不可写。桥接已在、夹具却始终不可写时，记 FAIL 而不是 BLOCKED。

真实进程重启、配额、旧 v5 迁移和正式 shell/CSP 属于 R4，本驱动不覆盖，也不混称通过。

## 验证记录

- 2026-10-04，Chrome 148.0.7778.96，Playwright 1.63.0：
  - 不传候选：自检 PASS 10，R2/R3 共 10 个场景 BLOCKED，退出码 2；
  - 传入没有 Probe 的占位页面：同样 10 个场景 BLOCKED，自检 PASS，退出码 2。
- 2026-10-04，`BUILD_FIXTURE=1`，Godot 4.7.2，严格 wrapper 导入/导出通过：
  - Godot 夹具在 Chrome 中实际启动，接上 JS 门面，公开 `host bridge missing`；
  - 10 个场景 BLOCKED，原因为 `probe=missing; fixture=not ready: host bridge missing`，自检 PASS 10，退出码 2；
  - 夹具的写入路径还没有经过真实 Host 执行。
- 2026-10-04，接入真实 R1 桥接 `2edb2e7`（Godot 4.7.2 严格导入/导出，Chrome 148.0.7778.96，Playwright 1.63.0）：
  - 修复了独立审核 review251_bridge 指出的夹具同帧重入问题（P1），以及 CODEX-LEAD 指出的两处等待条件；
  - 驱动和夹具在 `12fd135` 上连续跑两次，均为 12/12 PASS、72 项检查，退出码 0，日志里没有 ERROR，也没有编码告警；
  - 第一次运行的完整证据存为 [`test/save_recovery_web/evidence/2026-10-04-r2r3-12fd135-host-2edb2e7.json`](../../test/save_recovery_web/evidence/2026-10-04-r2r3-12fd135-host-2edb2e7.json)，含每个场景的数据库前后快照、屏障停点、事件序列和恢复结果；
  - Godot Web 导出不是逐字节可复现的，两次构建的 PCK SHA256 不同（`75de4f3f…` 与 `b59e28a6…`），证据里记的是当次构建的哈希。
- **变异验证**：把夹具换回修复前的 `6401500` 版本后，R2-c FAIL（第一次请求一直无法收尾），R3-a 因夹具不发布启动状态而 BLOCKED，其余场景照常 PASS。说明新场景能拦住这次的重入缺陷。
- 中间一次运行里，R2-c 的业务断言全部通过，但清理步骤因参与页仍连着库被拦下，记为 FAIL。改成关页后再删库之后，连续两次都通过。
- 2026-10-04，处理 PR #247 审核的 5 条 P3：
  - 修了四处：`resolve` 加重试上限；acknowledge 完成前保持在途；夹具没启动时记 FAIL；文档对齐。
  - 驱动和夹具在 `edcde8b` 上连续跑两次，均为 12/12 PASS、73 项检查（R2-c 新增一项“收尾后立即 grant 被接受”），退出码 0。组合同上：Gate `f096a4a`、Host `2edb2e7`、Godot 4.7.2、Chrome 148。
  - 变异验证：新驱动配 `2d2054f` 合入版的夹具时，R2-c FAIL。业务显示已收尾时意图尚未清理，紧接着的 grant 被拒，场景随之超时。
  - `resolve` 重试上限这条路径，现有场景还触发不到，只经过代码审读。
