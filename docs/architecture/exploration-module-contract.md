# 外出探索模块契约（EXP-CONTRACT 设计稿）

- 编号：EXP-CONTRACT · [issue #151](https://github.com/narutojzm1-dot/youjia/issues/151) · Owner `CURSOR-CLOUD`
- 状态：**设计稿，待 CODEX-LEAD 与 ENGINEERING-SUPERVISOR 评阅后冻结**；不是已实现接口，不选定探索形式、地点、带回物或布置方式。
- 上位文档：[边界草案](exploration-boundary-contract.md)、[系列计划](yard-growth-delivery-plan.md)。共享持久化与物品身份以 CODEX-LEAD 的 [#150](https://github.com/narutojzm1-dot/youjia/issues/150) 为准；本文第 10 节列出需要双方一起冻结的点。
- 后续：冻结后 [#152](https://github.com/narutojzm1-dot/youjia/issues/152) 按本文实现纯核心与隔离测试；[#153](https://github.com/narutojzm1-dot/youjia/issues/153) 等产品选定形式与资源后接入首片。

## 1. 设计目标与不做的事

探索是小院生活的**自愿补充**：可以不出门，出门后可以随时回、可以空手回；带回什么由玩家自己选。契约要保证四件事：

1. **形态无关**：同一核心既能接“手绘小景里亲自散步”，也能接“路线卡片/节点”，不预先选定。
2. **不丢、不重**：玩家已选的东西在宿主确认落盘前一直保留（唯一例外是内容确实不被接受时的 `settle_empty`，以及探索记录本身损坏，见 §4、§8）；同一趟旅程无论重复点击、回调、刷新、重启，最多授予一次。
3. **不困住玩家**：任何失败都有“再试一次”和“先回院子”两条出路；损坏或未知的探索记录不会连带清空小院、相册、关系或花圃。
4. **不新增时钟**：不读现实时间，不做离线收益、过期、体力或冷却；只采样宿主现有的游戏时钟。

不做：正式地图/地点/物品/数值、摆放逻辑、摄影新功能、通用剧情或路线生成器、关系分数联动。

## 2. 模块划分（建议目录 `scripts/exploration/`）

| 文件（建议名） | 类型 | 职责 | 禁止 |
| --- | --- | --- | --- |
| `exploration_contract.gd` | `class_name ExplorationContract`，静态常量与校验 | 契约版本、状态名、事件名、ID 格式、尺寸预算；`sanitize_record()` / `validate_catalog()` | 不持有状态，不访问 SaveStore |
| `exploration_session.gd` | `class_name ExplorationSession extends RefCounted` | 旅程状态机：接受事件、返回结果、产出只读视图与结果提案；可注入随机种子 | 不创建/删除 Node，不加载资源，不写文件，不发全局信号 |
| `exploration_catalog.gd` | `class_name ExplorationCatalog extends RefCounted` | 路线定义的只读注册表（纯数据）；区分 `formal` 与 `fixture` 两个来源 | 只含纯数据，不含执行逻辑；画面资源映射留在表现适配器；fixture 不进正式包的运行时注册 |
| `fixtures/`（仅测试） | 内部夹具数据 | 隔离测试用的假路线、假物品，ID 统一 `fixture.` 前缀 | 不得被宿主正式入口加载，不得提交进玩家存档（见 §6） |
| 表现适配器（#153，形式确定后） | Node 场景 | 把输入翻译成核心事件、把视图数据画出来 | 不直接改会话字段，只调核心 API |

宿主桥接（Main 场景切换、输入/相机/暂停恢复、SaveStore 提交）归 CODEX-LEAD 按边界草案负责；核心只通过本文 API 与宿主交流。

## 3. 形态无关的旅程模型

一条路线在核心眼里是一张**小图**：若干“停留点（stop）”和它们之间的可达关系，每个停留点可以挂一个“可能发现的东西”的候选池。

```text
route = {
  route_id: "formal.meadow_path"        # 由已确认目录提供，示例名不代表批准
  start_stop: "gate"
  stops: {
    "gate":   { next: ["brook"],  find_pool: [] }
    "brook":  { next: ["gate", "ridge"], find_pool: [{find_id, weight}], empty_weight }
    "ridge":  { next: ["brook"],  find_pool: [...] , empty_weight }
  }
  carry_limit: 1                        # 每趟最多带回几样，由产品选定；默认 1
  return_stops: ["gate"] 或 "any"       # 哪里可以回院；"any" 表示随时可回
}
```

两种候选形式都映射到同一组事件：

| 玩家体验 | 亲自散步适配 | 路线卡片适配 | 核心事件 |
| --- | --- | --- | --- |
| 出门 | 在院门/入口选择出发 | 点选一张去处卡 | `begin(route_id, clock)` |
| 走到一处 | 走进停留点热区 | 选下一张卡/节点 | `visit(stop_id)` |
| 看见可带的东西 | 热点出现物件 | 节点里展示 | （由 `visit` 首次进入时决定，见 §5） |
| 决定带走 / 放下 | 拿起 / 放回 | 点“带上”/“不带了” | `take(find_id)` / `release(find_id)` |
| 回院 | 走回入口，或随时点“回院子” | 点“回家” | `request_return(reason)` |

`return_stops` 默认建议 `"any"`，即随时可回，符合“可以随时结束”；是否要求走回入口是表现层体验选择，由产品决定。

## 4. 状态机

状态名为契约常量（字符串，便于 JSON 与日志阅读）：

| 状态 | 含义 | 是否持久化 |
| --- | --- | --- |
| `idle` | 没有进行中的旅程 | 只存 `next_trip_serial` 等元数据 |
| `active` | 在外面：可以走动、发现、带上/放下 | 是 |
| `pending_commit` | 已请求回院，结果提案已冻结，等宿主落盘确认 | 是 |
| `recoverable_failure` | 宿主落盘失败或恢复时发现问题；提案仍保留 | 是 |
| `committed` | 宿主确认已落盘；等待宿主收尾 `close()` | 是（短暂） |

合法转换（其余一律拒绝，见下）：

| 当前 | 事件 | 结果 | 说明 |
| --- | --- | --- | --- |
| `idle` | `begin(route_id, clock)` | `active` | 路线必须在已注入目录中；分配新的 `trip_serial` |
| `active` | `visit(stop_id)` | `active` | 只能去 `next` 可达点；首次到达时确定该点的发现（§5） |
| `active` | `take(find_id)` | `active` | 必须是当前点已出现、未被带走的；超过 `carry_limit` 拒绝 |
| `active` | `release(find_id)` | `active` | 放回原处，可再拿 |
| `active` | `request_return(reason)` | `pending_commit` | 冻结提案：`items` = 当前携带，可为空；`reason ∈ {player, cancel, host_interrupt, restored}` |
| `pending_commit` | `commit_succeeded(trip_id)` | `committed` | `trip_id` 必须与提案一致 |
| `pending_commit` | `commit_failed(trip_id, retryable=true)` | `recoverable_failure` | 落盘类失败；记录失败码与尝试次数，提案原样保留 |
| `pending_commit` | `commit_failed(trip_id, retryable=false, rejected≠[])` | `pending_commit` | 部分物品已失效：移出 `rejected` 中的项，`revision + 1`，`trip_id` 不变，宿主再提交一次。若 `rejected` 与提案物品没有交集，返回 `invalid_rejection` 且不做修改，避免空转 |
| `pending_commit` | `commit_failed(trip_id, retryable=false, rejected=[])` | `recoverable_failure`（`retryable=false`） | 内容整体不可接受；此时 `retry_commit` 被拒，只能 `settle_empty` |
| `recoverable_failure` | `retry_commit()` | `pending_commit` | 仅 `retryable=true` 时允许；同一提案、同一 `trip_id` 再交一次 |
| `recoverable_failure`（仅 `failure.retryable == false`） | `settle_empty()` | `pending_commit` | **终止出口**：提案改为空 `items`、`revision + 1`、`trip_id` 不变。宿主对空提案不做内容校验（§7），只可能因落盘失败而失败，因此一定能收尾 |
| `recoverable_failure` | `defer_to_yard()` | `recoverable_failure`（标记 `deferred`） | 玩家先回院子；提案保留，宿主下次启动或空闲时自动重试，不丢不重 |
| `committed` | `close()` | `idle` | 清掉旅程字段 |

**不会困住玩家**：任何停在 `recoverable_failure` 的会话，都至少有一条通往 `committed` 的路。可重试的失败走 `retry_commit`；不可重试的失败走 `settle_empty`，只有“空提案也落盘失败”（磁盘层问题）才会继续停留，而这种情况玩家仍可 `defer_to_yard` 回院正常生活。玩家主动放弃已带物品不属于本契约默认行为；如需要，作为产品决定另行加入。`settle_empty` 会舍弃这一趟里无法收下的东西；它只在内容确实不被接受时使用，表现层要用温和文案说明，不当作惩罚。

“取消”不是特殊状态：就是 `request_return(reason="cancel")`，提案可以为空，照样走一遍提交。这样“空手回”和“带东西回”是同一条路，宿主也能统一做幂等。

**非法事件**：返回 `{ok: false, error: <code>}`，会话**不做任何修改**。错误码集中定义，例如 `illegal_transition`、`unknown_route`、`unreachable_stop`、`not_offered`、`carry_limit`、`trip_mismatch`、`pending_exists`。重复点击“回院”在 `pending_commit` 下收到 `illegal_transition`，这不算故障，表现层忽略即可。

**`pending_exists`**：只要还有 `pending_commit` / `recoverable_failure` 的提案，`begin` 一律拒绝。必须先把上一趟收好，避免新旅程覆盖未落盘的所得。

## 5. 随机与发现

- 核心不使用全局随机。`begin` 接受可选 `seed`；不给时由宿主注入的随机源生成，只持久化 `rng_seed`。
- **每个停留点的掷骰只由 `(rng_seed, stop_id)` 决定**：取 `(rng_seed + ":" + stop_id).sha256_buffer().decode_s64(0)` 作为该点专用种子（有符号 64 位，不经过 `hex_to_int()`，避免高位为 1 时溢出被截断；也不用引擎内部的 `String.hash()`，避免跨版本变化），再新建 `RandomNumberGenerator` 掷一次。这样结果与访问顺序无关；崩溃后换个顺序走，也得到同样的发现。同时不需要保存 `rng_state`，也避开了 Godot 中设置 `seed` 会重置 `state` 的顺序陷阱。
- **`rng_seed` 以十进制字符串存储（允许负号）**：它是有符号 64 位整数，JSON 数字超过 2^53 会丢精度。
- 每个停留点**第一次到达时**确定一次：按权重从 `find_pool` 选出 0 或 1 个发现（`empty_weight` 允许什么都没有），结果写进 `offers[stop_id]`，并要求宿主立即保存（§11 `persist`）。以后再来、重启恢复都读记录，不重掷，避免“刷新重掷”变成反复劳动。
- “每点 0 或 1 个发现”、`carry_limit` 上限 3、每条路线最多 16 个停留点，都是**建议默认值**，需随产品选择的形式确认。
- 空手是正常结果：没有“失败”文案，不计数、不惩罚。

## 6. 持久化记录（纯值）

存放位置由 #150 冻结（建议 SaveStore 下单一键 `exploration`，与小院所得**在同一次原子保存里**写入，见 §7）。只允许 JSON 基本类型：

```text
# 核心拥有、宿主原样保存的探索记录
exploration = {
  contract_version: 1,
  next_trip_serial: 3,                 # 核心的下一个序号提示；实际分配见下方规则
  session: null | {
    trip_id: "trip-3",                 # = "trip-" + serial
    trip_serial: 3,
    route_id: "formal.xxx",
    catalog: "formal",                 # "formal" | "fixture"
    state: "active" | "pending_commit" | "recoverable_failure" | "committed",
    started_clock: { day: 4, elapsed: 132.5 },   # 只做记录与将来照片身份，不驱动任何计时
    current_stop: "brook",
    visited: ["gate", "brook"],
    offers: { "brook": "formal.find.xxx" | "" },
    carried: ["formal.find.xxx"],
    rng_seed: "-1234567890123",
    proposal: null | {
      trip_id: "trip-3",
      route_id: "formal.xxx",
      items: [ { find_id: "formal.find.xxx" } ],
      reason: "player",
      revision: 1
    },
    failure: null | { code: "save_failed", retryable: true, attempts: 1, deferred: false }
  }
}

# 建议放在 #150 共享区、**在 exploration 键之外**，由宿主拥有
last_committed_trip_serial: 2          # 已成功落盘的最大旅程序号；探索记录损坏时它仍在
```

**序号分配规则**：`next_trip_serial` 不是非负整数或大于 `last_committed_trip_serial + 1_000_000` 时视为损坏，忽略它。核心在 `restore` 时同时接收 `last_committed_trip_serial`（§11）。`begin` 分配的序号永远是 `max(next_trip_serial, last_committed_trip_serial + 1)`。因此无论探索记录缺失、损坏重置还是被手动删除，新旅程的序号都严格大于已提交序号，不会被宿主误判为“已提交”而吞掉所得。

约束：

- **ID 格式**：`^(formal|fixture)(\.[a-z0-9_]+){1,4}$`，总长不超过 64；`stop_id` 为 `^[a-z0-9_]{1,32}$`。会话的 `catalog` 必须与 `route_id` 前缀一致，所有 `find_id` 前缀也必须与之一致，否则按损坏处理。
- **尺寸预算**：`stops` 不超过 16 个，`visited`/`offers` 随之有界，`carried` 不超过 `carry_limit`（上限 3）。整段序列化后不超过 4 KB。超限按损坏处理（§8）。
- **禁止进入记录的内容**：Node 引用、Callable、资源路径、纹理、场景树路径、屏幕坐标、现实时间戳。表现层需要的位置/画面由适配器根据 `route_id + stop_id` 查目录得到。
- 夹具闸门：正式入口不能 `begin` fixture 路线；玩家存档恢复时读到 `catalog == "fixture"` 的会话按损坏处理（§8）；万一仍被提交，宿主拒绝其中所有物品（`rejected` = 全部），核心随即只剩空提案并正常收尾。三道闸门保证夹具所得进不了玩家档，同时不会把探索锁死。

## 7. 宿主提交协议（建议，待与 #150 共同冻结）

以下是本稿对宿主侧的**建议流程**，具体落在 CODEX-LEAD 的 #150 / Host bridge 中，以共同冻结的版本为准：

```text
核心                                宿主（CODEX 侧 SaveStore 桥）
request_return ──► pending_commit
   proposal(trip_id, items) ───────► 1. trip_serial <= last_committed_trip_serial ?
                                         是 → 视为已落盘，直接回 succeeded（不再发物）
                                     2. items 为空 → 跳过内容校验，直接到 3
                                        否则校验 items 都是 formal 目录合法 ID；
                                        有失效项 → commit_failed(retryable=false, rejected=[失效项])
                                     3. 同一次原子保存写入：
                                          - 取得物进入 #150 的持有状态
                                          - last_committed_trip_serial = trip_serial
                                          - 核心当前的 to_record()（此时为 pending_commit）
                                     4. save() 成功 → commit_succeeded(trip_id)
                                        save() 失败 → commit_failed(trip_id, retryable=true)
committed ◄──────────────────────────
close() ──► idle（宿主保存 to_record()，可与下次任意保存合并）
```

要点：

- **探索记录只由核心生成**：宿主只原样保存 `to_record()`，不直接改其中字段。即使第 3 步存下的会话仍是 `pending_commit`，恢复时发现 `trip_serial <= last_committed_trip_serial` 就会直接视为 `committed`（§8），不会二次授予。
- **幂等键用单调序号，不用集合**：宿主只需保存一个整数 `last_committed_trip_serial`，放在探索记录之外（§6）。它比保存所有已提交 ID 的集合更有界，也不会随游戏时长膨胀。
- **授予与序号同一次原子保存**：如果“发物”和“推进已提交序号”分两次写，中间崩溃就会重复发物或丢物，所以建议放进同一次 `save()`。这依赖 #149 的可靠替换（失败不删旧档）。
- **部分非法物品**：宿主回 `commit_failed(retryable=false, rejected=[...])`，核心移出失效项、`revision + 1`，仍是 `pending_commit`（§4）。`trip_id` 不变，所以仍然最多授予一次；全部失效时就成为空提案。
- **空提案永远可收**：取消、空手、`settle_empty` 都产生空提案。宿主对它不做内容校验，只推进序号；只有落盘本身失败才会失败。这是“不困住玩家”的兜底。

## 8. 恢复与降级

宿主加载存档后调用 `ExplorationSession.restore(record, catalog, last_committed_trip_serial)`，核心返回“恢复后状态 + 建议宿主动作”。表格**自上而下匹配，命中第一行即停**（唯一例外是“停留点已被移除”这一行：它只做清理，清理后继续匹配紧接着的 `active` 行）；所有 `idle` 结果的下一个序号都按 §6 规则取 `max(next_trip_serial, last_committed_trip_serial + 1)`，绝不回退：

| 读到的记录 | 恢复结果 | 建议宿主动作 |
| --- | --- | --- |
| 缺失 / 不是字典 | `idle` | 无 |
| `contract_version` 比当前新 | 不解析、不改写原始数据 | `quarantine`：宿主原样保留这段数据（#150 定位置），本次不开放出门，并给出非阻断提示；其余小院功能照常 |
| 字段损坏 / 超预算 / ID 非法 / 前缀不一致 / 玩家档里出现 `catalog == "fixture"` | `idle` | `log_and_reset_session`：只丢弃旅程字段，不碰小院其他数据。**若损坏记录里有尚未落盘的提案，它会随之丢弃**；这是明确记录的降级，列入 #152 坏数据测试 |
| 任意状态，且 `trip_serial <= last_committed_trip_serial` | `committed` | 直接 `close()`（说明上次已落盘，只是收尾前中断） |
| 路线已从目录移除（`active`） | 强制 `pending_commit`，提案包含全部已携带物 | 提示后回院；失效物品由宿主提交校验拒绝（§7） |
| 路线仍在，但 `current_stop` 或部分 `visited` / `offers` 的停留点已被移除（`active`） | 从 `visited` / `offers` 中剔除失效点；`current_stop` 失效时回到 `start_stop`；已携带物保留，提交时由宿主按目录校验；然后按下一行继续处理 | 同下一行 |
| `active`（路线与 `current_stop` 均有效） | `active`，停在 `current_stop` | **待产品选择**：A 继续旅程（回到该点）/ B 安全回院（`request_return(reason="restored")`，已带上的东西照常提交）。核心两种都支持 |
| `pending_commit` / `recoverable_failure` | 原状态 | 自动重试提交（`retryable=false` 的失败则提示后 `settle_empty`） |
| `committed`（但序号大于宿主已提交序号） | `pending_commit` | 说明宿主序号丢失或回退；重新提交同一提案，不直接关闭。此时序号已无法判断物品是否已授予，可能重复授予一次——这是有意的取舍：宁可多给一次，也不吞掉玩家所得 |

推荐 B（安全回院并保留已带上的东西）作为默认候选：重启后回到熟悉的小院，不丢玩家选择，也不需要恢复院外场景状态。最终由产品决定，经 #146 汇总。

## 9. 时间、生命周期与摄影

- **时间**：核心不调用 `Time`/`OS` 的现实时钟。宿主在 `begin` 和需要时传入 `{day, elapsed}` 采样（来自现有 `YardWorld.holiday_day` / `_day_elapsed`）。旅程期间游戏日是否继续流逝、院外光影如何采样，由宿主设计决定，并且只能用同一个时钟。会话没有超时、过期或冷却。
- **生命周期**：`ExplorationSession` 是 RefCounted，不连接全局信号。表现适配器的 `bind(view)` / `release()` 由宿主在进出场景时调用，`release` 必须断开输入与信号。反复创建/释放 1000 次的泄漏测试列入 #152。
- **视图数据**：`get_view()` 返回只读字典（当前点、可达点、本点发现、携带、能否回院、状态）。表现层只读它，不改。
- **摄影**：核心提供 `scene_identity()` = `{trip_id, route_id, stop_id, clock}`，供以后摄影切片作为可信现场身份。本契约不承诺院外拍照或自由取景。

## 10. 需与 #150 共同冻结的点

| # | 问题 | 本稿建议 |
| --- | --- | --- |
| 1 | 探索记录放在 SaveStore 哪个键、由谁迁移 | 单键 `exploration`，SaveStore v6 迁移由 CODEX 集中负责；缺失时视为 `idle` |
| 2 | 幂等凭证形式与位置 | 宿主侧单个整数 `last_committed_trip_serial`，放在共享区、`exploration` 键之外，恢复时传给核心（§6、§7） |
| 3 | 取得物身份与目录 | `formal.` 前缀 ID 来自 #150 的正式目录；核心只引用 ID，不定义物品字段 |
| 4 | 授予的原子性 | 授予 + 序号 + 核心当前记录同一次 `save()`；依赖 #149 |
| 4b | 空提案 | 宿主对空提案不做内容校验，只推进序号，保证 `settle_empty` 一定能收尾 |
| 5 | 未来版本数据的隔离位置 | #150 提供一个隔离槽，原样保存，不清除 |
| 6 | 旅程期间院内时钟 | 由 Host 设计定；核心只读采样 |
| 7 | 重启时 `active` 的玩家策略 | A 继续 / B 安全回院，推荐 B；产品经 #146 选定 |

## 11. 核心 API 草案（供 #152 实现，名称冻结前可调整）

```gdscript
class_name ExplorationSession extends RefCounted

static func restore(record: Variant, catalog: ExplorationCatalog, last_committed_trip_serial: int) -> Dictionary
    # → { session: ExplorationSession, host_action: String }

func begin(route_id: String, clock: Dictionary, seed: Variant = null) -> Dictionary
func visit(stop_id: String) -> Dictionary
func take(find_id: String) -> Dictionary
func release(find_id: String) -> Dictionary
func request_return(reason: String) -> Dictionary
func commit_succeeded(trip_id: String) -> Dictionary
func commit_failed(trip_id: String, retryable: bool, rejected: PackedStringArray = []) -> Dictionary
func retry_commit() -> Dictionary
func settle_empty() -> Dictionary
func defer_to_yard() -> Dictionary
func close() -> Dictionary

func get_state() -> String
func get_view() -> Dictionary
func get_proposal() -> Dictionary      # 没有时返回 {}
func scene_identity() -> Dictionary
func to_record() -> Dictionary         # 纯值，可直接 JSON
```

所有变更类方法统一返回 `{ok: bool, error?: String, state: String, persist: bool}`。`persist == true` 表示宿主应立即保存 `to_record()`，例如 `begin`、首次到达某点（`offers` 新增）的 `visit`、`take`、`release`、`request_return`、`settle_empty`和提交结果之后；`close` 返回 `persist: false`，其记录可与下一次任意保存合并（与 §7 一致）。

## 12. #152 隔离测试计划（独立 suite，纳入 strict daily）

1. 合法路径：出门 → 走两点 → 带一样 → 回院 → 提交成功 → 关闭；空手回；取消回。
2. 非法转换全表：每个状态下发送每个不允许的事件，断言错误码且记录字节不变。
3. 重复操作：连续 `request_return`；同一 `trip_id` 重复 `commit_succeeded`；宿主重复提交同一序号时不二次授予（用假宿主计数）。
4. 提交失败：可重试失败 → 重试成功；`defer_to_yard` → 重启 → 自动重试；不可重试且部分物品被拒 → `revision` 递增、`trip_id` 不变；不可重试且无 `rejected` → `retry_commit` 被拒、`settle_empty` 收尾；全部物品被拒 → 空提案收尾；`rejected` 与提案无交集 → `invalid_rejection` 且记录不变；可重试失败下 `settle_empty` 被拒。断言任何失败序列后都存在到达 `committed` 的路径。
5. 恢复：每个状态 `to_record` → JSON 字符串 → `restore` 往返一致；负数与超过 2^53 的 `rng_seed` 往返不变；以不同顺序访问停留点得到相同发现；哈希首字节 ≥ 0x80 的停留点得到与其他点不同的种子且无引擎错误输出。
6. 坏数据：非字典、缺字段、类型错、超长数组、超 4 KB、非法 ID、前缀不一致、玩家档中的 fixture 会话、未来版本、异常 `next_trip_serial`（负数、小数、超大）；断言只重置旅程、不抛脚本错误。序号：记录缺失或损坏且 `last_committed_trip_serial = N` 时，下一趟序号必须是 N+1 且提交后真实授予（假宿主计数为 1）。
7. 目录变更：路线删除、停留点删除（含 `current_stop`）、物品删除后的恢复与提交。
8. 夹具闸门：正式入口 `begin` fixture 路线被拒；fixture 会话提交时物品全部被拒并以空提案收尾；正式目录加载不包含 `fixture.` ID。
9. 生命周期：1000 次 `begin/close` 与适配器 `bind/release`，无残留连接或对象增长。
10. 不读现实时钟：静态检查 `scripts/exploration/` 不出现 `Time.get_unix_time`、`Time.get_ticks`、`OS.get_unix_time`。

## 13. 交接

冻结后本文升为契约 v1，记录冻结 SHA。#152 完成后补充样例目录、失败矩阵结果和测试入口；#153 首片发布并经独立验收（#156）后，按系列计划进入贡献者共同维护阶段，重大接口或持久化变更仍统一评审。
