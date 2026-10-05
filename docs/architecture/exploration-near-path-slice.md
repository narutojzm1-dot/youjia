# 首片近郊往返：正式游戏接入（EXP-FIRST-SLICE）

- 编号：EXP-FIRST-SLICE · [issue #153](https://github.com/narutojzm1-dot/youjia/issues/153) · Owner `CURSOR-CLOUD`
- 依据：[契约 v1](exploration-module-contract.md)、[画卷漫步形式](exploration-form-options.md)、[首条体验研究](exploration-first-experience.md)（取景、看景可进入、提篮常伴）、[回院适配研究](exploration-return-adapter.md)。用户 2026-10-05 授权独立推进。
- 证据：[体验记录](../playtests/2026-10-05-exploration-near-path-slice/README.md)。
- 表现口径：本文的横向画卷是过渡占位。用户已选“保留原画视角，沿路走动并自然换页”（[原画路径方向](exploration-painted-path-direction.md)），不再采用侧视横走；表现层由 EXP-PAINTED-PATH（PR #342）换成 02 原画沿路行走，下面的宿主、提交、恢复、提篮与容量逻辑原样复用。

## 玩家能做什么

1. 小院左下的石板路一直通到画外，那里就是出门的地方（`YardSceneHotspots.PATH_OUT`）。点那段路，或站在草地下沿靠近石板路处（`approach_points[0]` 附近 20px）按空格/行动按钮「出门走走」。花圃 60px 核心范围内空格/行动按钮始终归花圃，出门只在路口边缘那一小片与花圃外圈重叠（`YardInteraction.PATH_OUT_STANDING` / `PLANT_CORE`）。木栅栏边的观察保持原样。
2. 进入横向画卷「院外近郊」：院门外 → 小溪边 → 松树下 → 缓坡上。←→ / 按住屏幕左右半边走；靠近一处时出现「停下看看…」，空格/E 也可以。
3. 停下看总能进入；四处停留点都可能有圆石、松果或落羽，也可能什么都没有。可以带上、放回；单趟合计最多 3 件（用户 2026-10-05 决定，同名可重复）。篮子满了再遇到第 4 件时显示「换成…」，字幕写明最早带上的那件留回原处；放下与带上在 `ExplorationHost.swap` 里合成一次落盘，中途断电不会恢复成空篮。带上的东西画在左下的提篮里。
4. 随时回院：右上「回院」、R，或走回起点再往左走一会儿。回院不等写盘；文案分开：提交成功才说「…收好了」，空手说「空手走一趟也舒服」，写盘失败说「还没收好，等会儿再放一次」并在院里每 30 秒自动重试。
5. Esc 或画卷右上「歇一会儿」（触屏入口）打开暂停面板盖住画卷，画卷里的时间和输入一起停；外出期间小院不计时。回标题/再过一次假期时按宿主中断回院，带上的东西照常收下。
6. 外出途中关掉游戏：下次进院时安全回院，已带的东西照常收下，并提示一次。

## 结构

| 文件 | 职责 |
|---|---|
| `scripts/exploration/exploration_host.gd` | 核心与 SaveStore 异步存档队列之间的宿主桥：恢复动作（契约 §8）、提交步骤 0–4（§7）、回院导航不等持久化、重复回院幂等；只认自己的受理编号，确认后发布、被拒延后、未知等待 |
| `scripts/exploration/exploration_director.gd` | Main 下的外出导航：恢复、开始、创建/释放画卷、回院文案（确认后才说收好了）、院内自动重试（再被拒不打扰） |
| `scripts/exploration/near_path_scroll.gd` | 画卷表现适配器：输入 → 核心事件，核心视图 → 画面；自带相机与界面层（layer 8，在暂停层 10 之下）；`PROCESS_MODE_PAUSABLE` |
| `scripts/exploration/near_path_layout.gd` | 纯几何：停留点、取景（看景不比走路更近，竖屏留纸边） |
| `scripts/exploration/near_path_painter.gd`、`keepsake_art.gd` | **占位画面**：远山取自小院原画并在接缝处淡入（不镜像），其余为程序淡彩。正式长卷/小物交付后只替换这两个文件和布局里的锚点 |
| `autoload/save_store.gd`、`scripts/persistence/save_data_codec.gd` | 新字段 `exploration`（原样会话记录，由核心校验）、`exploration_committed_serial`（水位线；缺失为 0，损坏为 -1 = 不可信）、`keepsakes`（正式小物 → 次数，1..9999）。`request_exploration_trip` 把小物、水位线和记录放进**同一笔**排队写入：在队首按当时已确认的水位线求值，已越过就只写记录、不再授予；`commit_confirmed` 后才发布到内存 |

Main 新增屏幕状态 `exploring`：隐藏小院与 HUD、关小院输入、取消照片入册演出；回来时人站回石板路尽头，相机切回小院。

## 持久化口径

写入走 SaveStore 的异步存档队列（#336 的 `request_intent` / `commit_confirmed` / `commit_rejected` / `commit_unknown`），旧的同步 setter 已不再使用。受理只代表排进队列：

- **确认**：宿主才告诉核心已落盘、授予带回物，小院文案此时才说「收好了」。回院导航本身不等待，先显示「回到院里了」。
- **被拒**：这趟标记延后，提示「还没收好」；院内每 30 秒自动重试，重试再被拒不再弹提示。
- **结果未知**：原地等待（存档面板由 Main 统一提示），不说收好也不说没收好，期间不能再出门；查明后按确认或被拒处理。
- 回标题 / 重开 / 确认重开时先按宿主中断回院，让这趟的提交排在随后的 `flush_pending` 之前。

这仍不是 #150 / #176 的 Web 持久化验收；文案不据此承诺跨设备或浏览器存储层面的持久。

## 测试

`test/exploration_slice_suite.gd`（strict daily）：存档字段投影与清洗；提交、空手、重复回院、写盘失败保持原状与重试、重启恢复、提交后断电的水位线去重、损坏记录与不可信水位线；画卷看景/带上/放回/换（一次写盘）、出门前补提交成功先留院显示「收好了」、触屏在看景时不误走、R 只回一次、按住左走回家；Main 出门（花圃范围采样不被抢）/Esc 与触屏暂停/回院/回标题中断/重启恢复。全部用生产类；队列行为用 `test/fixtures/exploration_memory_store.gd`（生产 SaveStore 只把异步队列换成手动推进的内存队列，可注入被拒、结果未知后落地 / 未落地、同一趟两笔排队只授予一次）；Main 一节用真实 SaveStore 并等待队列清空。

## 仍待决定或交付

- 携带上限 3 为用户决定；出现权重、停留点数量与步速是实验参数，产品决定按 #146 交游戏制作人。核心用 `taken`（停留点 → 东西）记录来源，所以同名东西可以同时在篮子里，放回时回到原停留点。
- 带回的小物目前只记在存档里，院里还没有展示位置（提篮/陈列属于 #154 及后续决定）。
- 正式「02 院外近郊」画面与三件小物原画。
