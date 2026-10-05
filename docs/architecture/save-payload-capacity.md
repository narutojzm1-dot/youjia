# 存档载荷容量测量（#287 STATE-SAVE-CAPACITY）

Owner：CURSOR-CLOUD；父项 #150；生产容量决策与 Host 实现归 CODEX-LEAD。本文只给测量与建议，**不冻结任何上限**。

## 基线

| 项 | 值 |
| --- | --- |
| main | `ed62f0b880973d1d92f1210413d9d5ae21776f4f`（证据里的 `repo_head` 是在其上只加本目录脚本的 `e94d5f3…`） |
| Host | PR251 head `6e47c3acaea7ab7ecee0e09a1e3634dd8c4fb62e`，`test/save_recovery_r1/` 下 `store.mjs`/`legacy_v5.mjs`/`source_decode.mjs`/`bridge.mjs`/`head.html`/`source_snapshot.gd` 由 `git show` 原样取出，未改 |
| 引擎/浏览器 | Godot 4.7.2.stable.official.ed1daf0bf；Chrome 148.0.7778.96 headless |
| 隔离 | 一次性 `/tmp` XDG（生成脚本检测 `user://` 不在 `/tmp` XDG 下即拒绝运行，且起始时主/备/临时档必须不存在）；一次性 Chromium profile；IndexedDB 只用 `youjia-recovery-test-*` 命名空间并逐个删除 |
| 结果 | `test/save_payload_budget/evidence.json`：171 项检查，157 PASS、14 FAIL（全部是“自然可达存档能被现 Host 导入”，见下） |

复跑：`bash test/save_payload_budget/run.sh`（`HOST_SHA=` 可换 Host，`OUT=` 改输出，`KEEP=1` 保留样本文件）。有任一检查失败即退出 1；失败保留，不放宽。样本生成是确定性的：两次独立运行的全部样本文件逐字节相同。

## 样本来源

- **自然样本**：真实 `SaveStore` autoload 在一次性 `user://` 中按游戏顺序调用。先 `save()` 空档，再每拍到一张就 `set_album(已收集, {新照片: 实拍})`（与 `main.gd` 一致，所以主档是 k 张、备档是 k−1 张）。拍满后再调 `set_yard_progress`/`set_animal_relationship_memory`/`set_first_fish_caught`/`set_tutorial_completed`，使主备都是满相册（`natural_full_steady`）。照片来自真实 `YardWorld` + `debug_force_rule`/`try_interact` 经 `PhotoMoment.capture` 生成，摆位沿用 `test/photo_moment_render_suite.gd`，覆盖 `ExpressionCatalog.all_ids()` 的全部 15 条拍立得规则。文件字节就是生产 `SaveFiles.commit` 写出的两空格缩进 JSON。
- **压力样本**（明确不是游戏自然可达）：以 `SaveDataCodec.defaults()` 为底，经同一 `SaveFiles.commit` 写出，再加以下之一：未知扩展字段 `x_stress_extension`（ASCII 或 CJK 填充到精确字节数）；两张未知未来规则照片（真实照片改名）；或把最大的真实照片用自身条目重复填到 `PhotoMoment.MAX_ITEMS=64`（仍通过 `sanitize`）。
- 每个样本都用 Host 的 `source_snapshot.gd capture()` 读取，结果原样交给浏览器。浏览器侧走两条路：一是直接调 `decodeSourceSnapshot`→`prepareLegacyV5` 纯函数；二是经 `head.html` 适配器调真实 `YoujiaRecoveryHostBridge.open`→`initializeLegacy`，在空的测试库上执行，并在调用前后各取一次完整 IndexedDB 快照比对。被 Godot 读取拒绝的样本，另用 Python 直接 base64 原文件构造“绕过 Godot 上限”的快照，再走一遍浏览器链路，确认 JS 侧同样拒绝。

## 自然样本（15 条规则全覆盖）

字节均为 UTF-8。“合并封装”指 `legacy_v5` 同公式（去掉夹具上限）算出的 `{schema,selected,sources:{primary,backup}}` 字节数，即保留主+备原文的真实导入体积。“投影”指 `SaveDataCodec.project(主档)` 的紧凑 JSON 字节数。

