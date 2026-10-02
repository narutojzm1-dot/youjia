# 需求列表

这是代理认领与任务指定使用的活动列表。需求来源、决策过程与历史状态保存在 [产品决策与需求变更台账](decisions.md)；产品承诺和当前设计边界以 [游戏策划基准](game-design.md) 为准。

## 状态流转

`待产品决策` → 用户指导明确后 `待认领` → `已指定` / `进行中` → PR 打开后 `待评审` → 合入并验收后 `已完成`。

认领者通过 PR 修改本表的 Owner 与状态；Codex 确认后开始实现。未登记的 Agent-ID 不可认领；一个需求只能有一个负责人，多人协作时拆分不重叠子需求并分别分配。阻塞或方向变化要同步到本表、相关 PR 和台账。每个贡献者可处理并合入自己的 PR，但须由与实施者不同、使用独立上下文启动的子代理审阅最终 commit；评审记录是需求验收的一部分。

## 活动需求

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261002-001 | P0 | 校准角色走路速度和节奏，增加关键互动动作 | 默认速度不再停留在约 39 px/s；起步、停步和转向自然；抚摸/招呼/拿取/喂食至少有清晰动作与即时反馈；最新 Web 构建完成实际游玩复核。 | 进行中 | `CODEX-LEAD` | PR #27 提议默认行走速度约 61.4 px/s；互动动作与实玩验收仍待完成。[体验结论](playtests/2026-10-02-game-1347743.md#p0移动和互动反馈) |
| REQ-20261002-002 | P0 | 解释橙色目标提示并明确当前行动对象 | 指示准确指向目标；显示动物/地点名称与动作；键盘、HUD 和点选操作目标一致；新存档玩家无需猜它是弹窗还是菜单。 | 待验收 | `MANUS-CONTRIBUTOR` | 用户 2026-10-02 指定；[实现 PR #25](https://github.com/narutojzm1-dot/youjia/pull/25)、[候选体验记录](playtests/2026-10-02-REQ-002-target-clarity.md)、[正式构建 game-9fe0d39](https://narutojzm1-dot.github.io/youjia/)；线上版本与 PCK 哈希已核对，真实移动动物点选和手机触屏尚未实玩验收。 |
| REQ-20261002-003 | P1 | 确定长期定位与停留/回访循环，评估轻放置 | 用户明确定位选择；策划基准更新后再实现长期成长。不得在决定前加入强制日常任务、离席惩罚或离线资源损失。 | 待产品决策 | — | [策划基准的待决策问题](game-design.md#待决策问题) |
| REQ-20261002-004 | P1 | 增加大鹅和其他动物的动作、表情与互动回应；先修正大鹅始终张翅的问题 | 所有新增姿态保持同一角色的精致绘画质感；鹅在闲逛时可保留张翅个性，但安静时应收翅站立、休息时自然卧下，画作不靠变形冒充；切换接地、朝向、碰撞与相册不跳脚。其余动物还需有闲置和互动回应；最新 Web 构建复核前本条不标已完成。 | 进行中（鹅首切片已上线；其它动物仍待补） | `MANUS-CONTRIBUTOR` | [issue #33](https://github.com/narutojzm1-dot/youjia/issues/33)、[PR #34](https://github.com/narutojzm1-dot/youjia/pull/34) 和正式 `game-3e23a10` 浏览器卧姿实玩已核实；[增补决策](decisions/REQ-20261002-004.md)。REQ-001 主角步态仍由 `CODEX-LEAD` 负责。 |
| REQ-20261002-005 | P1 | 修复晴/阴天气表现，设计可辨认的季节变化 | 晴/阴使用对应场景资源且一眼可辨；季节有环境或动物行为变化，首次变化时间可接受；新增雨雪或四季资源先列方案与成本，经方向确认后制作。 | 待认领 | — | [体验结论](playtests/2026-10-02-game-1347743.md#p1天气与季节) |
| REQ-20261002-006 | P1 | 深入体验最新版本并提出大型玩法顺序 | 完成最新 Web 构建的现场复核，记录步骤、截图、构建号、发现和优先级。 | 已完成 | `CODEX-LEAD` | [game-1347743 体验记录](playtests/2026-10-02-game-1347743.md) |
| REQ-20261002-007 | P1 | 验证携鱼过期时失效投喂追踪会取消且普通散步保留 | 线上实际完成钓鱼、选择鸭/鹅并等待鱼过期；确认角色停止追踪无效目标且普通散步不受影响；记录构建和证据。 | 待验收 | `CODEX-LEAD` | [PR #19](https://github.com/narutojzm1-dot/youjia/pull/19)、[发布核查](playtests/2026-10-02-game-b82a7f5.md) |
| REQ-20261002-008 | P0 | 所有主动交互都有可感知的对象或场景正反馈；已分批补鸭鹅投鱼、抚摸与浇水 | 鸭鹅成功投鱼只对被喂鸟回应；牛/羊/马抚摸只对命中的动物回应；花圃当日首次有效浇水才显示水彩回应。距离不足、鱼过期、重复浇水均不得庆祝，低动效仍可读；羊驼喂/牵、种花/收获及其它交互继续盘点，不得提前标整条需求完成。 | 进行中（前两切片已上线） | `MANUS-CONTRIBUTOR` | [issue #30](https://github.com/narutojzm1-dot/youjia/issues/30)、[决策记录](decisions/REQ-20261002-008.md)、[投鱼 PR #32](https://github.com/narutojzm1-dot/youjia/pull/32)、[抚摸与浇水 PR #35](https://github.com/narutojzm1-dot/youjia/pull/35)；正式 `game-3e23a10` 已核对清单和 PCK。REQ-001 主角动作仍属并行工作。 |
| REQ-20261002-009 | P0 | 将可见小院细节变成可发现、可随时打断且保持精致绘画的场景交互和彩蛋 | 首批逐处验收花箱、池塘岸石和木栅栏真实画面命中、院内安全站位、键鼠/触屏/HUD 同目标、独立水彩回应；蝴蝶、蜻蜓、棚檐羽毛等无收益偶遇可在正常散步见到，无签到/任务/错过惩罚。保留钓鱼、植物和动物优先级、低动效及旧存档。叠加型草叶**不等于真正能开木门**，原背景物件替换/多热点规模化仍需单独验证。 | 进行中（花箱、岸石和栅栏三处已上线；更多热点/底图替换仍未实现） | `MANUS-CONTRIBUTOR` | [issue #36](https://github.com/narutojzm1-dot/youjia/issues/36)、[需求记录](decisions/REQ-20261002-009.md)、[背景架构](architecture/painted-yard-interactions.md)、[花箱 PR #38](https://github.com/narutojzm1-dot/youjia/pull/38)、[岸石 PR #39](https://github.com/narutojzm1-dot/youjia/pull/39)、[栅栏 PR #41](https://github.com/narutojzm1-dot/youjia/pull/41) 与正式 `game-df8b92d` 公网 PCK 校验。[PR #27](https://github.com/narutojzm1-dot/youjia/pull/27) 仍修改本表及策划基准且显示冲突；后合入方须手工整合双方状态并重新独立审核最终 SHA，不接管 REQ-001 步态代码。 |
| REQ-20261002-010 | P0 | 旅人随手拍：替换莫名镜头推近，让真实新照片形成、写当天短句并可见地收入相册 | 仅首次有效抓拍且持久保存后显出**同一张真实快照**，照片定日期与规则事件的中英短句；暂停/移动/开相册随时打断展示但不丢照片。低动效静帧，重复事件不重播；旧档无日期不伪造日期且原相册仍可看。通过实际事件、原生/浏览器画面和完整回归核验。 | 待评审（全量回归与候选 Web 实玩通过；待新主线最终 SHA 审核/发布） | `MANUS-CONTRIBUTOR` | 用户正式版试玩反馈：[issue #40](https://github.com/narutojzm1-dot/youjia/issues/40)；[摄影实现 PR #43](https://github.com/narutojzm1-dot/youjia/pull/43)；[实现边界](architecture/photo-diary-arrival.md)。这是独立于已上线栅栏 PR #41 的切片；[文档恢复 PR #42](https://github.com/narutojzm1-dot/youjia/pull/42) 已人工合并进入本分支；[PR #27](https://github.com/narutojzm1-dot/youjia/pull/27) 仍待独立集成，不接管步态。 |

## 认领约定

- PR 标题建议：`[REQ-20261002-001][GROK-CONTRIBUTOR] 改善角色移动与互动动作`。
- PR 描述中填写 `Agent-ID`、需求编号、涉及文件/子系统、验收情况和依赖 PR。
- 合入前在 PR 记录 reviewer 子代理的临时 Agent-ID、`APPROVE`/`REQUEST CHANGES`、审查的完整 commit SHA 和摘要；最终 SHA 改变时重新审查。
- 未认领前不要直接开始可能重叠的实现；Codex 负责确认负责人和集成顺序。用户也可以直接指定 Owner。
- 需求完成后，由 Codex 更新状态与合入/构建记录；本表保留需求，台账保留过程。
