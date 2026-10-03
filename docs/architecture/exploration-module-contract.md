# 外出探索模块契约（EXP-CONTRACT 设计稿）

- 编号：EXP-CONTRACT · [issue #151](https://github.com/narutojzm1-dot/youjia/issues/151) · Owner `CURSOR-CLOUD`
- 状态：**设计稿已合入（PR #160），未冻结**。本轮按 ENGINEERING-SUPERVISOR 在 [#150 的评阅](https://github.com/narutojzm1-dot/youjia/issues/150) 修订 §7、§8、§10、§11、§12，待 CODEX-LEAD 与 ENGINEERING-SUPERVISOR 共同冻结。不是已实现接口。首片形式已由用户选定为画卷漫步（见[探索形式](exploration-form-options.md)），但本契约保持形态无关，不选定地点、带回物或布置方式。
- 上位文档：[边界草案](exploration-boundary-contract.md)、[系列计划](yard-growth-delivery-plan.md)。共享持久化与物品身份以 CODEX-LEAD 的 [#150](https://github.com/narutojzm1-dot/youjia/issues/150) 为准；本文第 10 节列出需要双方一起冻结的点。
- 后续：冻结后 [#152](https://github.com/narutojzm1-dot/youjia/issues/152) 按本文实现纯核心与隔离测试；[#153](https://github.com/narutojzm1-dot/youjia/issues/153) 等产品选定形式与资源后接入首片。

## 1. 设计目标与不做的事

探索是小院生活的**自愿补充**：可以不出门，出门后可以随时回、可以空手回；带回什么由玩家自己选。契约要保证四件事：

1. **形态无关**：同一核心既能接“手绘小景里亲自散步”，也能接“路线卡片/节点”，不预先选定。
2. **不丢、不重（限定范围）**：在保存正常工作的前提下，玩家已选的东西在宿主确认落盘前一直保留；同一趟旅程无论重复点击、回调、刷新、重启，最多授予一次。明确的例外：内容确实不被接受时的 `settle_empty`（§4）；探索记录本身损坏时，含会话的记录被隔离并冻结出门，所得既不授予也不丢弃，待明确的恢复政策处理（§8）；保存持续失败期间又被强制退出，只能恢复到最后一次成功保存的状态（§7.2）；宿主无法给出可信的已提交序号时，相关旅程被隔离并冻结自动提交，既不重发也不宣称已收好，待明确的恢复政策处理（§8、§10 第 8 项）。仅凭失真的序号，无法在损坏场景下同时保证“不丢”和“不重”。
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
| `idle` | `begin(route_id, clock)` | `active` | 路线必须在已注入目录中；分配新的 `trip_serial`。`can_begin == false` 时拒绝，拒绝码按优先级取第一个命中的：`watermark_untrusted`（宿主序号不可信）> `quarantine_frozen`（`quarantine_and_freeze` 冻结）> `exploration_unavailable`（未来版本 `quarantine` 等其他不可出门结果）> `pending_exists`（有未收口旅程）（§8） |
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
| `recoverable_failure` | `defer_to_yard()` | `recoverable_failure`（标记 `deferred`） | 玩家先回院子；提案保留，宿主下次启动或空闲时自动重试，不丢不重。延后**不释放**这趟旅程的所有权：未收口前 `begin` 仍返回 `pending_exists` |
| `committed` | `close()` | `idle` | 清掉旅程字段 |

**不会困住玩家**：任何停在 `recoverable_failure` 的会话，都至少有一条通往 `committed` 的路。可重试的失败走 `retry_commit`；不可重试的失败走 `settle_empty`，只有“空提案也落盘失败”（磁盘层问题）才会继续停留，而这种情况玩家仍可 `defer_to_yard` 回院正常生活。玩家主动放弃已带物品不属于本契约默认行为；如需要，作为产品决定另行加入。`settle_empty` 会舍弃这一趟里无法收下的东西；它只在内容确实不被接受时使用，表现层要用温和文案说明，不当作惩罚。

“取消”不是特殊状态：就是 `request_return(reason="cancel")`，提案可以为空，照样走一遍提交。这样“空手回”和“带东西回”是同一条路，宿主也能统一做幂等。

**非法事件**：返回 `{ok: false, error: <code>}`，会话**不做任何修改**。错误码集中定义，例如 `illegal_transition`、`unknown_route`、`unreachable_stop`、`not_offered`、`carry_limit`、`trip_mismatch`、`pending_exists`。`quarantine_frozen` 泛指“会话处于隔离模式、不接受变更”，未来版本的隔离也用它（只有 `begin` 按 §4 优先级返回 `exploration_unavailable`），不表示一定有被冻结的旅程。重复点击“回院”在 `pending_commit` 下收到 `illegal_transition`，这不算故障，表现层忽略即可。

**`pending_exists`**：只要还有 `pending_commit` / `recoverable_failure` 的提案，`begin` 一律拒绝。必须先把上一趟收好，避免新旅程覆盖未落盘的所得。恢复时被冻结的隔离旅程同样算作未收口（`begin` 返回 `quarantine_frozen`）；宿主序号不可信时返回 `watermark_untrusted`（§6、§8）。

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
    record_revision: 7,                # 每次需保存的变更加一；persisted_revision 只在内存中，不存盘
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

**序号分配规则**：核心在 `restore` 时同时接收 `last_committed_trip_serial`（§11）。宿主序号可信时：`next_trip_serial` 不在下文整数范围内或大于 `last_committed_trip_serial + 1_000_000` 时视为损坏，忽略它；`begin` 分配的序号永远是 `max(next_trip_serial, last_committed_trip_serial + 1)`。宿主序号不可信（`-1`，§8）时：不分配任何序号，`begin` 一律拒绝（`watermark_untrusted`），也不做上述损坏判定。因此无论探索记录缺失、元数据损坏还是被手动删除，新旅程的序号都严格大于已提交序号，不会被宿主误判为“已提交”而吞掉所得。

约束：

- **整数范围与一致性**：`trip_serial`、`next_trip_serial`、`record_revision`、`proposal.revision`、`last_committed_trip_serial` 都是 JSON 整数，范围 `0 ≤ n ≤ 2^31 − 1`（`trip_serial` 从 1 起）；唯一例外是宿主传给 `restore` 的 `last_committed_trip_serial` 可以是 `-1`，表示“不可信”（§8），它不会写进探索记录；带小数、超范围或非数字按损坏处理。`trip_id` 必须严格等于 `"trip-" + str(trip_serial)`，`proposal.trip_id` 必须等于会话 `trip_id`，否则按损坏处理。
- **ID 格式**：`^(formal|fixture)(\.[a-z0-9_]+){1,4}$`，总长不超过 64；`stop_id` 为 `^[a-z0-9_]{1,32}$`。会话的 `catalog` 必须与 `route_id` 前缀一致，所有 `find_id` 前缀也必须与之一致，否则按损坏处理。
- **尺寸预算**：`stops` 不超过 16 个，`visited`/`offers` 随之有界，`carried` 不超过 `carry_limit`（上限 3）。整段序列化后不超过 4 KB。超限按损坏处理（§8）。
- **禁止进入记录的内容**：Node 引用、Callable、资源路径、纹理、场景树路径、屏幕坐标、现实时间戳。表现层需要的位置/画面由适配器根据 `route_id + stop_id` 查目录得到。
- 夹具闸门：正式入口不能 `begin` fixture 路线；玩家存档恢复时读到 `catalog == "fixture"` 的会话按损坏处理（§8）；万一仍被提交，宿主拒绝其中所有物品（`rejected` = 全部），核心随即只剩空提案并正常收尾。三道闸门保证夹具所得进不了玩家档，同时不会把探索锁死。

## 7. 宿主提交协议（建议，待与 #150 共同冻结）

以下是本稿对宿主侧的**建议流程**，具体落在 CODEX-LEAD 的 #150 / Host bridge 中，以共同冻结的版本为准：

```text
核心                                宿主（CODEX 侧 SaveStore 桥）
request_return ──► pending_commit
   提交请求(trip_id, proposal.revision) ─► 入队：宿主**统一串行事务队列**只记录提案身份 (trip_id, proposal.revision)，
                                          不复制 items；同一身份已在队列或在途时合并为一笔，不重复入队
                                          （在途那笔失败时，被合并的请求随之结束，不自动重放；
                                            核心进入 recoverable_failure，由 retry_commit() 后重新入队）
                                          何时入队见 §7.1“入队义务”
                                     ── 以下第 0–4 步在队首作为**一段不可交错的提交事务**执行 ──
                                     0. 重新读取核心当前状态：会话仍是宿主当前绑定的会话、状态为 pending_commit、
                                        且 get_proposal() 的 (trip_id, revision) 与队列身份一致？
                                        否（旧会话/已收口/提案已被拒绝项改写为新版本）→ 丢弃这笔请求并记日志，
                                        不回成功也不回失败（当前身份由 §7.1“入队义务”保证另有请求）
                                     1. trip_serial <= **此刻**已确认持久化的 last_committed_trip_serial ?
                                         是 → 本趟已在先前某次成功保存中落盘（例如确认丢失，或同 trip 前一笔刚成功），
                                              直接回 succeeded（不再发物）
                                     2. items（取自第 0 步刚读取的当前提案）为空 → 跳过内容校验，直接到 3
                                        否则校验 items 都是 formal 目录合法 ID；
                                        有失效项 → commit_failed(retryable=false, rejected=[失效项])，结束本笔事务
                                     3. 以宿主**当前内存状态**（包含院内合法但尚未保存的改动：新照片、关系、生活进展等）
                                        构造候选快照，并只在候选快照上写入：
                                          - 取得物进入 #150 的持有状态
                                          - last_committed_trip_serial = trip_serial
                                          - 核心当前的 to_record()（此时为 pending_commit）
                                     4. 以候选快照执行一次原子 save()，**等待持久化确认**：
                                        成功 → 只发布本次确认的授予与序号（不以候选快照整份覆盖工作内存），
                                               再回 commit_succeeded(trip_id)
                                        失败 → 丢弃候选快照；宿主内存中的持有物与序号保持写入前原样，
                                               院内未保存改动仍保留在内存、等待下次写入，
                                               回 commit_failed(trip_id, retryable=true)
                                     ── 第 4 步的结果发布完成后，队列才放行下一笔事务 ──
committed ◄──────────────────────────
close() ──► idle（宿主保存 to_record()，可与下次任意保存合并）
```

### 7.1 内存事务边界

- **幂等检查在串行提交临界区内**：第 0–2 步的会话、提案版本与水位检查必须在队首、紧挨着第 3–4 步执行，检查 → 构造候选 → 等待持久化确认 → 发布授予与水位是一段串行事务；只有本笔结果发布后才放行下一笔。只把文件写入串行化而在入队前做检查是不够的：已持久化水位为 2 时，同一 trip-3 的请求 A、B 都在 A 确认前通过检查，A 授予后发布水位 3，B 出队时不重查就会再加一次所得；核心之后拒绝重复的成功通知也撤不回已落盘的重复授予。
- **队列持有提案身份，不持有内容**：队列项只记 `(trip_id, proposal.revision)`，出队时从核心读取当前提案；不能把旧请求带来的 items 与出队时另一份 `to_record()` 拼成一笔提交。身份不一致（提案已因第 2 步的拒绝项升版、会话已收口或换了旅程）的请求在第 0 步丢弃。`settle_empty` 也会升版，但它只能从 `recoverable_failure` 发起，那时旧请求已因状态不是 `pending_commit` 在第 0 步被丢弃。
- **入队义务（不困住玩家）**：第 0 步可以丢弃请求，所以宿主必须保证“核心处于 `pending_commit` 时，队列里或在途中总有一笔当前身份的请求”。具体是：
  - 每当核心结果使会话进入或留在 `pending_commit` 且身份变化时，以当前 `(trip_id, proposal.revision)` 入队。包括 `request_return`、`retry_commit`、`settle_empty`、第 2 步拒绝后的升版，以及 §8 的 `submit_proposal`、`retry_commit`、`settle_empty` 三个恢复动作；
  - 兜底：每笔事务结束、队列空闲时，若核心仍是 `pending_commit` 且队列和在途中都没有当前身份，就重新入队。第 4 步“已落盘但成功回调丢失”时就靠这一条收尾：重新入队的请求在第 1 步按已确认水位直接回成功，不再发物。

  入队义务只关系到“不困住玩家”，不影响“不重复授予”；后者由第 0–1 步的队首重查保证。
- **比较依据只能是已确认持久化的序号**：第 1 步只能和“最近一次 `save()` 成功时写入磁盘的 `last_committed_trip_serial`”比较，不能和内存里先改过的值比较。
- **授予与序号先写候选快照，保存成功后才发布**：否则会出现这个反例——磁盘序号为 2；trip-3 先在内存里加物品、把序号改成 3；`save()` 失败；重试时用内存里的 3 判断为“已提交”并回成功；玩家关闭会话后崩溃，磁盘仍是 2，所得丢失。候选快照或“失败即完整回滚授予与序号”二者任选其一，具体由 #150 / 宿主桥（CODEX-LEAD）实现并冻结。
- **候选快照以当前内存为底，不以磁盘副本为底**：院内在提交之前已经发生、但尚未落盘的合法改动（新照片、关系变化、其他生活进展）必须一并进入候选快照；否则提交成功会用旧数据覆盖它们。
- **统一串行写入**：宿主所有保存（院内保存、出门阶段保存、回院提交）走同一条队列，同一时刻只有一次写入在进行。写入进行中又发生的改动（院内或探索）不并入正在写的快照，只把宿主标记为“仍有未保存改动”，在当前写入结束后**重排一次新的写入**，以届时的最新内存状态为底。写入失败不发布授予与序号，也不清掉院内的未保存标记。**成功回调只发布本次确认的内容**（授予、水位、对应的已保存版本），不能用写入开始时的候选快照整份覆盖当前工作内存；写入期间产生的较新改动及其未保存标记必须保留，交给重排的下一次写入。
- **单个序号足以幂等的前提**：同一时刻最多一趟未收口的旅程（`pending_exists`、`defer_to_yard` 不释放所有权，见 §4）；宿主只确认当前绑定会话的提案（第 0 步）。未知或旧会话的请求不能只凭 `serial <= watermark` 就被确认成功。
- 文件层的可靠替换（#149）只保证“失败不删旧档”，不能代替这里的内存事务协议。
- “提交失败 → 重试 → 成功 → 关闭 → 重启”必须不丢且只授予一次，列入 §10 共同冻结项与 §12 假宿主故障矩阵。同一 trip 在确认前的重复提交也必须只授予一次（§12 第 15 项）。

### 7.2 出门阶段的保存确认

出门阶段主要是 `begin`、首次到达某点的 `visit`、`take`、`release` 改变需要保存的记录。统一口径：**任何改变 `to_record()` 内容的事件都使 `record_revision` 加一并返回 `persist: true`**（包括 `request_return`、`commit_failed`、`commit_succeeded`、`retry_commit`、`settle_empty`、`defer_to_yard`，以及 `restore` 自己做的改写）；唯一例外是 `close`，它清空会话，返回 `persist: false`（§11）。核心先在内存中生效；宿主据此保存，再把结果告诉核心：

- 宿主每次写入时，连同 `to_record()` 记下当时的 `(trip_id, record_revision)`；写入结束后用这一对值通知核心。
- 保存成功：宿主调用 `host_persisted(trip_id, record_revision)`。
- 保存失败：宿主调用 `host_persist_failed(trip_id, record_revision)`。

核心处理确认的规则（`persisted_revision` 只在内存中）：

| 情况 | 核心行为 |
| --- | --- |
| 会话处于隔离模式（§8） | 忽略，返回 `quarantine_frozen`、`unsaved_changes = false`，不改任何状态 |
| `trip_id` 不是当前会话（旧旅程的迟到回调、会话已 `close`、当前为 `idle`） | 忽略，返回 `stale_ack`，不改任何状态 |
| `record_revision > ` 当前 `record_revision`（超前，宿主或测试出错） | 忽略，返回 `future_ack` 并记日志 |
| 成功，且 `record_revision <= persisted_revision`（乱序到达的旧成功） | 忽略 |
| 成功，其他情况 | `persisted_revision = record_revision` |
| 失败，且 `record_revision <= persisted_revision`（之后已有更新的成功写入） | 忽略 |
| 失败，其他情况 | 记录最近一次保存失败码，供 `get_view()` 显示 |

- `unsaved_changes` 由 `record_revision > persisted_revision` 推出，不单独存储；旧回调、乱序或超前通知都不能把新会话的未保存状态清掉。
- 确认通知本身**不**产生 `persist: true`，不会触发新的保存，避免无限保存循环。
- `restore` 时把读到的 `record_revision` 当作 `persisted_revision` 的初始值（它就是从磁盘读出来的）。如果 `restore` 自己改写了会话（剔除失效停留点、强制 `pending_commit` 等），`record_revision` 再加一，`unsaved_changes` 为 true，并在返回值中给出 `persist: true`。

玩家确认边界：

- 表现层可以立即显示“带上了”，因为这是玩家在当前会话里的真实选择；但**不得**显示“已收好/已保存”这类持久化成功的提示，直到对应的提交真正成功（§7 第 4 步）。
- 保存失败期间，玩家仍然可以继续走、可以回院；回院提交会再尝试一次完整保存。不做假成功。
- **诚实的限制**：如果保存持续失败、回院提交也失败，而玩家此时强制退出，重启只能读到最后一次成功保存的记录，这之后的选择会丢失。本契约不臆造额外的持久化保障；宿主是否在保存失败时给出温和提示，由宿主与表现层设计决定。
- 宿主是否合并多次待保存改动，由 §7.1 的串行队列决定；命名与接口细节列入 §10 共同冻结项。
- 回院提交事务（§7 第 3–4 步）写入的 `to_record()` 同样带有 `record_revision`。这笔事务的结果以 `commit_succeeded` / `commit_failed` 为准；宿主可以同时用候选快照里的 `(trip_id, record_revision)` 调 `host_persisted`，不调也只是 `unsaved_changes` 在之后那次保存前短暂为 true，没有风险。

### 7.3 其他要点

- **探索记录只由核心生成**：宿主只原样保存 `to_record()`，不直接改其中字段。处于隔离（`quarantine` / `quarantine_and_freeze`）时，`to_record()` 原样返回 `restore` 读到的原始记录（§8），保证冻结跨重启保持。即使第 3 步存下的会话仍是 `pending_commit`，在同代恢复的前提下（§8），恢复时发现 `trip_serial <= last_committed_trip_serial` 就会直接视为 `committed`（§8），不会二次授予。
- **幂等键用单调序号，不用集合**：宿主只需保存一个整数 `last_committed_trip_serial`，放在探索记录之外（§6）。它比保存所有已提交 ID 的集合更有界，也不会随游戏时长膨胀。
- **授予与序号同一次原子保存**：如果“发物”和“推进已提交序号”分两次写，中间崩溃就会重复发物或丢物，所以建议放进同一次 `save()`。这依赖 #149 的可靠替换（失败不删旧档）。
- **部分非法物品**：宿主回 `commit_failed(retryable=false, rejected=[...])`，核心移出失效项、`revision + 1`，仍是 `pending_commit`（§4）。`trip_id` 不变，所以仍然最多授予一次；全部失效时就成为空提案。
- **空提案永远可收**：取消、空手、`settle_empty` 都产生空提案。宿主对它不做内容校验，只推进序号；只有落盘本身失败才会失败。这是“不困住玩家”的兜底。

## 8. 恢复与降级

**前提：同代恢复**（宿主侧，#149/#150 负责）。授予状态、`last_committed_trip_serial` 和探索记录必须取自**同一份完整、校验通过的提交**；不能拼接“新库存 + 旧序号”，也不能把损坏的序号单独默认成 0。完整性校验只能发现损坏，不能证明玩家没有回滚文件。主档不可信而有可靠的上一代时，按 #149 的整份恢复策略回到上一代，并如实说明回退边界（之后未落盘或已损坏的进展不能声称已恢复）。宿主仍无法得到可信序号时，传入 `last_committed_trip_serial = -1`（`WATERMARK_UNTRUSTED`）。

现状（2026-10-03）：#149 的第一个切片 [PR #175](https://github.com/narutojzm1-dot/youjia/pull/175) 已合入，提供“启动时取有效主档，否则取备份；未提交的临时文件不提升”的整份文件恢复。它还没有代次或完整性标记，#150 的内存事务和 Web 端持久化确认也未完成。所以上面的同代前提目前只在文件层成立，`-1` 的判定条件仍待 #150 定义，不能把“文件可重读”当作序号可信的证明。

宿主加载存档后调用 `ExplorationSession.restore(record, catalog, last_committed_trip_serial)`，核心返回“恢复后状态 + 建议宿主动作 + `can_begin`”。表格**自上而下匹配，命中第一行即停**（唯一例外是“停留点已被移除”这一行：它只做清理，清理后继续匹配紧接着的 `active` 行）。序号可信时，所有 `idle` 结果的下一个序号都按 §6 规则取 `max(next_trip_serial, last_committed_trip_serial + 1)`，绝不回退；序号为 `-1` 时不分配序号。

**`can_begin` 的全局规则**：“宿主序号可信”“没有未收口的旅程”“没有被冻结的隔离旅程”是 `can_begin == true` 的必要条件；此外，下表中明确给出 `can_begin = false` 的行也不能出门。未收口指 `pending_commit` / `recoverable_failure`（含 `deferred`）；被冻结的隔离旅程指下表动作为 `quarantine_and_freeze` 的记录，在明确的恢复政策处理之前一直算作未收口，保证 §7.1 的“同一时刻最多一趟未收口旅程”。

**隔离跨重启保持**：命中 `quarantine` 或 `quarantine_and_freeze` 的会话进入只读的隔离模式，`to_record()` **原样返回读到的原始记录**（JSON 值语义等价，包括未来版本字段和非字典的原始值；Godot 解析 JSON 时数字统一为 float，不要求逐字节相同，测试按值比较），宿主的每次普通保存都把它原样写回 `exploration` 键；宿主另在 #150 隔离区保存一份原文副本和诊断信息。因此每次重启 `restore` 都会重新命中同一行，冻结不会因普通保存而解除；宿主序号恢复可信或执行明确的恢复政策后，记录才会按正常行重新判定。隔离模式下只读方法照常可用：`get_state()`、`to_record()`；`get_view()` 带 `quarantined: true` 且不含旅程细节；`get_proposal()` 返回 `{}`；`scene_identity()` 返回 `{}`。`begin` 按 §4 的优先级返回拒绝码（未来版本为 `exploration_unavailable`，冻结为 `quarantine_frozen`），其余变更方法一律返回 `quarantine_frozen`。进入隔离不改写原始数据、不递增 revision，`restore` 返回 `persist: false`；宿主仍在普通保存中原样写回原文。隔离时宿主不应发送保存确认；即使发了，`host_persisted` / `host_persist_failed` 也返回 `quarantine_frozen`、`unsaved_changes = false`，不改任何状态。

| 读到的记录 | 恢复结果 | `host_action` 与说明 |
| --- | --- | --- |
| 宿主序号为 `-1`，且探索记录存在但无法确认没有会话（不是字典、`session` 不为 null、无法解析，或 `contract_version` 比当前新） | 不改写原始数据，`can_begin = false` | `quarantine_and_freeze`：宿主原样隔离这段记录并附诊断信息；**冻结该旅程的自动提交和新旅程分配**；玩家安全在院，其他已验证的院内功能照常。既不自动重发，也不清空提案并宣称完成；补偿或丢弃属于后续明确的恢复政策（§10 第 8 项） |
| 宿主序号为 `-1` 的其余所有情况（记录缺失，或是字典且 `session == null`） | `idle`，`can_begin = false` | `freeze_new_trips`：没有可信序号就无法安全分配新序号；等宿主恢复可信序号或执行恢复政策 |
| 缺失（键不存在或为 JSON `null`） | `idle` | `none` |
| `contract_version` 比当前新 | 不解析、不改写原始数据，`can_begin = false` | `quarantine`：宿主原样保留这段数据（#150 定位置），本次不开放出门，并给出非阻断提示；其余小院功能照常 |
| 是字典且 `session == null`（元数据正常，或元数据损坏如 `next_trip_serial` 异常） | `idle` | `none`：最常见的健康空闲状态；元数据损坏时忽略它，序号按 §6 规则取值 |
| 纯夹具会话：`catalog == "fixture"`，且 `route_id` 以及 `offers`、`carried`、`proposal.items` 中所有 ID 都是 `fixture.` 前缀，其余字段校验通过 | `idle` | `quarantine_and_reset_session`：宿主隔离原文并附诊断，会话重置为 `idle`，`restore` 返回 `persist: true`（这是 restore 自己的改写，宿主应保存新的空闲记录）。只要有任何一个 `formal.` ID 或其他损坏，就不属于本行，落到下一行冻结。夹具物品永远不会被授予（§6 闸门），这份提案和它占用的序号**永久作废**，后续恢复政策不得重交，因此可以继续开始新旅程 |
| 其余损坏：不是字典、字段损坏、超预算、ID 非法、前缀不一致、`trip_id` 与序号不一致 | 不改写原始数据，`can_begin = false` | `quarantine_and_freeze`：无法判断其中是否有尚未授予的提案，所以不授予、不丢弃，隔离原文并冻结新旅程，直到明确的恢复政策处理。这是明确记录的降级，列入 #152 坏数据测试 |
| 任意状态，且 `trip_serial <= last_committed_trip_serial` | `committed` | `close`：说明上次已落盘，只是收尾前中断 |
| 路线已从目录移除（`active`） | 强制 `pending_commit`，提案包含全部已携带物；`persist: true` | `submit_proposal`：提示后回院；失效物品由宿主提交校验拒绝（§7） |
| 路线仍在，但 `current_stop` 或部分 `visited` / `offers` 的停留点已被移除（`active`） | 从 `visited` / `offers` 中剔除失效点；`current_stop` 失效时回到 `start_stop`；已携带物保留，提交时由宿主按目录校验；`persist: true`；然后按下一行继续处理 | 同下一行 |
| `active`（路线与 `current_stop` 均有效） | `active`，停在 `current_stop` | `request_return_restored`：**用户已选定（2026-10-03）安全回院**，宿主调用 `request_return(reason="restored")`，玩家回到小院，已带上的东西照常提交。核心仍保留“继续旅程”能力，但宿主默认不使用 |
| `pending_commit` | 原状态 | `submit_proposal`：自动提交同一提案 |
| `recoverable_failure` 且 `failure.retryable == true` | 原状态 | `retry_commit`：宿主先调用 `retry_commit()` 回到 `pending_commit`，再提交 |
| `recoverable_failure` 且 `failure.retryable == false` | 原状态 | `settle_empty`：提示后调用 `settle_empty()`，再提交空提案 |
| `committed`，但序号大于宿主已提交序号 | 不改写原始数据，`can_begin = false` | 动作同 `quarantine_and_freeze`。同代恢复下不应出现，说明序号与记录不同代（丢失或回退）：不重新提交（可能重复授予），也不直接关闭（可能丢失所得）。工程推荐见 §10 第 8 项 |

**隔离材料必须持久**：隔离的原文和诊断信息要在之后每次普通保存中原样保留，不能被 `sanitize_record()` 或宿主的正常保存悄悄抹掉；未来版本字段也不能被旧版本的普通保存覆盖。隔离不等于已恢复所得，界面与文档都不得这样表述。

用户于 2026-10-03 选定“安全回院并保留已带上的东西”：重启后回到熟悉的小院，不丢玩家选择，也不需要恢复院外场景状态。台账见 EXP-CONTRACT 条目。

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
| 7 | 重启时 `active` 的玩家策略 | **已由用户决定**：安全回院并保留已带物品（2026-10-03），不再待冻结 |
| 8 | 宿主已提交序号丢失、损坏或回退后的恢复政策 | **工程推荐草案**（ENGINEERING-SUPERVISOR 在 #150 提出，本稿采纳，待 CODEX-LEAD 对齐后共同冻结）：① 保存单元带版本与可校验的代次/完整性信息，授予、序号、探索记录从同一份校验通过的提交恢复；② 有可靠上一代时按 #149 整份恢复并说明回退边界；③ 仍无法判断该旅程是否已授予时，隔离原记录并冻结该旅程的自动提交与新旅程分配，玩家安全回院，其他院内功能照常；不自动重发、不清空提案宣称完成。补偿或丢弃另行制定明确的恢复政策，不作为技术默认（§8） |
| 9 | 提交的内存事务边界 | 幂等检查（绑定会话、提案身份、已确认水位）与构造候选、持久化确认、发布授予同处一段串行提交事务，本笔发布后才放行下一笔；队列只持有 `(trip_id, proposal.revision)`，宿主承担入队义务（`pending_commit` 时总有一笔当前身份的请求）；比较只用已确认持久化的序号；候选快照以宿主当前内存为底（保留院内合法未保存改动），授予与序号保存成功后才发布；所有写入经统一串行队列，写入中的新改动重排下一次写入；“失败 → 重试 → 关闭 → 重启”不丢且只授予一次（§7.1） |
| 10 | 出门阶段保存的确认接口 | `host_persisted(trip_id, record_revision)` / `host_persist_failed(trip_id, record_revision)`；旧旅程、乱序、超前通知按 §7.2 表忽略；恢复时以读到的 revision 初始化；通知不触发保存；保存失败期间保留内存状态、可回院、禁止假成功 |
| 11 | 单序号幂等的前提与整数范围 | 同一时刻最多一趟未收口旅程（`defer_to_yard` 不释放所有权；被冻结的隔离旅程也算未收口，§8 `can_begin` 规则）；`-1` 只作为传给 `restore` 的“不可信”标记，不写入记录、不参与序号分配；宿主只确认当前绑定会话的提案；序号与 revision 为 `0..2^31−1` 的 JSON 整数，`trip_id == "trip-" + serial`（§6、§7.1） |
| 12 | 隔离材料的保存位置与持久性 | #150 提供隔离区：原文 + 诊断信息，后续普通保存原样保留，`sanitize_record()` 不得清除（§8） |

## 11. 核心 API 草案（供 #152 实现，名称冻结前可调整）

```gdscript
class_name ExplorationSession extends RefCounted

const WATERMARK_UNTRUSTED := -1

static func restore(record: Variant, catalog: ExplorationCatalog, last_committed_trip_serial: int) -> Dictionary
    # last_committed_trip_serial 必须与 record 同代（§8）；不可信时传 WATERMARK_UNTRUSTED
    # → { session: ExplorationSession, host_action: String, can_begin: bool, persist: bool }
    # host_action ∈ {"none", "close", "request_return_restored", "submit_proposal", "retry_commit", "settle_empty",
    #                "quarantine", "quarantine_and_freeze", "quarantine_and_reset_session", "freeze_new_trips"}
    # 与 §8 表逐行对应；can_begin 按 §8 全局规则计算

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
func host_persisted(trip_id: String, record_revision: int) -> Dictionary
func host_persist_failed(trip_id: String, record_revision: int) -> Dictionary
    # 两者返回 {ok, error?: "stale_ack" | "future_ack", unsaved_changes: bool}，永不返回 persist: true（§7.2）

func get_state() -> String
func get_view() -> Dictionary
func get_proposal() -> Dictionary      # 没有时返回 {}
func scene_identity() -> Dictionary
func to_record() -> Variant            # 纯值，可直接 JSON；正常为 Dictionary，只有隔离模式会原样返回读到的非字典原始值（§8）
```

所有变更类方法统一返回 `{ok: bool, error?: String, state: String, persist: bool}`；例外是保存确认 `host_persisted` / `host_persist_failed`，返回 `{ok, error?, unsaved_changes}`、永不含 `persist`（§7.2）。`persist == true` 表示宿主应立即保存 `to_record()`，例如 `begin`、首次到达某点（`offers` 新增）的 `visit`、`take`、`release`、`request_return`、`settle_empty`和提交结果之后；`close` 返回 `persist: false`，其记录可与下一次任意保存合并（与 §7 一致）。

## 12. #152 隔离测试计划（独立 suite，纳入 strict daily）

1. 合法路径：出门 → 走两点 → 带一样 → 回院 → 提交成功 → 关闭；空手回；取消回。
2. 非法转换全表：每个状态下发送每个不允许的事件，断言错误码且记录字节不变。
3. 重复操作：连续 `request_return`；同一 `trip_id` 重复 `commit_succeeded`；宿主重复提交同一序号时不二次授予（用假宿主计数）。
4. 提交失败：可重试失败 → 重试成功；`defer_to_yard` → 重启 → 自动重试；不可重试且部分物品被拒 → `revision` 递增、`trip_id` 不变；不可重试且无 `rejected` → `retry_commit` 被拒、`settle_empty` 收尾；全部物品被拒 → 空提案收尾；`rejected` 与提案无交集 → `invalid_rejection` 且记录不变；可重试失败下 `settle_empty` 被拒。断言任何失败序列后都存在到达 `committed` 的路径。
5. 恢复：每个状态 `to_record` → JSON 字符串 → `restore` 往返一致；负数与超过 2^53 的 `rng_seed` 往返不变；以不同顺序访问停留点得到相同发现；SHA-256 结果第 8 字节（索引 7）≥ 0x80、即种子为负的停留点（`decode_s64(0)` 为小端序）得到与其他点不同的种子且无引擎错误输出。
6. 坏数据：非字典、缺字段、类型错、超长数组、超 4 KB、非法 ID、前缀不一致、玩家档中的 fixture 会话、未来版本、异常 `next_trip_serial`（负数、小数、超大）；断言按 §8 表得到对应的 `host_action` 与 `can_begin`、隔离原文字节不变且可以读回、不抛脚本错误。序号：记录缺失（或 `session == null` 仅元数据损坏）且 `last_committed_trip_serial = N` 时，下一趟序号必须是 N+1 且提交后真实授予（假宿主计数为 1）；含会话的损坏记录 → `quarantine_and_freeze`、`begin` 被拒；夹具会话 → 作废后可开始新旅程。
7. 目录变更：路线删除、停留点删除（含 `current_stop`）、物品删除后的恢复与提交。
8. 夹具闸门：正式入口 `begin` fixture 路线被拒；fixture 会话提交时物品全部被拒并以空提案收尾；正式目录加载不包含 `fixture.` ID。
9. 生命周期：1000 次 `begin/close` 与适配器 `bind/release`，无残留连接或对象增长。
10. 不读现实时钟：静态检查 `scripts/exploration/` 不出现 `Time.get_unix_time`、`Time.get_ticks`、`OS.get_unix_time`。
11. 假宿主故障矩阵（提交阶段）：磁盘序号为 N 时，提交 trip-N+1 首次 `save()` 失败 → 重试成功 → `close` → 重启，断言授予计数为 1、序号为 N+1；首次失败 → 不重试直接重启，断言授予计数为 0、会话仍为待提交并可再次提交成功。
12. 逐阶段保存失败 / 重启矩阵（出门阶段）：在 `begin`、首次 `visit`、`take`、`release`、`request_return` 各阶段令保存失败后重启，断言恢复到最后一次成功保存的记录、不出现“已保存”假成功、序号不回退；保存失败期间仍可 `request_return` 并在下次保存成功时完成提交。分开两种重启：`pending_commit` 提案曾经落盘（恢复后自动再提交，只授予一次）；`request_return` 本身也没落盘（只恢复到最后持久化的 `active` 或更早状态，再按用户决定安全回院，不做无依据保证）。
13. 确认通知：旧旅程的迟到确认、乱序到达的旧成功/旧失败、超前 revision，都不改变当前会话，`unsaved_changes` 不被错误清除；失败通知同样绑定会话；任何确认都不返回 `persist: true`；`restore` 后 `persisted_revision` 等于读到的 revision。
14. 序号不可信与隔离（核心侧）：`last_committed_trip_serial = -1` 时，有未关闭会话 → `quarantine_and_freeze` 且 `to_record()` 与原始记录值语义等价、`can_begin = false`；无会话 → `freeze_new_trips`；`committed` 但序号大于水位 → 隔离而不重新提交、不关闭、`can_begin = false`；`-1` 加不是字典 / 字段损坏 / 未来版本的记录都不能得到 `can_begin = true`；冻结后 `to_record()` 与原始记录值语义等价，经普通保存再重启，`can_begin` 仍为 false（分别覆盖字典与非字典原始记录）；隔离时确认通知返回 `quarantine_frozen`；拒绝码优先级与未来版本的 `exploration_unavailable`；`catalog == "fixture"` 但路线或物品为 `formal.` 前缀 → 冻结而不作废；`restore` 改写会话时 `persist: true` 且 `unsaved_changes = true`；`defer_to_yard` 后 `begin` 返回 `pending_exists`；`trip_id` 与序号不一致、序号超出 `2^31 − 1` 按损坏处理。

15. 异步提交交错（假宿主可分别控制“写入开始”和“持久化确认”的时机）：A 确认前重复提交同一 trip，A 成功后再放行 B → 只授予一次、B 在队首按新水位收尾；A 失败后重试 → 只授予一次；等待确认期间产生新照片 / 关系变化 → 成功回调不覆盖较新改动、未保存标记保留；旧提案排队期间发生内容拒绝升版 → 旧身份的请求被丢弃、只按新版本提交。A 已落盘但成功回调丢失 → 队列空闲时按入队义务兜底重新入队，在第 1 步按已确认水位收尾、不再写入。断言重启后所得恰好一次、水位正确、新院内进展保留、陈旧请求不修改当前会话。本项与平台持久化确认分别举证。

**宿主侧联合验收**（由 CODEX-LEAD 在 #149/#150 实现与举证，核心以假宿主配合；列在这里是为了两边对同一份清单冻结）：

- 同代：同一次提交的库存、序号、探索记录必须同代；分别模拟只损坏序号、只损坏探索记录、主档坏但上一代有效、两代都不可信。
- 合并：trip-N 提交失败后，院内出现新照片 / 关系变化，再重试成功——新进展不被覆盖；写入进行中再改动时按 §7.1 重排下一次写入。
- 隔离持久：隔离后连续多次自动保存再重启，隔离原文与诊断仍在；未来版本字段不被旧版本普通保存覆盖。
- 平台举证：原生平台的 rename 成功与 Web 同源持久化确认分开举证；不能只凭内存中文件可读就承诺刷新后仍在。

## 13. 交接

冻结后本文升为契约 v1，记录冻结 SHA。#152 完成后补充样例目录、失败矩阵结果和测试入口；#153 首片发布并经独立验收（#156）后，按系列计划进入贡献者共同维护阶段，重大接口或持久化变更仍统一评审。