| 样本 | 照片 | 主档 | 备档 | 原文和 | 合并封装 | 投影 | Godot 读取 主/备 | 现 Host 结果 | 主/备 SHA-256 前缀 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `natural_00_empty` | 0 | 291 | — | 291 | 472 | 242 | present/absent | 接受 | `b087843db9011b56` / — |
| `natural_01_goose_horse_mount` | 1 | 17577 | 291 | 17868 | 19593 | 8462 | present/present | 接受 | `a637a6a17f92195b` / `b087843db9011b56` |
| `natural_02_llama_overcast_goose_annoyed` | 2 | 37998 | 17577 | 55575 | 60487 | 17980 | present/present | 接受 | `7b2f846e738bc506` / `a637a6a17f92195b` |
| `natural_03_llama_sun_sheep_happy` | 3 | 55300 | 37998 | 93298 | 101395 | 26222 | present/present | **拒绝**：combined legacy fixture too large | `8f65e5e2068f42fc` / `7b2f846e738bc506` |
| `natural_04_llama_sheep_cow_smirk` | 4 | 73363 | 55300 | 128663 | 139811 | 34805 | too_large/present | **拒绝**：unreadable or oversized source | `79cc7bade17f36d2` / `8f65e5e2068f42fc` |
| `natural_05` … `natural_14` | 5–14 | 91797→247918 | 73363→230668 | 165160→478586 | 179451→519959 | 43509→117670 | too_large/too_large | **拒绝**（同上） | 见 evidence |
| `natural_15_fish_first_catch` | 15 | 266072 | 247918 | 513990 | 558420 | 126282 | too_large/too_large | **拒绝**（同上） | `db0dcedcaa4839a8` / `b994a41153f4a64f` |
| `natural_full_steady` | 15 | 266132 | 266132 | 532264 | 578267 | 126333 | too_large/too_large | **拒绝**（同上） | `2128eef1fb0d159a` / `5757bcb23cbc82ff` |

结论：

- 每多一张真实照片，存档文件增加 17.2–20.4 KB（紧凑投影增加 8.2–9.5 KB）。现有 15 条规则拍满后，单份存档 266,132 B，主+备原文 532,264 B，保留原文的合并导入封装 578,267 B（JSON 转义带来约 8.6% 额外体积）。
- **现 Host 夹具预算最多只能导入有 2 张照片的自然存档。**第 3 张就出现议题要求检查的情形：主档 55,300 B、备档 37,998 B，单份都低于 64 KiB，但合并封装 101,395 B 超限。从第 4 张起，单份文件已超过 64 KiB，Godot 读取阶段就报 `too_large`。这 14 条 FAIL 保留在证据里（含完整主/备 SHA），等 Leader 定生产预算，不放宽断言。
- 即使导入成功，后续正常存档走的 `prepare` 仍受 `MAX_PAYLOAD=65536` 限制。实测把 4 张照片的真实主档（73,363 B）提交给 `prepare`，被 `bounded frozen JSON text required` 拒绝。如果改用紧凑投影，8 张照片（68,463 B）同样超限。

## 压力样本（非自然可达）

| 样本 | 构造 | 主/备字节 | 合并封装 | 现 Host 结果 |
| --- | --- | --- | --- | --- |
| `stress_single_at_limit` | 单份恰 65536 B，无备 | 65536/— | 65722 | 拒绝：combined legacy fixture too large（单份过关，包装开销使合并超限） |
| `stress_single_over_limit` | 单份 65537 B | 65537/— | 65723 | Godot `too_large`；绕过后 `noncanonical or oversized source` |
| `stress_dual_each_under_combined_over` | 两份各 40000 B | 40000/40000 | 80241 | 拒绝：combined |
| `stress_dual_fits` | 两份各 30000 B | 30000/30000 | 60241 | 接受，原文逐字节保留 |
| `stress_nonascii_single_chars_under_bytes_over` | CJK：22060 字符 / 65538 B | 65538/— | 65724 | Godot `too_large`；绕过后 `noncanonical or oversized source` |
| `stress_nonascii_dual` | CJK：两份各 11546 字符 / 34000 B | 34000/34000 | 68241 B（23333 字符） | 拒绝：combined——按 UTF-8 字节而非字符计 |
| `stress_future_rules_growth` | 2 张未知未来规则照片 | 34841/34841 | 75885 | 拒绝：combined；投影只剩 275 B |
| `stress_photomoment_dense_single` | 1 张 sanitize 合法的 64 条目照片 | 70889/70889 | 153753 | Godot `too_large`；绕过后 head 拒绝（参数 189126 字符 > 180000） |

## 现 Host 的拒绝位置（按调用顺序）

1. Godot `source_snapshot.gd read_source`：文件长度 > 65536 返回 `read_error:too_large`，而且读入前就按 `get_length()` 拒绝。`read_error` 不会被当成 absent。
2. `head.html` 适配器：`initializeLegacy` 参数不是字符串或超过 180000 字符时，抛 `legacy snapshot JSON string required`。实测只有 base64 后总长超限的绕过样本会触发。合法上限内的两份 base64 最多约 174,8xx 字符，所以这一层在 64 KiB 预算下从不先触发。
3. `bridge.initializeLegacy`：恢复结论不是 `empty` 时拒绝（`legacy import requires empty recovery`）。
4. `source_decode.mjs`：遇到 `read_error`、base64 长度 > 87384 或解码后 > 65536 B，抛 `unreadable or oversized source` 或 `noncanonical or oversized source`。
5. `legacy_v5.mjs`：单份文本 > 65536（按字符或字节，任一超即拒），合并 payload 字节 > 65536 时抛 `combined legacy fixture too large`。
6. `store.mjs envelope`：payload > 65536 B 抛 `bounded frozen JSON text required`，后续 `prepare` 也受这一条约束。

