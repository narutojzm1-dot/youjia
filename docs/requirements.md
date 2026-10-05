# 需求列表

这是代理认领与任务指定使用的活动列表。需求来源、决策过程与历史状态保存在 [产品决策与需求变更台账](decisions.md)；产品承诺和当前设计边界以 [游戏策划基准](game-design.md) 为准。

## 状态流转

`待产品决策` → 用户指导明确后 `待认领` → `已指定` / `进行中` → PR 打开后 `待评审` → 合入并验收后 `已完成`。

认领者通过 PR 修改本表的 Owner 与状态；Codex 确认后开始实现。未登记的 Agent-ID 不可认领；一个需求只能有一个负责人，多人协作时拆分不重叠子需求并分别分配。阻塞或方向变化要同步到本表、相关 PR 和台账。每个贡献者可处理并合入自己的 PR，但须由与实施者不同、使用独立上下文启动的子代理审阅最终 commit；评审记录是需求验收的一部分。

## 活动需求

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261002-001 | P0 | 校准角色走路速度和节奏，增加关键互动动作 | 默认速度不再停留在约 39 px/s；起步、停步和转向自然；抚摸/招呼/拿取/喂食至少有清晰动作与即时反馈；最新 Web 构建完成实际游玩复核。 | 进行中（PR #27 走速、PR #76 拿草/递草切片已发布；抚摸/招呼等动作待做） | `CODEX-LEAD` | PR #27 合入 `fce84fe`，默认参考速度约 61.4 px/s；回归、Web/Chromium 步行/停步/转向核验完成。[步态体验与发布记录](playtests/2026-10-02-REQ-001-locomotion.md)。拿草/递草由独立切片 REQ-001-GRASS 在 PR #76 完成；抚摸/招呼等仍是本需求未完成部分。 |
| REQ-20261002-002 | P0 | 解释橙色目标提示并明确当前行动对象 | 指示准确指向目标；显示动物/地点名称与动作；键盘、HUD 和点选操作目标一致；新存档玩家无需猜它是弹窗还是菜单。 | 待验收 | `MANUS-CONTRIBUTOR` | 用户 2026-10-02 指定；[实现 PR #25](https://github.com/narutojzm1-dot/youjia/pull/25)、[候选体验记录](playtests/2026-10-02-REQ-002-target-clarity.md)、[正式构建 game-9fe0d39](https://narutojzm1-dot.github.io/youjia/)；线上版本与 PCK 哈希已核对，真实移动动物点选和手机触屏尚未实玩验收。 |
| REQ-20261002-003 | P1 | 确定长期定位与停留/回访循环，评估轻放置 | 已确定轻陪伴为主、轻放置为辅；互动可以留下可感知的后续回响，缺席不造成惩罚。具体系统按 REQ-20261002-011 拆解。 | 方向已决策；系统设计进行中 | `CODEX-LEAD` | 用户 2026-10-02 确认；见[当前策划基准](game-design.md#一句话方向)与[台账](decisions.md)。 |
| REQ-20261002-004 | P1 | 增加大鹅和其他动物的动作、表情与互动回应；先修正大鹅始终张翅的问题 | 所有新增姿态保持同一角色的精致绘画质感；鹅在闲逛时可保留张翅个性，但安静时应收翅站立、休息时自然卧下，画作不靠变形冒充；切换接地、朝向、碰撞与相册不跳脚。其余动物还需有闲置和互动回应；最新 Web 构建复核前本条不标已完成。 | 进行中（鹅首切片已上线；其它动物仍待补） | `MANUS-CONTRIBUTOR` | [issue #33](https://github.com/narutojzm1-dot/youjia/issues/33)、[PR #34](https://github.com/narutojzm1-dot/youjia/pull/34) 和正式 `game-3e23a10` 浏览器卧姿实玩已核实；[增补决策](decisions/REQ-20261002-004.md)。REQ-001 主角步态仍由 `CODEX-LEAD` 负责。 |
| REQ-20261002-005 | P1 | 让时段、天空与天气可感知，并设计可辨认的季节变化 | 同一院子在早晨、正午、傍晚有可辨的光线变化；晴/阴与云层表现能被看出来，不只依赖全屏滤色；季节有环境或动物行为变化，首次变化时间可接受。新增云形、火烧云、雨雪或四季资源先列方案与成本，再制作。 | 进行中（B/C/早晨云已发布；夜里压暗已发布；待制作人看图；雨雪仍待） | CURSOR-CONTRIBUTOR-LOCAL | 阴天底图 game-165c7d4（PR #52）；季节节奏 game-70883ff（PR #55）。云带 B `game-32ff2d1`；傍晚 `game-3350c89`（PR #103）；早晨 PR #140 `game-693b311`。夜里压暗 PR #158 `game-922be64`，公网包已核对；晴天夜里偏冷 modulate，不新画。雨雪仍不做。见 [sky-cloud-plan.md](architecture/sky-cloud-plan.md)；[制作人样张](playtests/2026-10-03-REQ-005-user-accept/README.md)。 |
| REQ-20261002-006 | P1 | 深入体验最新版本并提出大型玩法顺序 | 完成最新 Web 构建的现场复核，记录步骤、截图、构建号、发现和优先级。 | 已完成 | `CODEX-LEAD` | [game-1347743 体验记录](playtests/2026-10-02-game-1347743.md) |
| REQ-20261002-007 | P1 | 验证携鱼过期时失效投喂追踪会取消且普通散步保留 | 线上实际完成钓鱼、选择鸭/鹅并等待鱼过期；确认角色停止追踪无效目标且普通散步不受影响；记录构建和证据。 | 待验收 | `CODEX-LEAD` | [PR #19](https://github.com/narutojzm1-dot/youjia/pull/19)、[发布核查](playtests/2026-10-02-game-b82a7f5.md) |
| REQ-20261002-008 | P0 | 所有主动交互都有可感知的对象或场景正反馈；已分批补鸭鹅投鱼、抚摸与浇水 | 鸭鹅成功投鱼只对被喂鸟回应；牛/羊/马抚摸只对命中的动物回应；花圃当日首次有效浇水才显示水彩回应。距离不足、鱼过期、重复浇水均不得庆祝，低动效仍可读；羊驼喂/牵、种花/收获及其它交互继续盘点，不得提前标整条需求完成。 | 进行中（前两切片已上线） | `MANUS-CONTRIBUTOR` | [issue #30](https://github.com/narutojzm1-dot/youjia/issues/30)、[决策记录](decisions/REQ-20261002-008.md)、[投鱼 PR #32](https://github.com/narutojzm1-dot/youjia/pull/32)、[抚摸与浇水 PR #35](https://github.com/narutojzm1-dot/youjia/pull/35)；正式 `game-3e23a10` 已核对清单和 PCK。REQ-001 主角动作仍属并行工作。 |
| REQ-20261002-009 | P0 | 将可见小院细节变成可发现、可随时打断且保持精致绘画的场景交互和彩蛋 | 首批逐处验收花箱、池塘岸石和木栅栏真实画面命中、院内安全站位、键鼠/触屏/HUD 同目标、独立水彩回应；蝴蝶、蜻蜓、棚檐羽毛等无收益偶遇可在正常散步见到，无签到/任务/错过惩罚。保留钓鱼、植物和动物优先级、低动效及旧存档。叠加型草叶**不等于真正能开木门**，原背景物件替换/多热点规模化仍需单独验证。 | 进行中（花箱、岸石和栅栏三处已上线；更多热点/底图替换仍未实现） | `MANUS-CONTRIBUTOR` | [issue #36](https://github.com/narutojzm1-dot/youjia/issues/36)、[需求记录](decisions/REQ-20261002-009.md)、[背景架构](architecture/painted-yard-interactions.md)、[PR #38](https://github.com/narutojzm1-dot/youjia/pull/38)、[#39](https://github.com/narutojzm1-dot/youjia/pull/39)、[#41](https://github.com/narutojzm1-dot/youjia/pull/41) 与正式 `game-df8b92d` 公网 PCK 校验。REQ-001 走速切片已在 PR #27 合入发布；其互动动作继续独立推进。 |
| REQ-20261002-010 | P0 | 旅人随手拍：替换莫名镜头推近，让真实新照片形成、写当天短句并可见地收入相册 | 仅首次有效抓拍且持久保存后显出**同一张真实快照**，照片定日期与规则事件的中英短句；暂停/移动/开相册随时打断展示但不丢照片。低动效静帧，重复事件不重播；旧档无日期不伪造日期且原相册仍可看。通过实际事件、原生/浏览器画面和完整回归核验。 | 已合入；正式发布工作流成功，待公网体验复核 | `MANUS-CONTRIBUTOR` | 用户正式版试玩反馈：[issue #40](https://github.com/narutojzm1-dot/youjia/issues/40)；[摄影实现 PR #43](https://github.com/narutojzm1-dot/youjia/pull/43) 于 2026-10-02 合入 `main`；验证和 Pages 工作流成功，公网体验待记录。 |
| REQ-010-SUBTLE | P0 | 留影固定显影并原位淡出，移除飞行缩放与收尾按钮弹跳 | 真实照片保持中心位置与完整大小；原位淡入淡出；保存先于展示；暂停/移动/相册可中断且不丢照片；低动效可读；最新主线回归、Web 实际抓拍与最终 SHA 独立审核通过。 | 已发布；game-562ad5d 清单与 PCK 已核对 | `CODEX-LEAD` | 父 REQ-010 的历史归属保持 MANUS；[PR #102](https://github.com/narutojzm1-dot/youjia/pull/102)、[决策](decisions/REQ-010-photo-arrival-subtle.md)、[体验](playtests/2026-10-03-REQ-010-photo-arrival-subtle.md)。 |
| REQ-20261002-011 | P1 | 让玩家互动在之后留下轻微、可感知的世界回响与后续故事 | 以稀疏、可解释的动物关系记忆产生可观察的相处变化；关系因真实共同经历改变并兼容旧档，不做显眼数值任务或缺席衰退，保留随机性。先完成已获产品确认的鹅—羊驼切片，再依据试玩决定是否扩展，不建设通用剧情引擎。 | 已发布；公网清单与 PCK 已核对 | `CODEX-LEAD` | 制作人于 2026-10-03 确认“玩家牵引羊驼靠近大鹅、双方安静共处后留下记忆”。[PR #71](https://github.com/narutojzm1-dot/youjia/pull/71) 独立审查批准最终 SHA `219ed34d5299aeaa0e8eff53ec2f6e7f7683d045` 并合入 `main`（merge `6dacd879ea0a2bac724ecfd548779e5d40c44308`）；[Actions 37090111095](https://github.com/narutojzm1-dot/youjia/actions/runs/37090111095) 成功。Pages 清单指向 `game-6dacd87` / source commit `6dacd879ea0a2bac724ecfd548779e5d40c44308`；公网 PCK 12,783,108 字节，SHA-256 `96be444adf13de8d87cb374b0abccf1ac2998f28e7ad8978d4d85c5759fbf29c`。该片复用现有画作，无新资源依赖；#56 的鹅马行为仍仅是提案，未获产品确认。[issue #45](https://github.com/narutojzm1-dot/youjia/issues/45)、[#56](https://github.com/narutojzm1-dot/youjia/issues/56)。 |
| REQ-20261002-012 | P1 | 让熟悉的小院随时段天空和玩家构图反复呈现新意 | 同一场景通过晨/午/晚光线、云形与天气、树水细节和偶发趣事支持反复观看；摄影探索玩家选择角度、前景和画面关系的可能性。可研究轻量场内摄影演出：主人静坐时，动物事件从远景进入、经主人视角跟随后聚焦近景并留下照片。先验证美术方案、操作可读性、资源成本与 Web 性能；汽水瓶仅为构图例子，不预设具体道具或 UI。保留安静停留和随机探索，不加入打卡/集齐目标。 | 进行中（切片 C 已发布；D 延后；待制作人看抬头） | CURSOR-CONTRIBUTOR-LOCAL | [issue #48](https://github.com/narutojzm1-dot/youjia/issues/48)；切片顺序见 [architecture/familiar-yard-observation.md](architecture/familiar-yard-observation.md)。A 云带 `game-31316aa`；B 树叶 `GROK-BUILD` PR #85；C 安静抬头微推已发布 `game-6a20cdc`（PR #88/#94，Actions [37100630995](https://github.com/narutojzm1-dot/youjia/actions/runs/37100630995)），见[体验记录](playtests/2026-10-03-REQ-012-quiet-sky-look.md)。D 仍延后。制作人验收入口见 [decisions.md 待制作人验收](decisions.md#待制作人验收)。 |
| REQ-012-STAY | P1 | 站在栅栏边时，用已有草叶画让院子轻轻动一下 | 停住约 2.5 秒才播一次现成草叶，走路立刻停；不新增提示、相册或美术；不改云带速度，不改羽毛偶遇。 | 已合入（无界面测试通过；无网页实玩） | `GROK-BUILD` | 父需求 REQ-20261002-012 的 Owner 仍是 `CURSOR-CONTRIBUTOR-LOCAL`。[PR #85](https://github.com/narutojzm1-dot/youjia/pull/85) 合并 `36fa443`。记录见 [playtests/2026-10-03-REQ-012-STAY.md](playtests/2026-10-03-REQ-012-STAY.md)。 |
| REQ-20261002-013 | P0 | 真实可拍动物偶遇、稳定的有限题词与可翻旅人手账 | 大鹅完整卧姿、两羊靠近、池边鸭鹅须实际可见并真实入镜；题词只在首次成片保存变体，旧照不改写、中英切换和重开稳定；宽屏双页、手机单页，按钮/左右键/触摸翻页可靠。只浏览已拍记忆，无锁定槽、红点或完成率。 | 已发布；用户正式版试玩待反馈 | `MANUS-CONTRIBUTOR` | [PR #53](https://github.com/narutojzm1-dot/youjia/pull/53) 合并提交 `b560dec94f08a1597e2b834e74c41841893ba36b`；[Actions 37025345857](https://github.com/narutojzm1-dot/youjia/actions/runs/37025345857) 成功；正式 `game-b560dec` Pages PCK 12,776,620 字节，SHA-256 `e5b9c3f931b957ac4dd288e1c6786f6b9fc1d9ace946eac711e3bed723ac3d58` 已从公网核验；[体验记录](playtests/2026-10-02-REQ-013-scrapbook.md)。与 REQ-011 世界回响及 REQ-012 天空/自由构图分离。 |
| REQ-20261002-014 | P1 | 实现“大鹅骑上马背扑腾翅膀”场内摄影演出切片 | 玩家在院内停留观察时，满足温和空间与节奏条件后触发；演出包含远景、旅人第一视角感镜头、鹅马近景和扑翼；移动可立即打断；结束拍摄真实现场并保存稳定中英题词，可从相册回看；不重复刷取、不影响旧档、低动效可读。 | 已合入发布；自然触发实玩待补 | `CODEX-LEAD` | PR #65 最终 SHA `f7f2d0686753f798055809ef23c465d9fc237b0c` 经独立审查 APPROVE，合入 `521e6c2180284ab80aa914ec78e0ed513af960ed`；PR #72 验证补丁已并入 #65 后关闭。Actions [37092968010](https://github.com/narutojzm1-dot/youjia/actions/runs/37092968010) 成功；Pages `game-521e6c2` 对应源提交 `521e6c2180284ab80aa914ec78e0ed513af960ed`，公网 PCK 13,742,972 字节，SHA-256 `d46351fbac8d1bbe3d11de110cdbe8001a7cb805bbae07b40e16ffe97be54c1a`。公网 Chromium 1280×720 加载成功、无脚本错误或请求失败。自然等待未观察到完整演出；此为历史占位证据；PR #173已接入两帧成品画，当前组合验收见[issue #180](https://github.com/narutojzm1-dot/youjia/issues/180)。历史资源见 [issue #64](https://github.com/narutojzm1-dot/youjia/issues/64) 和[验收记录](playtests/2026-10-03-REQ-014-verification.md)。 |
| REQ-20261002-015 | P1 | 为大鹅骑马抓拍补一张完整的乘骑扑翼画 | 规格写清脚必须踩在马背上、不能用站立鹅冒充、画布/锚点/朝向/体积上限；画切片只交付成品 PNG 与运行时注册，不改演出脚本。 | 资源及导演接线已合入；最终SHA后置复审已通过；组合验收代码推导记录已产出（见 issue #180 评论与 docs/playtests/2026-10-05-REQ-015-acceptance.md），运行时Web证据仍待补，#180 保持开放 | `GROK-BUILD`（规格切片）／`WORKBUDDY-CONTRIBUTOR`（成品画切片） | 规格见 [architecture/goose-mount-pose-spec.md](architecture/goose-mount-pose-spec.md)。PR #65 已把临时换帧接到 `show_goose_encounter_cel`。产品已于 2026-10-03 确认「两张交替」而非一张：`WORKBUDDY-CONTRIBUTOR` 交付 `goose_riding_up`/`goose_riding_down` 两帧成品画（1254×1254、脚底锚点对齐后残余 ≤0.5px、`native_facing=1`、均小于 `goose.png` 的 1,212,584 字节上限），并在 `cast_art.gd` 暴露 `riding_up`/`riding_down`。导演接线仍属 REQ-014 / `CODEX-LEAD`，本切片不改 `yard_world.gd`／`FeltActor`。**PR #99 已于 2026-10-03 合并**（merge `5b695043`，head `f2d2fc21`，三轮独立评审终轮 APPROVE 无阻塞）：两帧已在 main，`cast_art.gd` 已注册 `riding_up`/`riding_down`，可被引擎直接取用；导演接线已由 `WORKBUDDY-CONTRIBUTOR` 于 2026-10-03 跨越切片边界实施（用户明确授权）：[PR #173](https://github.com/narutojzm1-dot/youjia/pull/173) 将 `yard_world.gd` 鹅马乘骑演出的 `show_goose_encounter_cel` 帧交替由占位 `idle`/`calm` 改为真正的 `riding_up`/`riding_down`，沿用既有 0.28s 扑翼时钟与低动效定帧，资源/接线历史单#64已关闭；最终完整SHA `0066cef9da621530d05d5ad8051be684512ce88c` 后置独立复审已通过（reviewer `CODEX-LEAD-ASSISTANT-REVIEW-PR-173-FINAL`，[证据](https://github.com/narutojzm1-dot/youjia/pull/173#issuecomment-5971467561)），不追认原始合入门禁；组合Web验收仍由[issue #180](https://github.com/narutojzm1-dot/youjia/issues/180)跟踪，Owner保持WORKBUDDY-CONTRIBUTOR。 |
| REQ-20261002-016 | P0 | 为旅人递草喂羊驼设计第一组可读互动动作规格 | 盘点现有旅人图集；提交递草前、递出、羊驼接收、收回手臂的动作分镜和锚点/时长/打断/低动效/Web 体积规格；不改玩法逻辑、不制作最终帧，待产品确认后再另开实现任务。 | 待产品确认（规格已提交；动作候选已在 main） | `GROK-BUILD` | 原表写成 `GROK-CONTRIBUTOR`。用户让 Grok Build 做这项指定，故改为 `GROK-BUILD`，不代表接管 GROK BOT 的其他事项。规格见 [architecture/resident-grass-offer-spec.md](architecture/resident-grass-offer-spec.md)。帧已由 REQ-001-GRASS / PR #76 先合入，本需求不另做第二套画。[issue #70](https://github.com/narutojzm1-dot/youjia/issues/70)。 |

| REQ-20261003-001-ACTION | P0 | 为招呼/抚摸成功反馈拆分旅人短动作切片提案 | 盘点现有旅人帧与成功/取消路径，提交短时、可打断、低动效/Web 可读的动作方案；不改距离判定和行为语义，不新增关系值/任务；资源方向先由产品确认。 | 待产品确认 | `未认领` | [issue #84](https://github.com/narutojzm1-dot/youjia/issues/84)。独立于已发布的拿草/递草 [REQ-001-GRASS](#req-001-grass) 与动物回应 REQ-008；确认后开放认领。 |
| REQ-20261003-017 | P2 | 低动效下花圃、水面涟漪和咬钩浮标保持静止可读 | 开启低动效时嫩芽不左右倾、开花不摇不闪、收获花瓣停在原地、水面只留一圈静止涟漪、咬钩浮标保持红色稳圈而不是快速闪烁；关闭低动效时原有轻摇、三圈涟漪和咬钩明暗仍在。不改钓鱼规则、存档或新资源。 | 已合入发布；正式试玩待反馈 | `GROK-CONTRIBUTOR` | 用户 2026-10-03 让 GROK-CONTRIBUTOR 自选无主切片。不改 REQ-001 抚摸/招呼、REQ-005/012 云带、REQ-008/009 动物与热点、REQ-014/015 鹅马。原绘制提交随 [PR #104](https://github.com/narutojzm1-dot/youjia/pull/104) 集成，兼容验证归下方 REQ-017-VERIFY；首次正式版本 `game-1949dc4` 已核验。 |
| REQ-001-GRASS | P0 | 主角拿草与递草身体动作 | 定稿居民完整帧、固定脚底；成功才演出，移动和低动效可打断；不延迟库存或喂食；实际 Web 复核。 | 已完成（独立切片已发布） | `CODEX-LEAD-ASSISTANT` | [issue #73](https://github.com/narutojzm1-dot/youjia/issues/73)；父 REQ-20261002-001 Owner 保留。仅 Vacationer / SequenceResident、动作帧、独立验证；YardWorld 既有喂草调用只传入对象位置。[PR #76](https://github.com/narutojzm1-dot/youjia/pull/76) 合入 `6c1d6f0`；独立审核和全量回归通过，正式 `game-6c1d6f0` 公网版本与 PCK 已核验；Web 正常拿草/喂草成片及受控完整动作复核。父需求的抚摸/招呼仍待做。[验收记录](playtests/2026-10-03-REQ-001-grass-actions.md)。 |

## REQ-014 协作验证切片

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261002-014-VERIFY | P0 | 对鹅马摄影候选补充验证并修复提前入册、中断恢复、落点、缩放及遮挡缺陷 | Godot 4.7.2 完整日常回归、专用演出回归及候选 Web 画面核查通过；记录实际证据和剩余美术限制。 | 已并入 #65 并发布 | `CODEX-LEAD-ASSISTANT` | PR #65 最终 SHA 经独立审查批准；Actions 37092968010 与公网 PCK 已核验。子切片仅验证缺陷修复，不接管父需求；正式乘骑资源仍属 REQ-015 / issue #64。 |

## 认领约定

- PR 标题建议：`[REQ-20261002-001][GROK-CONTRIBUTOR] 改善角色移动与互动动作`。
- PR 描述中填写 `Agent-ID`、需求编号、涉及文件/子系统、验收情况和依赖 PR。
- 合入前在 PR 记录 reviewer 子代理的临时 Agent-ID、`APPROVE`/`REQUEST CHANGES`、审查的完整 commit SHA 和摘要；最终 SHA 改变时重新审查。
- 未认领前不要直接开始可能重叠的实现；Codex 负责确认负责人和集成顺序。用户也可以直接指定 Owner。
- 需求完成后，由 Codex 更新状态与合入/构建记录；本表保留需求，台账保留过程。


## REQ-017 协作验证切片

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261003-017-VERIFY | P1 | 集成 PR #93，并修复低动效设置改写历史照片及独立脚本编译失败 | 拍摄时保存道具低动效状态，旧快照保留原普通相位；标准照片测试、全量回归、原生及 Web 真渲染通过；独立最终 SHA 审查 | 已完成并发布核验 | `CODEX-LEAD-ASSISTANT` | [PR #93 范围登记](https://github.com/narutojzm1-dot/youjia/pull/93#issuecomment-5966854032)；父 REQ-017 Owner 保留 `GROK-CONTRIBUTOR`，原提交完整保留。PR #104 最终 SHA 独立 APPROVE；Actions 37108000038 / Pages 37108145912 成功，首次公网 `game-1949dc4` 清单、PCK与浏览器核验通过；[验收记录](playtests/2026-10-03-REQ-017-integration.md)。不改钓鱼规则。 |


## REQ-015 候选资源验证切片

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261002-015-VERIFY | P1 | 对 PR99 两帧乘骑画补原生导入、运行时注册/照片兼容与受控Web证据 | 精确候选的Godot导入与两帧显示、照片JSON保留及候选导出通过；区分本地/受控和正式演出/发布 | 候选引擎验证完成；父项待集成 | `CODEX-LEAD-ASSISTANT` | 成品画仍归WORKBUDDY、规格归GROK-BUILD、导演接线归CODEX-LEAD；不改原分支，不接管父需求。[验收记录](playtests/2026-10-03-REQ-015-verify.md)。 |

## 追加切片

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261003-018 | P2 | 低动效下橙色目标光圈和钓到庆祝环保持静止可读 | 开启低动效时目标脚底光圈半径固定、钓到后的金环停在中等大小且没有向外飞的碎点；关闭低动效时原有呼吸光圈、扩散环和碎点仍在。不改钓鱼时长、目标选择或存档。 | 已发布；game-26c93c8 核验通过 | `GROK-CONTRIBUTOR` | 用户 2026-10-03 让 GROK-CONTRIBUTOR 继续自选无主切片。不改 REQ-017 的花圃/涟漪/浮标，不改 REQ-002 的目标文案，不改 REQ-015 乘骑画。只动 `WorldEffectsOverlay` 的绘制相位。[PR #108](https://github.com/narutojzm1-dot/youjia/pull/108) 最终 SHA 独立批准；Actions/Pages/公开 PCK 已核对。[集成与发布证据](playtests/2026-10-03-REQ-018-integration.md)。 |
| REQ-20261003-019 | P2 | 低动效下橙色目标指示的明暗脉动保持静止可读 | 开启低动效时目标脚底光圈与头顶弧的明暗不再随时间脉动，固定为可读亮度；关闭低动效时原有 0.75–1.0 脉动仍在。不改目标选择、距离衰减、钓鱼或乘骑画。 | 已发布；game-664dfde 公开清单/PCK核验通过 | `GROK-CONTRIBUTOR` | 用户 2026-10-03 让 GROK-CONTRIBUTOR 继续自选无主切片。补上 REQ-018 决策明确未覆盖的目标明暗脉动。不改 REQ-015/#99 乘骑资源，不改 REQ-001/005/012。只动 `WorldEffectsOverlay`：`celebration_pose.alpha_pulse` 与绘制时抵消 YardWorld 仍写入的脉动；不改 `yard_world.gd`、乘骑资源或目标选择。 |
| REQ-20261003-020 | P2 | 低动效下草堆亮度保持稳定 | 开启低动效时草堆不再一明一暗；人站在旁边时维持略亮，走开后是普通白色。关闭低动效时原来的呼吸亮度还在。不改拿草、库存或走路。 | 待评审 | `GROK-BUILD` | 活动表没有待认领行。不改 REQ-019 的目标明暗，不改 REQ-001-GRASS 的拿草动作，不改 REQ-015 乘骑画。只停 `YardWorld` 里草堆的亮度闪动。 |
| REQ-20261003-021 | P1 | 补一组动物休息画和路旁小植物 | 鸭休息时用理羽画，马休息时用甩尾画，牛休息时用嚼草画，羊休息时用抖毛画；人在南边小路停住一会儿，会看到一只蜗牛和一株三叶草。走动就收起。不改乘骑演出，不改拿草，不新增任务或相册。 | 待评审 | `GROK-BUILD` | 用户要求用画图补互动资源。父需求 REQ-004 的 Owner 仍是 `MANUS-CONTRIBUTOR`，REQ-009 的 Owner 仍是 `MANUS-CONTRIBUTOR`。本行只加这六张新画和对应的休息/停留显示。不改 PR #99 的乘骑画。 |


## REQ-015 最终合入门禁

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261002-015-GATE | P1 | 核对 PR #99 同步 main 后的最终 SHA 与资源集成门禁 | 独立审查精确 head、实际引擎导入/回归；阻断写明复现、修复和新 SHA 重验要求 | 历史失败已被后续PR99资源修复/合入解决；导演接线与正式演出待做 | `CODEX-LEAD` | 旧head `1620c2abffab3d087a08472d080df39f32c48b75`失败保留为历史；PR99最终f2d2fc2已合入5b695043，资源注册已被后续严格主线回归覆盖；不表示导演已用乘骑帧。成品仍归 WORKBUDDY，规格归 GROK-BUILD，导演归 REQ014。[记录](playtests/2026-10-03-REQ-015-final-gate.md)。 |


## REQ-019 集成验证

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-019-VERIFY | P1 | 保留 PR113 并恢复标准回归入口可执行权限，补实际目标像素证据 | 标准全量回归、正常Web及真实YardWorld输入绘制通过；独立最终SHA审核后方可合入发布 | 已完成；独立审查、发布与公网核验通过 | `CODEX-LEAD` | 功能Owner保持GROK-CONTRIBUTOR；PR99由ASSISTANT验收，不重复。[验收](playtests/2026-10-03-REQ-019-integration.md)。 |


## 制作人指定：互动动作资源订单

资源制作全部指定给 `GROK-BUILD`；行为/接入保持父项原Owner。订单与节奏见[制作清单](art/interaction-resource-orders.md)。PR118/#117休息画沿用，不重复制作；PR99仍归WORKBUDDY。

| 编号 | 优先级 | 资源交付 | 验收条件 | 状态 | Owner | 依赖 / issue |
| --- | --- | --- | --- | --- | --- | --- |
| ART-ACK-COW | P0 | 牛：成功互动后的抬眼与温和回应 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 样张已交；成功抚摸已接上抬眼，其它互动未接 | `GROK-BUILD` | [#119](https://github.com/narutojzm1-dot/youjia/issues/119)；#30 的行为接入原属 MANUS。制作人于 2026-10-03 让 `GROK-BUILD` 接手未完成部分。候选仍在 `art/concepts/ack_cow_v1/`。 |
| ART-ACK-HORSE | P1 | 马：注意玩家与接受轻抚的回应 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 样张已交；未接入 | `GROK-BUILD` | [#120](https://github.com/narutojzm1-dot/youjia/issues/120)；候选在 `art/concepts/ack_horse_v1/`。#30 的行为映射仍未改。 |
| ART-ACK-SHEEP | P1 | 两只羊：保留个性的互动回应 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 样张已交；未接入 | `GROK-BUILD` | [#121](https://github.com/narutojzm1-dot/youjia/issues/121)；两张候选在 `art/concepts/ack_sheep_v1/`。#30 的行为映射仍未改。 |
| ART-ACK-BIRDS | P1 | 鸭与鹅：自然关注和接食姿态资源 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 已指定；排队；鹅先复用盘点再作画 | `GROK-BUILD` | [#122](https://github.com/narutojzm1-dot/youjia/issues/122)；#30 / MANUS反馈映射接入 |
| ART-RESIDENT-PET | P1 | 旅人：自然轻抚动作的三姿态样张 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 已指定；可先制作三姿态分镜样张；产品核对后烘最终帧 | `GROK-BUILD` | [#123](https://github.com/narutojzm1-dot/youjia/issues/123)；#84 / CODEX主角接入 |


## 扩大旅人可走范围

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-WALK-EXPAND | P1 | 扩大院内连通可走空间，分离玩家与动物安全边界 | 标定真实落脚/禁行/遮挡，原区域可达；统一键鼠触屏/路径/追踪与牵引，镜头/透视自然；方案核对后独立实现并完整回归/Web验收 | 已指定；区域标定与技术设计待做，未实现 | `CODEX-LEAD` | [#125](https://github.com/narutojzm1-dot/youjia/issues/125)；[分期计划](architecture/player-walk-area-expansion.md)，不直接扩大动物作息区。 |
| ART-GROUND-EXPAND | P1 | 扩展候选地面的资源盘点与补绘提案 | 现画可用则不重画；补绘同院子晴阴坐标/遮挡一致、来源锚点与预算齐全，具体方案确认后制作 | 已指定；先盘点，最终补绘依赖区域确认 | `GROK-BUILD` | [#126](https://github.com/narutojzm1-dot/youjia/issues/126)；依赖REQ-WALK-EXPAND，协调#51 CURSOR天气底图，不抢动物资源订单。 |


## 工程门禁：异常退出不得当作验证通过

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| VERIFY-EXIT-GATE | P0 | 修复每日Godot回归忽略非零退出码的发布门禁漏洞 | Godot/timeout和tee任一非零、错误/FAIL日志或日志读取失败均阻断；11项故障注入与严格完整回归、独立最终SHA审查通过 | 已合入并核验发布；PR134独立审查批准、主线严格回归/导出/Pages与公开包一致性通过 | `CODEX-LEAD` | [工程督导#130](https://github.com/narutojzm1-dot/youjia/issues/130)；不包含存档协议、完成标记或PR验证workflow。[证据](playtests/2026-10-03-verify-exit-gate.md)。 |


## 追加切片（低动效对象反馈）

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261003-022 | P2 | 低动效下抚摸/浇水/投喂对象反馈保持静止可读 | 开启低动效时水彩心、浇水溅与投喂鸟环心在反馈窗口内不再上浮或中途淡出，固定为可读静帧，倒计时结束仍整段消失；关闭低动效时原有上浮、扩散与淡出仍在。不改互动判定、存档、草堆亮度或乘骑资源。 | 已发布；game-2cd15c2，独立审核/主线严格回归/Web/公开包核验通过 | `GROK-CONTRIBUTOR` | 用户半小时推进自选切片。不改 REQ-017/018/019 已覆盖相位，不改 REQ-020 草堆，不改 PR #99 乘骑画。只动 `WorldEffectsOverlay`；`still_object_feedback_suite.gd` 验收；CODEX-LEAD按PR136交接补标准daily挂载、完整/Web验收与独立最终SHA审查；实现Owner保持GROK。决策见 [decisions/REQ-20261003-022.md](decisions/REQ-20261003-022.md)。 |


## 贡献者的用户决策与展示汇总

| 编号 | 范围 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- |
| COLLAB-PRODUCER-HANDOFF | 所有贡献者把需要用户决策或查看的内容提交仓库；CODEX-LEAD、督导或GAME-PRODUCER汇总告知并回写用户决定 | 制作人已明确；统一上报规范已记录 | `CODEX-LEAD` | [通知#146](https://github.com/narutojzm1-dot/youjia/issues/146)，[交接规范](collaboration/producer-decision-handoff.md)；不改变Owner/审核流程或用户重要产品决策权。 |


## 小院成长与外出探索系列计划

用户明确要求按GAME-PRODUCER总纲安排系列计划，并指定CURSOR-CLOUD独立承担探索核心。[系列计划](architecture/yard-growth-delivery-plan.md)与[边界草案](architecture/exploration-boundary-contract.md)；方向提案仍见#142/PR143，三项产品选择不冒充已批准。

| 编号 | 优先级 | 当前可做范围与验收 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- |
| STATE-SAVE-RECOVERY | P0 | 存档提交/恢复，真实失败注入与旧v5/照片/平台持久化不丢进展 | 文件恢复首片已发布（PR #175）；Web持久化确认/内存事务仍未完成 | `CODEX-LEAD` | [#149](https://github.com/narutojzm1-dot/youjia/issues/149)；依赖/正式内容门禁见工单。 |
| STATE-YARD-GROWTH | P1 | 物品/布置/探索结果共享契约与迁移/去重提交矩阵，先设计 | PR251新6e47c3acaea7ab7ecee0e09a1e3634dd8c4fb62e initializeLegacy接桥接/JSON回调，独审5408479637，16入口/8双页恢复/139通过；Cloud被测9b627完整109矩阵通过，9b→6e仅注释等价，Leader1505985396584与Cloud1505985493507已明确接收实测9b/最终6e注释等价，兼容接收闭环；正式迁移未完成；Cloud261最终98d518274c469c9dd2057c450b95634df4077911独立审合入3956afb，测试侧239已验收关闭/Owner接收，14矩阵含自检109检查仅隔离组合，正式Host/R4仍待，未正式接入/联合冻结 | `CODEX-LEAD` | [#150](https://github.com/narutojzm1-dot/youjia/issues/150)；依赖/正式内容门禁见工单。 |
| EXP-CONTRACT | P1 | 独立探索边界/快照/宿主确认/失败恢复契约，与共享状态对齐 | 纯核心已按设计稿实现（2026-10-05 授权独立推进，不再以联合冻结为前置）；依赖 #150 的项（平台持久化结果未知、物品身份/共享区）仍未冻结，归 CODEX-LEAD | `CURSOR-CLOUD` | [#151](https://github.com/narutojzm1-dot/youjia/issues/151)；[契约设计稿](architecture/exploration-module-contract.md)，与#150待共同冻结项列于其第10节；不含正式地点/物品/形式。 |
| EXP-CORE | P1 | 形态无关核心状态机/恢复/返回，严格隔离测试；夹具不正式发布 | 进行中：用户 2026-10-05 授权 CURSOR-CLOUD 独立推进、不再以契约冻结为前置；核心与正式近郊目录随 `scripts/exploration/` 合入 main，隔离 suite 纳入 strict daily；PR176 草案由此取代 | `CURSOR-CLOUD` | [#152](https://github.com/narutojzm1-dot/youjia/issues/152)；依赖/正式内容门禁见工单。 |
| EXP-FIRST-SLICE | P1 | 确认的一条近郊往返，空手/取消/重复提交/键鼠触屏低动效与正式发布闭环 | 进行中（用户 2026-10-05 授权独立推进）：计划在后续 PR 接入正式游戏内画卷往返及基于现有 SaveStore 文件提交的探索记录/带回物（不等于 #150/Web 持久化验收），画面为可替换占位；各分片原画未入仓，横卷/单页串联待 #155 选择；正式构图/资源仍待 #155 / GAME-PRODUCER，#150 正式 Host 回执仍归 CODEX-LEAD | `CURSOR-CLOUD` | [#153](https://github.com/narutojzm1-dot/youjia/issues/153)；依赖/正式内容门禁见工单；形式已定：[画卷漫步](architecture/exploration-form-options.md)（用户 2026-10-03）；首地/首物已定：近郊小路＋圆石、松果、落羽都可遇见（用户 2026-10-04，见 EXP-UNBLOCK-20261004），具体构图与资源由 GROK-BUILD #155 交付。 |
| EXP-SCROLL-PROTOTYPE | P1 | #153 队列第 1 项：test/ 下独立最小项目的画卷漫步交互原型，键盘/触屏/停下观察/相机边界/视口变化；几何占位，不接 SaveStore/Main/AudioDirector，不进正式导出 | 隔离原型已交付：PR #204 最终 head `c086b76` 经独立复审（`CURSOR-CLOUD-REVIEW-PR-204`）APPROVE 后合入（`e07bf44`），隔离测试 154 项；高 DPR 真机复测交 GAME-QA #156，竖屏取景交 #201 | `CURSOR-CLOUD` | [#199](https://github.com/narutojzm1-dot/youjia/issues/199)；CODEX-LEAD 指定；[原型说明](architecture/exploration-scroll-prototype.md)；数值为实验参数，不冻结；只证明隔离交互，不是正式功能。 |
| EXP-RETURN-ADAPTER | P1 | #153 队列第 2 项：模拟小院与假 Host 下 `request_return` 后先使院外输入/相机/连接失效再开放院内；unknown/迟到确认/明确失败都可在院内移动且不显示虚假已保存 | 隔离适配已交付：PR #207 最终 head `a2e0043` 经独立复审（`CURSOR-CLOUD-REVIEWER-200`）APPROVE 后合入（`2e33d50`），隔离测试 150 项、13 个变异均被门禁拦下；该原型仍按 PR #176 固定 SHA `e2a6d70` 运行时取出核心（正式核心现已在 `scripts/exploration/`）；真实宿主与 H2/H3/H4 仍归 CODEX-LEAD | `CURSOR-CLOUD` | [#200](https://github.com/narutojzm1-dot/youjia/issues/200)；[开工评论](https://github.com/narutojzm1-dot/youjia/issues/200#issuecomment-5976367738)；沿用 #156 Q10/Q16/Q17；引用 PR #176 核心须注明依赖分支，不证明耐久保存或强退恢复。 |
| EXP-FIRST-EXPERIENCE | P1 | #153 队列第 3 项：停下看景、空手中途返回、带一个占位物中途返回三种体验研究，首片节奏/构图需求与资源接口交接包 | 隔离研究切片已交付：[PR #210](https://github.com/narutojzm1-dot/youjia/pull/210) 最终 head `be60a64` 经独立复审（`CURSOR-CLOUD-REVIEWER-201`）APPROVE 后合入（`f5ca6f3`），隔离测试 261 项；[研究说明](architecture/exploration-first-experience.md)含节奏/构图需求、资源接口表、地点/物件候选与 6 条待决项；首地/物件种类已由用户确认；正式构图/资源待 #155；正式接入沿用现有 SaveStore 文件提交（#153，不等于 #150/Web 持久化验收） | `CURSOR-CLOUD` | [#201](https://github.com/narutojzm1-dot/youjia/issues/201)；[开工评论](https://github.com/narutojzm1-dot/youjia/issues/201#issuecomment-5976771165)；含 GAME-PRODUCER 补充的横竖屏同一停留点取景比较与「走近—松手观察—选择／不选择—中途回院」连续操作检查；与 GROK-BUILD #155 交接，地点/物件种类已决，不再重复征求；画面/资源规格交专业审阅。 |
| EXP-HOST-RECOVERY-GATE | P1 | #150 R2/R3 真实浏览器验收驱动：同一 context、同 origin 下，在“意图已完成/提交前”和“提交完成/回执前”关页后用新页恢复；双页锁竞争；无 Web Locks 阻断；丢回执、错身份、重复/迟到回执与真实 abort 分别出证据；业务授予不重复 | R2/R3 测试侧已交付并合入：#247（`2d2054f`）、#257（`73fe3d5`）；本轮把 #257 中仅经代码审读的 resolve 持续失败上限（模拟错误）与 ack 真实事务 abort 加入正式矩阵，并修正夹具重开后 payload 写成浮点数的问题。驱动/夹具 `e4f9e24` + Gate `f096a4a` + R1 PR251 `2edb2e7`，Godot 4.7.2/Chrome 148 连续两次 14/14 PASS（109 项），变异验证能拦住修复前夹具；PR261 最终 `98d5182` 经独立复审 APPROVE 后合入 `3956afb`。#257 最终 head `47838bf`；CODEX-LEAD-ASSISTANT 的两条异常路径一次性补证 PR259 已合入 `b3f77cc`，已由本矩阵常驻覆盖。只证明隔离候选，不是正式 Host 冻结或 R4 | `CURSOR-CLOUD`（仅测试侧驱动） | [#239](https://github.com/narutojzm1-dot/youjia/issues/239)；[接收与接口候选 v1](https://github.com/narutojzm1-dot/youjia/issues/239#issuecomment-5981415664)。范围：`test/save_recovery_web/**`、`tools/verify_save_recovery_web.sh`、`docs/architecture/save-recovery-web-acceptance.md`。不复制或重写存储实现，不接正式 SaveStore/Main，不建第二套 Host；R1 封套/意图/协调器/恢复入口与 R4 迁移仍归 CODEX-LEAD，接口由 CODEX-LEAD 与 ENGINEERING-SUPERVISOR 核对。 |
| YARD-DECOR-PROPOSAL | P1 | 仅同一占位物的可逆布置隔离对照：2–3 个候选位置与自由放置，预览/取消/确认/收起/换位置；键鼠/触屏横竖屏与低动效 | 隔离对照原型已交付（PR216）；PR232空间修订已合入70c170d，独立审及ART静态材料通过（5981854171）；正式布置/真机/持久化仍待 | `CODEX-LEAD-ASSISTANT`（仅此原型切片） | [#154](https://github.com/narutojzm1-dot/youjia/issues/154)；Leader 明确拆分见本单交接。仅 test/ 隔离项目与 docs，不改 Main/YardWorld/SaveStore/PhotoMoment；#125/#150 正式门禁保留，探索核心仍归 CURSOR-CLOUD。 |
| ART-EXPLORATION-PROPOSAL | P1 | 先资源盘点/规格/构图提案与来源预算；最终画另批 | PR248构图/资源复用提案1d647c31ed0e76a912979940431aabab63ebce95已交，制作人5981844802候选方向通过/消费接口已核，ART5983411469已对同SHA批准仅构图提案，独立review5407926310已APPROVE并合入601d683896d811e2f17cb389e7d0d8104d16e36a；仅提案，不接入 | `CODEX-LEAD-ASSISTANT`（小物样张；关键背景GAME-PRODUCER） | [#155](https://github.com/narutojzm1-dot/youjia/issues/155)；依赖/正式内容门禁见工单。 |
| QA-EXPLORATION-GATE | P1 | 独立失败矩阵/夹具与候选验收、发布和共同维护交接证据 | Q01–Q17矩阵已交；原型Web/真机补测已指定但待执行；正式平台联合验收待交付 | `CODEX-LEAD-ASSISTANT`矩阵 / `GAME-QA`原型补测 / `CODEX-LEAD`平台实现 | [#156](https://github.com/narutojzm1-dot/youjia/issues/156)；依赖/正式内容门禁见工单。 |


## 同构图阴天原画修复

| 编号 | 优先级 | 范围与验收 | 状态 | Owner | 依赖 |
| --- | --- | --- | --- | --- | --- |
| ART-OVERCAST-ALIGNED | P1 | 以晴天母版重绘阴天，几何/交互锚点不动；完整画、叠图与实际尺度预览、来源哈希；美术审核后用新路径接入，保留旧照片资源 | 候选已审画，需局部修改（#168评论5979307760）；v3/2568661350bcfca6cac4c66cae123cbb71b385503bc ART5983393849 REQUEST CHANGES后，原Owner已交v4/2662b1f024f6bad3b700f7c348316075bf0cdc88018，PNGfcc5e649/池框650,790,1560,1020与成对裁切已核；ART5984922645只两云区返修已由原Owner接收并交v5/27133dfd962b93013bb75f8890b5836ef26a3c2e26b，PNGf01c66c1、两云区v4/v5裁切；当前v5已ART5985871441 REQUEST CHANGES：左亮椭圆/右矩形遮罩边、峰脊保护mask及README基准hash需修；只两云区新候选和成对证据，已过草地池面/无争议几何冻结，原Owner已接并交v6/278 e742ac413a6c1eb286a86501c1e177f4462c2427，PNG63a514c6/两云mask/正确v4 hash已交，v6 ART5986839320雪框/池保护通过，云体/矩形天空底板仍需改；原Owner已接并交v7/28165ec28a2685a17087f17baff0db7a3365e9f3312，PNGdff973df/干净右底板/两对照/mask已交，当前v7专业及资源终审待，已过雪地池冻结；LOCAL PR228兼容盘点已合入；50%混合照片表达/字段方案仍待明确，正式接图等待新图艺术批准，未接入/发布 | `GAME-PRODUCER`（GPT绘画接力，待回执） | [#168](https://github.com/narutojzm1-dot/youjia/issues/168)；当前新候选在 `art/concepts/yard_overcast_aligned_v7/`，旧v1保留。ART-DIRECTOR审画，CURSOR-CONTRIBUTOR-LOCAL在#51接自然转场，GAME-QA复测。 |


## 总体声音规划

| 编号 | 优先级 | 当前交付与验收 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- | --- |
| AUDIO-TONE-PROPOSAL | P1 | 60–90秒等响度附近A/B小院试听、分层和来源授权，标清候选未接入 | 用户已选 B；78 秒混音不是循环成品；未接入 | `GROK-BUILD` | [#170](https://github.com/narutojzm1-dot/youjia/issues/170)；用户于 2026-10-03 直接交给 GROK-BUILD。文件在 `art/concepts/audio_tone_v1/`。 |
| AUDIO-HOST-CONTRACT | P1 | 小院事件/混音/设置/Web生命周期与验收方案，复用现有音频设施 | 契约已独立审查合入PR215（06035d2）；#195已由GROK-BUILD实现并发布；冷启动修复/真实Web/听验仍待，不阻塞#149/#150 | `CODEX-LEAD` | [#171](https://github.com/narutojzm1-dot/youjia/issues/171)；[宿主契约](architecture/audio-host-contract.md) |
| AUDIO-B-ASSETS | P1 | 现有院景的环境轨与轻音乐轨可分开调节；循环接缝有测量；不接运行时 | 分轨候选已交；#195 正在引用；未听验 | `GROK-BUILD` | [#194](https://github.com/narutojzm1-dot/youjia/issues/194)。文件在 `art/concepts/audio_b_stems_v1/`。不包含脚步、动物叫、快门。 |
| AUDIO-B-INTEGRATION | P1 | 复用 AudioDirector 播放院景环境与轻音乐；手势解锁、暂停 duck、后台暂停、音乐/环境/总静音可分开；不改存档 | 冷启动与开关已合入 e8622b1；正式game-e8622b1已发布；PM后续game-fd2e9fe仅环境轨一次关/开补证，完整矩阵及实际听验未通过 | `GROK-BUILD` | [#195](https://github.com/narutojzm1-dot/youjia/issues/195)。用户要求优先接入。素材是 #194 候选。 |
| AUDIO-CONTROLS | P1 | 暂停页两条独立音量；0% 真静音；关了再开回到原来的非零音量；只在本局 | 262最终3a008628defe00e2aa04cb005c786afe140243bc独审5408492143、目标4.7.2完整daily/三尺寸正式Web过并合入2686295；公开game-2686295已核Actions/Pages/manifest/PCK，旧类型/横屏布局阻断解除。实际听感/触屏真机/跨刷新持久化未通过，194/195/196/235分别保持 | `GROK-BUILD` | [#234](https://github.com/narutojzm1-dot/youjia/issues/234)；发布证据2625985093870、[三尺寸](playtests/2026-10-05-0620-pause/README.md)。不新增 tuning id，不改存档。 |

来源#162；[分期计划](architecture/audio-delivery-plan.md)；[宿主契约](architecture/audio-host-contract.md)。用户已选 B。#196 听验仍归 GAME-QA。本表不把候选写成听感通过或已发布。


## Web 加载画面修复

| 编号 | 优先级 | 范围与验收 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- | --- |
| QA-EXP-20261003-003 | P2 | 复用已有晴天小院资源恢复加载页风格；桌面/横屏/竖屏文字可读，进度/失败/重试/首帧与版本语义保持，正式发布后冷加载复核 | 已发布；公网三尺寸加载/重试核验通过，GAME-QA可复测 | `CODEX-LEAD-ASSISTANT` | [#167](https://github.com/narutojzm1-dot/youjia/issues/167)；GAME-QA复测，不改游戏或新资源方向。 |

## 用户指定独立 QA

| 编号 | 优先级 | 范围 / 验收 | 状态 | Owner |
| --- | --- | --- | --- | --- |
| QA-20261003-001 | P1 | 归档本轮体验报告与证据，补齐每天 08/12/16 冒烟、20 深测及报告 PR 规则；不开发修复 | 报告与规则经PM集成PR219独立审核合入；原PR165/191已merged；持续测试 | `GAME-QA`（身份 PR164 已合入） |

## 用户指定 PM

| 编号 | 范围 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- |
| PM-COORDINATION | 全仓协作疏导、接收闭环、状态同步与持续游戏体验 | 身份已合入；QA165/191集成已完成；小时巡检已启用，资源/平台真正阻塞仍跟踪 | `GAME-PM` | [#220](https://github.com/narutojzm1-dot/youjia/issues/220)、[规范](collaboration/pm-coordination.md)、[首轮](pm/2026-10-04-coordination.md) |


## 用户试玩镜头收尾

| 编号 | 优先级 | 范围与验收 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- | --- |
| REQ-014-NO-ZOOM | P0 | 鹅马演出三个阶段保持普通倍率，保留观察/扑翼/成片和中断；生产Main各阶段倍率回归与实际Web画面 | 候选实现；完整回归及受控Web已通过，待独立最终SHA审核/发布 | `CODEX-LEAD` | #40；[候选Web证据](playtests/2026-10-04-goose-nozoom/README.md)，演员尺寸#180另验 |


### EXP-UNBLOCK-20261004 · 首片内容已决与存档验证协作

- #153/#155/#201：用户已确认近郊小路＋圆石、松果、落羽均可遇见，解除首地/首物选择依赖。正式构图/资源由 GROK-BUILD #155 交付；探索核心仍归 CURSOR-CLOUD，#176 正式接入仍需 #150。
- #239：Leader 指定 CURSOR-CLOUD 承担 #150 R2/R3 真实浏览器重载/双页验收驱动，CURSOR-CLOUD 已接收（[接收评论](https://github.com/narutojzm1-dot/youjia/issues/239#issuecomment-5981415664)，见 EXP-HOST-RECOVERY-GATE 行）；立即可开展驱动和最小故障屏障接口，真实最终验收依赖 Leader R1 实现，不能以假Host替代。详见工单的文件范围和证据矩阵。
- CODEX-LEAD 保留 R1 封套/持久意图/写入协调/恢复入口及 R4 迁移责任，下一架构交付应为可运行实现；ENGINEERING-SUPERVISOR 评阅接口。GAME-PM 跟进接收、当前/下一交付和解除条件。此分工修正此前 R1–R4 均由 Leader 实现的安排；不重做已交付 #199/#200/#201。


## REQ024边界反馈候选复验

| 编号 | 范围 | 状态 | Owner | 证据与剩余 |
| --- | --- | --- | --- | --- |
| REQ-20261003-024 | 低动效不可达地点提示固定alpha，普通模式保持既有末段淡出，tick独占生命周期 | PR159最终1e067b3已独立审核、目标4.7.2完整daily和三尺寸Web集成通过，合入be47d777并发布game-be47d77；公开manifest/PCK实际核验完成 | GROK-CONTRIBUTOR 实现；CODEX-LEAD/ASSISTANT 验收集成 | [最终集成证据](playtests/2026-10-05-0720-boundary-integration/README.md)；旧c92像素仅按未变代码引用，不称本轮重做。 |

## REQ025底部通知纸片

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-025 | P2 | 底部通知压在前景草石上时也看得清 | 通知垫一块贴合文字的半透明 PAPER 纸片（alpha 0.88、APRICOT 细边、圆角）；最宽仍是原 ±220/屏宽−20，超出换行；钓到鱼 22px/提示 18px 下一帧重新贴合；换行时向上长，不压竖屏底部按钮；字色、字号、位置带、时长、点击穿透不变，无动画。`test/notice_paper_suite.gd` 三视口 49 项通过，修前12项失败；最终49项通过，公开横竖证据见PR318。 | 已合入并公开；适用缺陷仍跟踪 | `GROK-CONTRIBUTOR` | 用户让 GROK-CONTRIBUTOR 每小时自选无主切片；来源是 #276 修订 3 复测旁注“底部通知在阴天背景上对比度低”，原生渲染确认晴天同样难认。只改 `scripts/main.gd` 的通知：构建时加纸片、新增贴合函数，布局与 `_process` 改为调用贴合，不改文案、HUD 其他控件、YardWorld、钓鱼、存档或资源；不改 `tools/verify_daily_life.sh`，挂入 daily 交合入方。决策见 [decisions/REQ-20261005-025.md](decisions/REQ-20261005-025.md)，渲染前后见 [体验记录](playtests/2026-10-05-REQ-025-notice-paper/README.md)。 PR311最终15a8dc40c13d0f2f98f01e94153b4ac0fd260681已独审合入d08f838d24b58c1ede31c0511e2f0dcbe8b72273；公开game-d08f838及后续157ff5f由Leader核验，见PR318/319，不要求重复已交纸片修复。 |


### 隔离恢复夹具错误路径追加证据

ASSISTANT已补PR257候选原先仅代码审读的持续resolve失败/ack真实事务abort，共15断言通过，见[记录](playtests/2026-10-05-0300-recovery-errors/README.md)。只独立验证，不新认领实现；EXP-HOST-RECOVERY-GATE原Cloud与STATE-YARD-GROWTH原Leader Owner保持，正式Host/R4/联合冻结尚未完成。


### R4 进程终止恢复归档（CODEX-LEAD，2026-10-05）

#150 / PR260：prepared、committed、acknowledged三个窗口，实际SIGKILL自建Chromium进程组并同profile/origin重启，25项检查通过，独立终审5407718338。首审prepared verdict异常原证据保留，修订排除自动启动/并发页面并采集页面/恢复事件，不放宽断言。测试代码与已审f27d717保持逐字节不变，本次只同步main并保留共享文档其他贡献者内容。

证据组合仍是当时的fixture73fe、Gatef096、Host2edb及README记录的PCK，不冒充最新Host6e的进程验收；后续Cloud对Host9b的109项兼容与6e仅注释等价是另一组证据。仅完成进程终止子项，不证明物理断电、配额、v5生产迁移或正式Host冻结。旧玩家档/玩法规则不变；260测试目录被.gdignore与导出排除，生产接入仍归Leader150。

### #150 生产读取共用模块（2026-10-05）
CODEX-LEAD 提取 SaveDataCodec，使旧 SaveStore 与后续迁移复用同一业务读取规则；原始字节保全和投影视图区分，未知字段不由投影覆盖。目标4.7.2完整回归、本地三尺寸Web与16项来源隔离检查通过；独立最终SHA审核待完成，正式迁移未冻结；方案见 [save-data-codec](architecture/save-data-codec.md)。Cloud旧六方法接口未变，不重复要求同一矩阵。


### #231 钓鱼携鱼一致性：测试子项明确分配
父缺陷Owner保持CODEX-LEAD；GROK-CONTRIBUTOR已在2315986095129/2425986095748接收并交PR276精确8ffefdf2fa857fa7d7fec3b31acda0998235a351；原作者已修夹具/隔离并交45e839eec3627efad85851bbe715962399b803f8，ASSISTANT5986885702代码范围APPROVE、Leader5986917049接收；旧两项退回解除，剩真实Web三序列及新最终SHA重审，不把85检查当父缺陷已修复。范围仅test/fish_carry_consistency_suite.gd、必要daily挂载及体验记录，不改Main/YardWorld/存档/动物反馈。覆盖无旧鱼miss、有旧鱼miss、携带到期、接近途中到期、暂停恢复和连点消费；Web记录通知key、carry前后及成功投喂与抚摸的区分。失败保留证据，不为凑绿改期望或删除合法旧鱼；最小修复由Leader接收后实现。无需等待150或天气图。[明确交接](https://github.com/narutojzm1-dot/youjia/issues/231#issuecomment-5985809083)。

### #150 共用读取模块审核更新
PR273最终f2b0089d0fe79fa7b1b3322fcda98b7cafb87d88独立CODEX-LEAD-REVIEW-SAVE-CODEC批准5408903859，已合入d480b9696a48f1b6d79c2ae6f27ba321ea10a947；完整daily、最终16检查、本地三尺寸Web通过。合入时Actions37246175543运行中，正式公开核验另写PR273。上文“独立审核待完成”以此结果更新，正式迁移仍未冻结。

### #231 奇怪的鱼：成功收杆通知纠正
GROK-CONTRIBUTOR已接测试子项并交PR276（8ffefdf，58项现状检查）；夹具/隔离已由45e839e修订并获5986885702代码范围APPROVE，原作者继续真实Web三序列；新head须重新终审，当前不合入。CODEX-LEAD独立修正odd成功收杆通知：中文“钓到一条奇怪的鱼。”、英文“Caught a peculiar fish.”，不再声称它已逃走；携带20秒、投喂/消费、随机空钩全部保持。真实到期release文案不改。只解决这一明确矛盾，S2旧鱼+miss歧义及父缺陷其余范围继续验收；验证与发布见对应PR，尚不关闭231。


### #150 小院时间与花圃单次快照（CODEX-LEAD）
生产 YardWorld._save_progress 改为一次 set_yard_progress：天数、日内时间与花圃三个字段一起写入，避免连续提交把“新时间＋旧花圃”旋转为备份。新方法先复制候选，文件提交成功才替换 SaveStore 内存；失败保持先前内存。现有字段/取值边界、独立 setter 和游戏节奏保持，不是 Web durable 回执或正式 Host 冻结。独立分支审核与实际验证见对应 PR 和 test/yard_snapshot_suite.gd；探索正式接入仍等待唯一 writer、文件系统就绪、统一业务确认和容量门禁。


### 探索/布置方向材料接力（PM 2026-10-05）

制作人1545986931224已接232/248并给区域内轻量调整推荐，尚非用户最终自由度批准；唯一实物缺件为一个首批物件（建议圆石）的实际尺度，2–3安全语义位置、摆前/后/收起及正常拍照视角。用户新增提篮贯通与院外/家双核心方向见[策划同步](game-design.md#2026-10-05-用户探索与提篮方向制作人记录同步)；具体形态/容量/采集频率/自由度未定，不新增交易或第二套物品状态。PM155已将短画面序列与实物样张并入既有资源交接，不新开重复研究；执行顺序/窗口待GROK-BUILD接收，既有Owner/150门禁保持。

后到用户资源分工由制作人1535987057979同步：新世界地图/重要背景由GAME-PRODUCER亲绘并交用户选择，小物件可保留GROK-BUILD；原其他认领不自动转移，旧B点材料如涉及新重要背景需按此边界协调，不默认GROK制作大图。A/B预览仅制作人会话未入仓，PM未见实际图、不代选择；工程规格/保存/专业门禁保持。

### GROK-BUILD额度耗尽与绘画Owner接力（2026-10-05用户通知）

当前人员状态与新旧职责以[人员公告](collaboration/personnel-availability.md)为准：GROK-BUILD不可执行，预计10月9日恢复需实际核实。本次最初一揽子绘画移交已被用户最新分工细化：168关键背景归GAME-PRODUCER；155小物/119/121/122归CODEX-LEAD-ASSISTANT，120/123/126普通补绘归CODEX-LEAD，回执/首交未到，不把移交写开工；重要地图背景原已归制作人。音频194/235与工程195/234不随绘画自动转交，替代实现Owner待按真实能力明确，已发布功能和MANUS/LOCAL/Cloud/QA范围保持。历史GROK“可继续”等行此时不代表可执行，不等待其主动回报来推进新排期。

用户最新明确制作人低频巡检，优先重要决策/关键背景/大世界绘制，不承担普通物件队列。各任务实现Owner见[人员公告分表](collaboration/personnel-availability.md)；维护者先核已有资源只补缺件，Assistant下一首项为155实物尺度与提篮材料，Leader按现有主任务/真实缺口串行排资源，不能把队列分配视全部已开工。行为/核心/接入既有Owner与专业审核保持。


### 2026-10-05 CODEX-LEAD普通资源接力回执
已读取人员公告并接收#120马回应/#123旅人轻抚/#126普通地面补绘，GROK-BUILD暂停期间不再等其执行。先核现有候选：#120 PR145已合入的horse_attend不重画一遍冒新成果，本轮补ART5970265333要求的固定脚底、相同倍率idle→attend→idle资源切换证据。浏览器审查页与左右镜像/110px参考尺度见[记录](playtests/2026-10-05-horse-attend-gate/README.md)。原尺寸胸背/臀线变化及透明碎点需专业收口，未批准接入，不使用逐帧bbox缩放遮盖问题。

串行次序：120剩余问题收口→123先B静态接触样张（沿原384×448/脚底192,420与一种动物的接触规格）→126先核现有地面是否足够再决定普通补绘；不并行宣布三单开工，不绘制作人的关键背景、不接管MANUS行为/WORKBUDDY乘骑。#150正式存档仍Leader主任务，资源审查不代表存档冻结。


### STATE-SAVE-CAPACITY / #287：真实容量证据分工
CODEX-LEAD指定CURSOR-CLOUD承担真实PhotoMoment/相册与旧档主备原文封装容量边界，接收回执待核。范围test/save_payload_budget/、docs/architecture/save-payload-capacity.md及证据，独立分支PR/最终SHA审核；不修改生产Store/Host，不重复已关闭239的109矩阵。用生产捕获与序列化构建可追溯样本，分开自然可达样本与合成压力样本，记录UTF-8字节、双原文封装开销及现64KiB夹具拒绝点/失败前后保全。不得裁历史照片/未知字段凑预算，Storage.estimate不是配额保证。正式容量、唯一writer和durable消费仍Leader负责；此项无需等待画作或正式探索，详见[工单287](https://github.com/narutojzm1-dot/youjia/issues/287)。


## 11:20轮当前接收与候选（实际03:17Z后）

两维护者已接普通资源：Assistant1555987355414/2425987385196实际交Draft285 e6c780967c1d3c087d839099feb32655c689ae5a圆石9静态位置图/提篮文本；Leader1205987453733交并合入286 final3d32328aa3902f008f6f6837b7019067440282b3脚底固定倍率材料。均不代表ART/正式摄影/运行时通过，先收当前再串行119/121/122或123/126。Producer关键背景168接收仍待。

阴天v7已ART5987342220退回仅天空合成；晚到原Grok289/v8 3893d472594ec73624cc5e4c3b4fcbc9af78dec0实际PNG ec11fa32f498fa48a37ba43dc35235176f539102bc3ffc5946d4ffe4064f01c9/3586561bytes，专业/资源终审待。原产物保留，不撤用户额度暂停/不认其下轮可执行、不把关键背景Owner交回。LOCAL正式接图待最新批准；字段只读兼容提案可继续。

用户世界图已选B纵深、庭院靠A现有识别，本轮不扩幅，远处线稿纸白；私聊B修订预览本身未确认/未入仓，PM未看图。携带3只是候选实验，数量/掉率未冻结。Cloud新287容量证据获明确拆分，可先交真实capture/default样本与raw双份UTF8/独立压力边界，不等150正式接入；首次接收/实物未到。276当前5e01c1f06a5a20fb2c4f981159660b78b29cbde7保留yard_snapshot/隔离marker及fish挂载，旧45e审核仅历史，新终审待；Web旧鱼miss仍未覆盖，Leader5987473273已澄清自然同岸同像素证据，不等新产品决定，不能以不可走到水面当携带禁钓。

当前仍开发展开，收285专业/真实摄影边界、120艺术缺口、287容量交接及276自然证据→精确SHA终审→必要验证/合入，再按晚间检查点取可发批次，不承诺150/探索/阴天已正式交付。详见[本轮逐人记录](pm/2026-10-05-1120-coordination.md)。

### 2026-10-05 Assistant #231：旧鱼保留时第二竿未钓到的提示

CODEX-LEAD-ASSISTANT按最新缺陷队列接收与原单5990509435认领，只修YardWorld._tick_fishing两条miss通知：carry有效时明确本次未钓到、手中之前那条鱼仍在；空手/到期提示和鱼状态/20秒/概率/计数/投喂不改。新专项16项修前2失败/修后全过、Godot4.7.2完整daily及双语横竖受控Web、正常标题入口自然两竿实玩通过，见[证据](playtests/2026-10-05-fish-miss-feedback/README.md)。原276仅同步S2通知断言，历史未审原帧不冒完成；Leader149150/Cloud322不覆盖。当前候选待独立最终SHA审核、合入与实际公开发布，父231其余验收保持开放。

### 2026-10-05 CODEX-LEAD：#231 携鱼第二竿主操作

由CODEX-LEAD修复#276修订3发现7，仅调整活动钓竿优先于默认携物操作；保留显式动物选择、既有携鱼再抛竿与旧鱼到期规则。新独立回归纳入daily，不接管GROK-CONTRIBUTOR的fish_carry套件。验收：携鱼等待/咬钩显示等待/收竿，主操作确实收竿，失败不清旧鱼或重置计时，三视口受控Web及完整回归；合入、发布仍待门禁。

## 12:20轮有效更新（实际04:17Z后）

Cloud已2875987971922/2425987986625接收容量子项，分支cursor/save-payload-budget-9e9c，报告连续执行；未交最终SHA/PR，不等150正式接入。回报正文05:2xZ/13:2x与本轮服务器04:17Z时间不一致，只记作者窗口声明和实际API接收，不伪称该未来时段已完成。

阴天289/v8精确3893d472594ec73624cc5e4c3b4fcbc9af78dec0已ART5987861221 REQUEST CHANGES，仅右侧无云底板轴对齐拼贴；左区/雪山/y>=250通过冻结，先底板全图+跨边界1:1裁切，后云层。Leader已接专业结论，Producer实际绘画接收待；用户额度暂停保持，不再写v8等首次艺术审。PM1685988019012交最小产物，LOCAL兼容只读范围可继续。

285当前1b53f4a241cc972aae323d28253ed2b9d4a1237c只README/三尺寸CSS证据，原PNG未变。ART5987884621已要求水彩概括/短淡影/紧透明包络/实体影bbox锚点/近物前后遮挡实际文件，不再等首次专业意见；PM2855988018792交原Owner下一最小返修与接收。手机11–14CSSpx不当真机摄影通过。

276当前f3cef337db18d0953cab0887b6f68c7927bb41b4作者已自然复测旧鱼miss两次，旧鱼保留/计时不重置；撤回不可落脚等旧推断。原PNG仍只hash，新终审待。Leader已接HUD发现7、保留携鱼再钓并独立291（索引head ca6c736adc89fc44f6325faae4e3c5928be12269，活动中可能变化）；受控探针390×844纹理/着色错误与正常冷启动无错均不足以定生产原因，Draft不合入。PM2765988018451提出仅关键原帧下载URL/base64文本→PM解码核hash/Git blob归档的具体接力，等原字节/回执，不重复106图、不改S2禁止携鱼/不把hash当看图。

用户七页B修订概念已确认，制作人1535987978019；原图未入仓/PM未见，概念不当七页首发或可接资源。详见[策划](game-design.md)与[本轮逐人记录](pm/2026-10-05-1220-coordination.md)。仍开发展开，先收上述真实依赖/资源修订/容量/证据终审，晚间按通过批次收敛。

## 2026-10-05 13点轮：容量测量接收与下一项

CODEX-LEAD接收#287/#293最终f0fece7测量交付，合入f39e4abb2cd441ca4e02b2c75e77ca7962a36628。自然稳态两张照片82,603B、满档合并578,267B，证明64KiB夹具不能用于正式接入；不是生产存档丢失或正式Host验收通过。后续#294指定CURSOR-CLOUD测合法密集照片、转义封装及0/1/8/32恢复归档容量，只限原测试/容量文档，待回执；CODEX-LEAD保留四层预算实现与生产写入/持久回执责任。1.5MiB/3.5MiB/≥1MiB仅候选，待真实边界与平台成本证据，不冻结。


## 13:20轮接收与发布更新（实际05:22Z后）

291 final1713c8073c3f0eb49dfe76a70a1ee27f6d5f15cc独立5410201299通过并合入76499128714eb17b92f7be15d550bcdfc43d305a，已公开game-7649912。三视口受控重验/正常本地自然两竿与公开发布核验记录在296；旧失败保留，不能把/tmp满称唯一根因。上轮“291Draft门禁失败”不再是当前状态；231其余范围和276原帧/作者终审不因此全部关闭。

Cloud287已交293 finalf0fece7bddd9baa87a2271604c0b602170f26a9b，合入f39e4abb2cd441ca4e02b2c75e77ca7962a36628，Leader明确接收并295更新生产预算边界。190检查174PASS/16真实兼容FAIL保留；两照片稳态82603B与满档578267B说明64KiB不能直接照搬生产，投影不能代替原文。2945988560174已接cursor/save-budget-bounds-9e9c，合法密集合成/转义二次封装/archive测量继续，非重复239；候选1.5/3.5/≥1MiB未冻结，Lead仍生产Host/sole-writer/durable Owner。

Assistant285新166c21d7a847d7325e82d81ff01d9f28c90eda5b实际水彩化中间图已交，alpha外晕仍未合格，Owner明确继续紧包络/近物遮挡文件；不当已ART通过/正式资源。168仍仅右底板待Producer直接接收，左区与雪地池冻结；Grok额度暂停至预计10/9待核，不恢复任务。

276作者5988107051已接PM，原106帧和6关键帧为JPEG（非PNG），hash清单不是PM看图。通道不能可靠传大base64，PM5988628522接收限制、不重复催百万文本/不索凭据，不将新环境复跑冒原帧；原代码能审范围仍可原链审，原帧缺口与新公开补证分开。194/235音频资源缺位，PM1945988628315请MANUS仅核可追溯制作能力/工具/试听窗口，未接/未证明前不转资源Owner，行为成功事件/30可继续。Cloud294接收已同步5988628876。

当前仍开发展开，今日优先闭环294→生产预算、285最小资源修订→ART、168右底板→ART与276原链可审/证据限制；晚间按实际通过批次取可发项，不以七页概念或统计数代功能交付。逐人下一步见[本轮记录](pm/2026-10-05-1320-coordination.md)。


## 用户最新人员调整：MANUS额度与音频临时接力（2026-10-05）

用户直接通知：MANUS额度11月2日刷新，当前按额度暂停记录，预计2026-11-02恢复须核实际可用/接收，不自动恢复定时任务。此前向MANUS询问音频制作能力的等待取消，不继续催其交付。

用户明确“音频暂时找assistant”：CODEX-LEAD-ASSISTANT临时接#194环境自然化与#235短音资源制作，先接收并核现有分轨/来源、缺件与实际工具/试听能力，给一个最小可听候选及来源/哈希/循环或一次播放说明和实际窗口。不能以图片生成、波形或整体调低音量代替音频候选/真实听验；无制作能力时及时具体上报，不重新等MANUS。先盘点与现有#155串行排期，不假定全部并行完成。

#30/#235成功事件接入等MANUS既有行为Owner保留但暂停，用户本次只明确音频接力；不自动接管其全部代码/音频后端。若资源完成后确需接线，PM另组织显式文件范围交接；公共cue接口/集成仍Leader，真实听验仍QA/可出声设备。已有素材、原分支与提交保留，独立最终SHA审查、必要验证/试听、合入及发布分别记录。留言不等Assistant已接收。


## 2026-10-05 阻塞兜底授权

用户明确所有受阻内容由CODEX-LEAD保底执行或与CODEX-LEAD-ASSISTANT协作。30/235行为及180运行验证由Leader接替无法执行的范围，150继续Leader，Assistant音频/小物/动物资源按实际队列协作；制作人活跃绘画不重复，缺件Leader兜底。详见[人员公告最新执行表](collaboration/personnel-availability.md#2026-10-05-用户授权阻塞工作由leader保底执行)。不再以暂停Owner名义长期等待，不降低独立审查/真实验证要求，不冒称已开工或上线。

- 2026-10-05 #180 CODEX-LEAD保底切片：实际Web复现并提出马idle/rest贴图尺寸跳变止血候选；暂用idle休息，horse_tail原资源保留待同尺度美术。具体12态修前/后证据见[记录](playtests/2026-10-05-horse-posture-size/README.md)。仅此路径待独立审核/发布，不关闭#180组合验收，也不声称所有马尺寸问题已修。

- 2026-10-05 #30 CODEX-LEAD兜底切片：牛成功抚摸用glance，马/双羊用原idle站姿停步面向玩家，不再默认播放爱心；每只动物2.2秒反馈、5秒视觉间隔，连点不续期，合法交互/摄影事件照常。鸭鹅投鱼及完整自然动作资源仍另验收。


## 14:20轮执行接力与收尾（实际06:21Z后）

301兜底分工已合入ba3bb72f9d78ddd2740403fb66a4a380c481e84e，Leader实际执行30/180/150，非仍未落实接力。276模式已a1de2bc修复，最终da146fd3adb3d6f58730fb802ae2fba02ac4c617独审5989156701后合入ed5f1d7d6b025ebb7290bfd470f89aa7ac482a4b，旧文件权限阻塞解除；批准代码/如实记录，旧106JPEG仍未审、父231不关闭。

304 final97fc91eb5d7a5375e6d292fa0d47c2638aa5e148独立5989199336通过并合入6a3ffd5；只停绑horse_tail休息cel造成29.13%包围盒变化路径，资源/scale/camera保持。302 first78b0114转向tick覆写已独审退回，当前ee33dda3d2d84b301cfcb3c4616ce1e779e81f0a独立5989207778批准，普通抚摸实际tick回应/不默认心，合入与发布按最新实际状态，不能称整个30/180已闭环。

303 final3041e5f022786bb1ad5fde7e3e8263e49b6798e8只合入251研发分支，Host当前0dbff93ae2a78ceb3aa5d54c86a3a38da6475b89新增candidate-v1分层预算/32MiB记录预算，fixture64KiB保留；这是模块实际实现，不是150生产冻结。Cloud298294a1f9842ec894634ad4b268e4ffc429d063c87已交且队列空，PM新305承接原239真实组合职责，固定此新Host与190Gate，增量profile/大自然档/锁恢复组合，不重复303内部139/28或293298容量测量；接口不支持时交精确接线缺口、不造假Host，新回执待。150生产整合仍Leader。

Assistant音频300 b8e5e6dc916dacd1eaf45b36c9f17584d36fc16c已接且实际交，技术独审/PCM可复现≠OGG字节可复现或真实听验，32秒包络规律与RMS降低须出声QA，候选Draft不替线上。235短音串行下一项，285166c21d7a847d7325e82d81ff01d9f28c90eda5b新ART5989168450水彩/轮廓通过冻结，只机械清晕紧包络/主体影bbox锚点及同版本3场景文件；PM5989228656收窄，不再重画风格或把提篮完整序列扩大此次返修。Producer1685988859097已接但无新底板；两额度暂停/Grok原产物保持。

当前开发展开，先收302/304实际验证发布、305候选组合接线、285资源收尾与300真人听验，不以单量/模型统计替交付。详见[本轮逐人记录](pm/2026-10-05-1420-coordination.md)。


## 单一Owner端到端交付（用户2026-10-05调整）

用户因小时轮次下多角色串行等待拖慢交付，明确改为：每个worker独立负责所认领切片的制作/实现、监修、返修、运行时接入、必要验证、PR和合入。默认完成定义是可运行且验证过的切片，不是交一张候选图后等待另一个小时角色接线。Owner在一次实际执行中连续推进可完成步骤，不人为把每一步留到下次定时；有真实依赖才交接。

- **Owner必须主动单独启动独立子代理审核。** 实施者不得自审或用自己的检查冒充子代理。资源可在接入前先由独立子代理审画，最终接入PR仍须对完整最终SHA独立终审，检查资源质量、需求符合度、代码、兼容性与回归；缺专业能力时由Owner主动补充具备能力的独立审阅，不将定时督导下一轮巡检作为默认串行前置。审核后改SHA须重审，必要验证未覆盖不能算通过。
- ART/工程督导保留方向、专业监督、疑难升级及抽检职责；GAME-QA继续独立体验与发布回归。独立评审必须覆盖适用专业标准，已有REQUEST CHANGES必须逐项解决，不以新流程抹去退回结论或降低资源/平台/存档/真实听验门禁。真正用户产品选择仍归用户。
- Owner可在其切片内做必要接入代码；共享存档、公共协议等高耦合框架仍按已明确接口与文件边界，不因端到端授权任意重写。无法运行、缺审核能力或接口确实未完成时，给具体缺口和最小协助，Leader/Assistant按已有兜底授权协助；不能长期停留在“等别人接入”。
- 现有任务逐项确认单一交付Owner和重叠文件，保留原候选/提交，使用自己的分支PR，不强推/覆盖他人分支。接入职责转移须回原单并请求接收；未回执不宣称已开工。已完成的前任接入者转为已有契约说明/兼容协助，不并行重复接线。
- 作者独立审核及验证通过后可自行合入。Leader保留整体架构、跨切片冲突、23:00正式发布与后置保底；PM逐人检查实际产物、接收与阻塞，#242短回报机制保留，不新增逐级审批。

**当前落地：** #168/#51同构图阴天由已接收背景绘画的GAME-PRODUCER承担右侧底板返修→主动独立审画→必要天气接入→最终SHA独审→天气连续性/照片兼容及导出验证→合入。允许本角色为自身背景切片做必要接入代码，覆盖旧“不直接参与代码”限制的这一范围；关键背景/世界图与普通物件由两位Codex负责的分工保持。LOCAL保留其已交成果及照片字段兼容协助，不再作为每张背景必须等待的第二接入Owner；照片公共存档不转交制作人。Producer需回原单接收扩展范围与实际执行能力，不能把原先只接绘画的回执视作已接住新范围。#285物件/#300音频等由既有Assistant连同适用接入和验证收尾，不把资源交出视作功能已完成；真实出声/设备能力不足须据实安排协助。

- 2026-10-05 #40 CODEX-LEAD补充路径：静观天空5.5秒后独立触发1.14相机缩放，非马贴图切换。候选仅改为1.0，观察/抬头平移/冷却/中断保留；两模式实际Main相机Web对照见[记录](playtests/2026-10-05-quiet-sky-scale/README.md)。待独立最终SHA审核、合入和公开发布，不将候选写成已上线。


### 2026-10-05 探索模块独立交付授权

用户指定 CURSOR-CLOUD 按已确认需求独立负责探索开发，无须 CODEX-LEAD 前置审核；Leader 阶段性后置补审，Cloud 参照执行并记录处理。作者自行组织独立最终 SHA 子代理审核及必要验证后可合入。首片近郊小路＋圆石/松果/落羽已决；共享 #150 存档真实依赖仅限制相关生产接线，不阻塞独立探索切片。#305 不是探索唯一队列，#176 不因授权自动获得生产验收。完整范围、Owner 边界与回执规则以 [AGENTS.md 探索独立授权](../AGENTS.md#2026-10-05-cursor-cloud-独立负责探索模块用户最新授权) 为准。


## 2026-10-05 用户最新三位开发者分工

用户将Leader工作重心定为功能增加/迭代与共享架构，Assistant倾向缺陷修复，Cloud独立负责大世界探索；制作人持续输出原画、音频资源与游戏需求。以 [最新分工/在途/交接表](collaboration/goal-ownership.md) 为准。旧资源临时Owner保留历史，不继续作为新开工依据；#300/#317/#285保留已交候选后显式交Producer，新Owner回执待核。#149/#150真实Host框架由Leader连续收尾，316经两轮退回修正、最终c893be6f617e75552f3adcc0358546263aa8c903独审合入251研发分支39516cb02d491837a6943b01a3a81b157a9dac5d，不代表生产冻结；Cloud314已有纯核心产物但无玩家入口。原单直接标Owner/状态/文件方法范围/PR和SHA，未开始不标进行中。#198用户主动延期至核心玩法基本完成，停止资源追问。

### Assistant 接收缺陷优先目标与新绵羊照片子项
已接收用户新分工及[单一范围认领](collaboration/goal-ownership.md)，不重复Leader/Cloud在途实现。QA-EXP-20261003-002新照片构图子项由CODEX-LEAD-ASSISTANT推进：sheep物种Owner与sheep_a/sheep_b快照ID不一致导致默认取景漏羊。最小修复仅PhotoMoment构图和专项测试/daily挂载，9项修前三失败/修后全过、4.7.2完整daily和受控Web对比通过，见[证据](playtests/2026-10-05-photo-species-frame/README.md)。PR320最终8c364c0ab5a4d2b5550e7710485d0b428064c0ef经独立子代理APPROVE，合main5a0a446577eba5916da51ad7f0e926f118045c01；Actions/Pages成功，实际公开game-5a0a446三资源完整下载哈希与gh-pages一致。正常本地及公网自然轻抚生成新照片、手帐两羊完整入镜，见[实玩/发布证据](playtests/2026-10-05-photo-species-release/README.md)。仅完成新照片构图子项，旧图不变、父40仍Leader；#180/#231/#195/#234/#167剩余缺陷队列已接收，未同时实施，资源候选已明确交制作人接续待回执。


## REQ026网页高清屏按CSS像素排版

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-026 | P1 | 手机、Retina 和 Windows 125%～175% 缩放的浏览器里，字和按钮保持设计大小，竖屏手机走竖屏布局 | Web 上把根窗口 `content_scale_factor` 设为浏览器 devicePixelRatio（<1/NaN/无穷按 1，上限 4），尺寸变化时重读；`Main.size` 回到 CSS 像素，HUD 位置/尺寸/字号/镜头缩放与同 CSS 尺寸 DPR 1 一致，画面仍按物理分辨率渲染；原生桌面不变。`test/web_hidpi_suite.gd` 102 项通过，去掉自动加载后 39 项失败。 | 已独审合入；公开发布验收进行中 | `GROK-CONTRIBUTOR` | 用户让 GROK-CONTRIBUTOR 每小时自选无主切片；来源是 GAME-QA 14:34 冒烟截图（1260×886 CSS 视口里提示纸片约 308px，设计 538px，约 1.75 倍缩小）。根因：Web 导出 hidpi 开 + `stretch=disabled`，DPR 3 手机的 390×844 被当成 1170×2532 桌面横排。只新增 `scripts/ui/web_hidpi.gd`（规则）与 `autoload/web_hidpi_boot.gd`（主场景首次布局前定倍率、根窗口尺寸变化时重读），`project.godot` 只加这一行自动加载；不改 `scripts/main.gd`、stretch 设置、导出预设、加载页、字号、文案、YardWorld、存档或资源；CODEX-LEAD集成补充daily入口与真实Web DPR验证；结果见本PR集成记录。决策见 [decisions/REQ-20261005-026.md](decisions/REQ-20261005-026.md)，记录见 [体验记录](playtests/2026-10-05-REQ-026-web-hidpi/README.md)。  PM已登记原作者候选84f61b218da98ba1ea3b6f482a84a3a7b4392214及端到端责任：作者主动独审/验证，能力缺口明确交协助者，不等Leader下一轮；模型DPR不当手机真机，原生布局保持。按作者明确请求Leader已接最小集成：daily保100755、生产Web同CSS视口DPR1/2/3与真实输入验证，见[集成证据](playtests/2026-10-05-hidpi-web-integration/README.md)。前一候选6d9fb765be168115fb820341958720e75da62d3b已独审APPROVE，文档冲突解决后最终517b164d6f7e7d74987111ce84cabb097e5e5a2f已重新独审APPROVE并合入main 5f74afb1eaf521f0f2df9401138b248b560b04a4；公开发布验收继续。 |


### #149 现有文件提交的内存一致性（2026-10-05，CODEX-LEAD）

进行中候选：SaveStore所有旧setter使用共同候选提交边界，文件失败不发布内存，稍后保存不混入失败字段。72项实际文件故障回归由21失败变0，完整daily及正常Web抚摸羊→照片→关页重开通过；[证据](playtests/2026-10-05-save-candidate/README.md)。只修同步文件路径，不宣称Web durable；#150生产后端与异步协调器继续，Cloud探索同名helper保留一个相同实现、其新方法与字段不覆盖。最终独审/合入/公开验证以关联PR为准。


## GAME-PM 16:20：首片容量已决与资源/程序口径同步

用户本轮直接选择单趟最多3件，合计不是每种3件；可空手/随时回院、不要求捡齐圆石松果落羽。此前上限1仅实验值，Cloud1535990862078已收到仓库通知，新范围接收和实现SHA待核，Owner不变。0/1/2/3、第四件处理、同篮回院/重载须在新最终SHA适用验收，频率/掉率未定；原画长卷/单幅串联已向用户呈现仍待选择，不当整条探索阻塞。1555990819693已纠正小物继续等Assistant的旧口径，新资源Producer接续；四份当前协作入口的旧资源分配同步319，历史台账保留。321实际已获得集成协助/独立再审并合入5f74afb，328生产候选提交边界已入e68e9a1；研发251最新3d418与生产Host未开启分别记录，Leader/Assistant仍有在途实现不重复调度。详见本轮逐人报告与公开体验证据。

## 2026-10-05 本地制作人接续：原画透视探索已决

用户在本地制作人会话明确选择“保留原画视角，沿路走动并自然换页”。正式探索保留单幅绘画纵深，人物沿画中道路行走，在桥、林口等自然边界换页，不以水平拉伸/重排地理迁就侧视横走原型。世界地理固定，07回望左院右村；首片近郊与随时回院保持，七页非同批首发，单趟最多3件已由用户在PM会话另行确认（#153评论5990862078），频率仍未定。执行细化和验收见[原画路径方向](architecture/exploration-painted-path-direction.md)。

总图、七页标注与六页场景候选已恢复为[可追溯原图包](../art/concepts/producer_world_20261005/README.md)，另保留历史稿，13张均原字节及hash核验；三个用户直链再次下载一致。此为原图归档和方向交付，不表示运行时接入、美术终验或发布。此前“原图只在会话”描述保留历史，以本条为当前状态；制作人资源职责按goal-ownership及[本地接续](collaboration/producer-local-handoff-20261005.md)，不按旧两Codex临时资源分工继续开工。

### #149/#150 PR336 接线候选（CODEX-LEAD，实际进行中）

已实现生产候选的可信启动、单队列意图、严格持久回执消费、原文来源保全和旧页分歧下载入口；自然Web羊照片实际关页重开及受控迁移/事务abort已取得证据。最终完整回归、修订后独审、探索组合适配与公开验收未齐前不可合入。原生回退兼容已依据独审及原回归返修，200真实文件检查与旧“坏主好备可继续保存”24项通过，仍待新最终SHA独审。接口/未覆盖见[PR336接线说明](architecture/production-save-integration.md)，父单保持开放。
