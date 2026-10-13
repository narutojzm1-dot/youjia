# #700 磨粉共享模型候选（2026-10-13）

Owner：CODEX-LEAD；Leader 内部委派。基于 main `fbf87cd5c9a05663186756ed69c7aef8a42cd8c9`。这是磨粉端到端候选的共享前置，保持 Draft，**没有开放磨盘玩法、没有 Web 体验或发布结论**。原 #700 不关闭。

## 可接入契约

- `Inventory.read()`：canonical schema5，新增 `flour` 和 `production_revision`；旧 schema1–4 只在读视图补零，首次正常写入随同事务迁移，原库存、手持、地面 ID 和 revision 保留。未知或损坏 schema 阻断。schema5 不向旧客户端降级写回。
- `Inventory.STORED` 包含面粉，`FOOD` 仍仅代表已有手持/落地/投喂能力。面粉暂不能借鱼类 fallback 拿取、落地或投喂；背篓展示、搬运资源和食谱由后续运行片接入。
- `GrowthProduction.read(snapshot)`：缺字段读空 schema1；receipt 字段为 `id/action/day/period/ap/ingredients/products/experience`，当前只接 `mill_wheat`、小麦输入、面粉输出、厨艺经验。序号必须连续，账本 revision 与库存 `production_revision` 对应；丢账、孤账或版本不匹配均阻断预算，不能把已消费 AP 重置为空。
- 原 `growth_actions` schema1 和 `pond_edging` 的配对 revision 不变。`GrowthBudget.budget()` 合并两种凭据的消耗，仍只有一个三餐 AP 池；`expected.source` 同时包含三餐、旧池岸、新生产账本。没有新的余额字段。跨日余点仍返回 `AP_CROSS_DAY_UNRESOLVED`，不自行清零、结转或补领。
- `GrowthBudget.complete_milling(snapshot, expected, proposal, config)`：`proposal` 来自现有 `plan_growth_materials()`，选择目录为 `wheat -> {id: mill_wheat, materials: {wheat: 配置数量}}`；`config` 必须恰含 `ap/wheat/flour/experience`，数字全部由调用方提供，本模型无玩法默认值或等级阈值。
- `SaveStore.request_milling(expected, proposal, config)` 深拷贝入参并排入现有 `growth` FIFO；队首复核完整预算、材料快照、留种、容量和版本。在一个 candidate 中扣麦、加面粉、库存 revision +1、生产 revision/库存锚点 +1、保存 AP 与经验凭据。`get_growth_production()` 只读已确认账本。接受 ID 不代表成功，unknown 不能重交，confirmed 后才展示成果。
- 为保留拒绝语义，`SaveCoordinator.IntentRejection` 仅追加本片实际 `AP_* / GROWTH_* / PRODUCTION_*` 白名单；没有改变排队、准备、提交、确认、重试或回执协议。未知错误字符串仍降为 `INVALID_LOCAL_INTENT`。

## 验证

Godot 4.7.2 Windows headless；每套独立 APPDATA，真实 NativeSaveHost 落盘和重载。11 套合计 **964 项、0 失败**；[摘要](summary.json)、[日志](logs/)和[被测源码 SHA256](source-files.sha256.json)保留。按仓库完成映射逐一检查日志完成行、退出码及错误；新增 suite 已登记到 daily runner 与 completion map。

| Suite | 检查数 |
| --- | ---: |
| growth_production | 130 |
| growth_budget | 74 |
| growth_materials | 77 |
| yard_inventory | 53 |
| yard_crops | 90 |
| chick_millet_model | 27 |
| yard_ground_food_ledger | 22 |
| meal_ledger | 85 |
| meal_planner | 28 |
| pond_growth_director | 292 |
| save_coordinator | 86 |

新增覆盖：schema1–4 实际旧输入和首次写入；磨粉→池岸→磨粉共享 AP；两端凭据/库存锚点和缺失凭据；库存 revision 每次只增一次；产物容量、最后麦种、材料竞态、可配置数量；旧消费和新消费相互使冻结预算过期；unknown 落地/未落地两种回执；真实 FIFO 先行写入；原生重复请求、真实文件重开不重复扣料/加粉/经验/AP；普通库存、三餐和作物写入保留面粉及凭据；实际 `commit_rejected` 保留 AP_CHANGED / PRODUCTION_LIMIT / GROWTH_CHANGED。

两处旧测试的 canonical schema 断言由4改5并增加面粉零值；旧“未来 schema5”改为未来 schema6，旧字段保全断言保留。没有删除或降低原有行为断言。

## 待后续端到端片完成

磨盘资源/位置、统一自主行为抽选、实体背篓取麦与磨盘往返/动作、面粉背篓表现、面粉食谱和搬运表现、体验与公开发布仍未完成。后续必须一次对全部可执行主材料抽选 50/50，不能让两个 director 分别抽选抢角色；抵达背篓只校验冻结 proposal，不重新随机。延用当前三餐角色占用和生产疲劳规则。

本候选不改运行调度器、Main/UI、资源、三餐食谱，也不设等级、跨日余点、补觉或连熬叠加规则。此处 headless 模型和持久化证据不能代替普通游戏/浏览器/实体手机验收。