以上全部发生在 `store.initialize` 开写事务之前。逐样本断言：每个被拒样本调用前后 IndexedDB 快照完全相同，且 current/intent/archive 均不存在（`*:rejected_before_write` 与 `*:bypass_rejected_before_write` 全 PASS）。旧档文件在整轮运行后 SHA 不变（`*:source_file_untouched_*` 全 PASS）；Host 本身没有任何写旧档的接口。

**已有状态保全**（`state_preservation`，全 PASS）：

- 先合法导入 1 张照片的存档，再在 `intent_prepared_complete` 屏障处关页，留下 1 条 archive。重开后得到 `restored_parent_intent_rejected`，此时有 current 和 archive。对这个库：
  - 再调 `initializeLegacy` 被 `legacy import requires empty recovery` 拒绝；
  - 用 4 张照片的真实主档调 `prepare` 被 `bounded frozen JSON text required` 拒绝；
  - 前后快照完全相同。
- 另一页停在 `intent_prepared_complete`，持有锁，intent 处于 `prepared`。第二页直接用 `store.mjs`：`envelope(超限)` 被拒；伪造的超限 candidate 调 `submit`，0 ms 内即被 `invalid candidate` 拒绝，没有等锁；current/intent/archive 快照不变。

## 业务投影 vs 保留原文

| 样本 | 原文主档 | 投影（紧凑） | 比例 |
| --- | --- | --- | --- |
| `natural_full_steady` | 266,132 | 126,333 | 47% |
| `stress_dual_each_under_combined_over` | 40,000 | 242 | 0.6% |
| `stress_future_rules_growth` | 34,841 | 275（相册 ID 保留，2 张未知照片丢弃） | 0.8% |

Host 导入 payload 里存的是原文：每个被接受的样本都断言内嵌文本的 SHA 等于磁盘文件 SHA（`*:accepted_raw_preserved`）。投影会丢掉未知字段、未来规则照片和原始空白，体积可小两个数量级，**不能用投影替代原文来压进预算**。投影只适合用来估算后续正常存档的体积。

## 给 Leader 的预算建议（不冻结）

1. 拆成四个独立的字节上限，并相互推导：(a) 旧档单份原文读取上限，Godot `source_snapshot.gd` 与 `source_decode` 共用；(b) 合并导入封装上限，即 `legacy_v5` 与导入时的 `envelope`；(c) 后续正常存档 payload 上限，即 `prepare`/`envelope`，取决于 Godot 提交的格式；(d) head 适配器参数上限，按 (a) 推导为 `2 × ceil(a/3) × 4 + 余量`。现在四者都写死 65536 或由其推导，生产不可直接沿用。
2. 起点建议：(a) 1.5 MiB（1,572,864 B），(b) 3.5 MiB（3,670,016 B），(c) 至少 1 MiB（紧凑）或与 (a) 相同（若沿用两空格缩进），(d) 约 4.2M 字符。依据：
   - 当前自然满档单份 266 KB、合并 578 KB，余量分别约 5.9× 与 6.3×；
   - 按密集样本线性外推，15 张都塞满 64 条目的单份约 1.06 MB、合并约 2.30 MB。这是外推值，没有实测。1 MiB 单份上限会差约 1%，因此不建议用 1 MiB；
   - 每新增一条拍立得规则，合并封装约增加 37–44 KB。
3. 超限必须显式阻止，并让玩家可见，绝不删照片或截断未知字段来凑预算。冻结前应在目标低端移动浏览器上，按所选上限实测 IndexedDB 写入/回读耗时与内存。`store.mjs` 每次事务都会对完整 current/intent/archive 做 `JSON.stringify` 比较，MB 级下的开销本次没有测量。

## 剩余不确定项

- 照片体积依赖画面：本次用固定摆位，每张 15–17 个条目，上限是 64。真实游玩中同框动物更多时，单张会变大；`stress_photomoment_dense_single` 只是 sanitize 合法的上界之一，并非严格证明的最大值。
- 将来的规则、字段、`archive`（最多 32 条，每条含 parent+candidate 两份完整封套）都会放大 IndexedDB 中的实际占用。本次只量了 payload，没有量 archive 满载后的总量。
- 两空格缩进格式与浮点写法取决于 Godot 4.7.2 的 `JSON.stringify`，换引擎版本需要复测。
- 原生读取只在 Linux headless 下验证。Web 导出中 `user://`（IDBFS）上 `source_snapshot.gd` 的表现本次未测。
- `navigator.storage.estimate()` 在本 headless profile 中 quota 约 10 GiB，且每次读数都有抖动，只是观察值，不是配额保证。真实 `QuotaExceededError`、物理断电和正式迁移均**未验证**，本文也不作此声明。
