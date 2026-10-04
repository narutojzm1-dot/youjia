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
| REQ-20261002-015 | P1 | 为大鹅骑马抓拍补一张完整的乘骑扑翼画 | 规格写清脚必须踩在马背上、不能用站立鹅冒充、画布/锚点/朝向/体积上限；画切片只交付成品 PNG 与运行时注册，不改演出脚本。 | 资源及导演接线已合入；最终SHA后置复审已通过，组合Web验收待补（#180） | `GROK-BUILD`（规格切片）／`WORKBUDDY-CONTRIBUTOR`（成品画切片） | 规格见 [architecture/goose-mount-pose-spec.md](architecture/goose-mount-pose-spec.md)。PR #65 已把临时换帧接到 `show_goose_encounter_cel`。产品已于 2026-10-03 确认「两张交替」而非一张：`WORKBUDDY-CONTRIBUTOR` 交付 `goose_riding_up`/`goose_riding_down` 两帧成品画（1254×1254、脚底锚点对齐后残余 ≤0.5px、`native_facing=1`、均小于 `goose.png` 的 1,212,584 字节上限），并在 `cast_art.gd` 暴露 `riding_up`/`riding_down`。导演接线仍属 REQ-014 / `CODEX-LEAD`，本切片不改 `yard_world.gd`／`FeltActor`。**PR #99 已于 2026-10-03 合并**（merge `5b695043`，head `f2d2fc21`，三轮独立评审终轮 APPROVE 无阻塞）：两帧已在 main，`cast_art.gd` 已注册 `riding_up`/`riding_down`，可被引擎直接取用；导演接线已由 `WORKBUDDY-CONTRIBUTOR` 于 2026-10-03 跨越切片边界实施（用户明确授权）：[PR #173](https://github.com/narutojzm1-dot/youjia/pull/173) 将 `yard_world.gd` 鹅马乘骑演出的 `show_goose_encounter_cel` 帧交替由占位 `idle`/`calm` 改为真正的 `riding_up`/`riding_down`，沿用既有 0.28s 扑翼时钟与低动效定帧，资源/接线历史单#64已关闭；最终完整SHA `0066cef9da621530d05d5ad8051be684512ce88c` 后置独立复审已通过（reviewer `CODEX-LEAD-ASSISTANT-REVIEW-PR-173-FINAL`，[证据](https://github.com/narutojzm1-dot/youjia/pull/173#issuecomment-5971467561)），不追认原始合入门禁；组合Web验收仍由[issue #180](https://github.com/narutojzm1-dot/youjia/issues/180)跟踪，Owner保持WORKBUDDY-CONTRIBUTOR。 |
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
| STATE-YARD-GROWTH | P1 | 物品/布置/探索结果共享契约与迁移/去重提交矩阵，先设计 | 宿主事务方案已提交，待联合评阅；未冻结/实现 | `CODEX-LEAD` | [#150](https://github.com/narutojzm1-dot/youjia/issues/150)；依赖/正式内容门禁见工单。 |
| EXP-CONTRACT | P1 | 独立探索边界/快照/宿主确认/失败恢复契约，与共享状态对齐 | 设计稿已按督导评阅修订并合入（PR160 → PR174，CODEX-LEAD 批准 56eeedc，未冻结）；待与#150共同冻结（含平台持久化结果未知的边界）并经工程督导复核 | `CURSOR-CLOUD` | [#151](https://github.com/narutojzm1-dot/youjia/issues/151)；[契约设计稿](architecture/exploration-module-contract.md)，与#150待共同冻结项列于其第10节；不含正式地点/物品/形式。 |
| EXP-CORE | P1 | 形态无关核心状态机/恢复/返回，严格隔离测试；夹具不正式发布 | 已指定；依赖契约冻结；冻结前草案见 PR176（Draft，不合入） | `CURSOR-CLOUD` | [#152](https://github.com/narutojzm1-dot/youjia/issues/152)；依赖/正式内容门禁见工单。 |
| EXP-FIRST-SLICE | P1 | 确认的一条近郊往返，空手/取消/重复提交/键鼠触屏低动效与正式发布闭环 | 已指定；正式内容待产品/资源选择与共享存档 | `CURSOR-CLOUD` | [#153](https://github.com/narutojzm1-dot/youjia/issues/153)；依赖/正式内容门禁见工单；形式已定：[画卷漫步](architecture/exploration-form-options.md)（用户 2026-10-03）；首条去处/带回物待 GROK-BUILD #155 资源提案与样张确认。 |
| EXP-SCROLL-PROTOTYPE | P1 | #153 队列第 1 项：test/ 下独立最小项目的画卷漫步交互原型，键盘/触屏/停下观察/相机边界/视口变化；几何占位，不接 SaveStore/Main/AudioDirector，不进正式导出 | 隔离原型已交付：PR #204 最终 head `c086b76` 经独立复审（`CURSOR-CLOUD-REVIEW-PR-204`）APPROVE 后合入（`e07bf44`），隔离测试 154 项；高 DPR 真机复测交 GAME-QA #156，竖屏取景交 #201 | `CURSOR-CLOUD` | [#199](https://github.com/narutojzm1-dot/youjia/issues/199)；CODEX-LEAD 指定；[原型说明](architecture/exploration-scroll-prototype.md)；数值为实验参数，不冻结；只证明隔离交互，不是正式功能。 |
| EXP-RETURN-ADAPTER | P1 | #153 队列第 2 项：模拟小院与假 Host 下 `request_return` 后先使院外输入/相机/连接失效再开放院内；unknown/迟到确认/明确失败都可在院内移动且不显示虚假已保存 | 隔离适配已交付：PR #207 最终 head `a2e0043` 经独立复审（`CURSOR-CLOUD-REVIEWER-200`）APPROVE 后合入（`2e33d50`），隔离测试 150 项、13 个变异均被门禁拦下；核心按 PR #176 固定 SHA `e2a6d70` 运行时取出，不复制入仓；真实宿主与 H2/H3/H4 仍归 CODEX-LEAD | `CURSOR-CLOUD` | [#200](https://github.com/narutojzm1-dot/youjia/issues/200)；[开工评论](https://github.com/narutojzm1-dot/youjia/issues/200#issuecomment-5976367738)；沿用 #156 Q10/Q16/Q17；引用 PR #176 核心须注明依赖分支，不证明耐久保存或强退恢复。 |
| EXP-FIRST-EXPERIENCE | P1 | #153 队列第 3 项：停下看景、空手中途返回、带一个占位物中途返回三种体验研究，首片节奏/构图需求与资源接口交接包 | 隔离研究切片已交付：[PR #210](https://github.com/narutojzm1-dot/youjia/pull/210) 最终 head `be60a64` 经独立复审（`CURSOR-CLOUD-REVIEWER-201`）APPROVE 后合入（`f5ca6f3`），隔离测试 261 项；[研究说明](architecture/exploration-first-experience.md)含节奏/构图需求、资源接口表、地点/物件候选与 6 条待决项；正式结论待用户选择地点/带回物、#155 资源样例与 #150 联合冻结 | `CURSOR-CLOUD` | [#201](https://github.com/narutojzm1-dot/youjia/issues/201)；[开工评论](https://github.com/narutojzm1-dot/youjia/issues/201#issuecomment-5976771165)；含 GAME-PRODUCER 补充的横竖屏同一停留点取景比较与「走近—松手观察—选择／不选择—中途回院」连续操作检查；与 GROK-BUILD #155 交接，地点/物件作为候选交 GAME-PRODUCER/Leader 汇总用户确认。 |
| YARD-DECOR-PROPOSAL | P1 | 仅同一占位物的可逆布置隔离对照：2–3 个候选位置与自由放置，预览/取消/确认/收起/换位置；键鼠/触屏横竖屏与低动效 | 隔离对照原型已交付（PR216）；正式布置规则、地面/动物遮挡、真机与持久化仍待验 | `CODEX-LEAD-ASSISTANT`（仅此原型切片） | [#154](https://github.com/narutojzm1-dot/youjia/issues/154)；Leader 明确拆分见本单交接。仅 test/ 隔离项目与 docs，不改 Main/YardWorld/SaveStore/PhotoMoment；#125/#150 正式门禁保留，探索核心仍归 CURSOR-CLOUD。 |
| ART-EXPLORATION-PROPOSAL | P1 | 先资源盘点/规格/构图提案与来源预算；最终画另批 | 已指定；先提案，不接入 | `GROK-BUILD` | [#155](https://github.com/narutojzm1-dot/youjia/issues/155)；依赖/正式内容门禁见工单。 |
| QA-EXPLORATION-GATE | P1 | 独立失败矩阵/夹具与候选验收、发布和共同维护交接证据 | 待认领；先方案，候选验收随交付 | 待认领 | [#156](https://github.com/narutojzm1-dot/youjia/issues/156)；依赖/正式内容门禁见工单。 |


## 同构图阴天原画修复

| 编号 | 优先级 | 范围与验收 | 状态 | Owner | 依赖 |
| --- | --- | --- | --- | --- | --- |
| ART-OVERCAST-ALIGNED | P1 | 以晴天母版重绘阴天，几何/交互锚点不动；完整画、叠图与实际尺度预览、来源哈希；美术审核后用新路径接入，保留旧照片资源 | 候选已交；未审画、未接入、未发布 | `GROK-BUILD` | [#168](https://github.com/narutojzm1-dot/youjia/issues/168)；文件在 `art/concepts/yard_overcast_aligned_v1/`。ART-DIRECTOR审画，CURSOR-CONTRIBUTOR-LOCAL在#51接自然转场，GAME-QA复测。 |


## 总体声音规划

| 编号 | 优先级 | 当前交付与验收 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- | --- |
| AUDIO-TONE-PROPOSAL | P1 | 60–90秒等响度附近A/B小院试听、分层和来源授权，标清候选未接入 | 用户已选 B；78 秒混音不是循环成品；未接入 | `GROK-BUILD` | [#170](https://github.com/narutojzm1-dot/youjia/issues/170)；用户于 2026-10-03 直接交给 GROK-BUILD。文件在 `art/concepts/audio_tone_v1/`。 |
| AUDIO-HOST-CONTRACT | P1 | 小院事件/混音/设置/Web生命周期与验收方案，复用现有音频设施 | 契约已成文，按工程督导条件修正；待独立审查，不阻塞#149/#150 | `CODEX-LEAD` | [#171](https://github.com/narutojzm1-dot/youjia/issues/171)；[宿主契约](architecture/audio-host-contract.md) |
| AUDIO-B-ASSETS | P1 | 现有院景的环境轨与轻音乐轨可分开调节；循环接缝有测量；不接运行时 | 分轨候选已交；未审核、未接入、未听验 | `GROK-BUILD` | [#194](https://github.com/narutojzm1-dot/youjia/issues/194)。文件在 `art/concepts/audio_b_stems_v1/`。不包含脚步、动物叫、快门。 |

来源#162；[分期计划](architecture/audio-delivery-plan.md)。用户已选 B，见 #170。#195 接入、#196 听验、#171 方案仍各归其主。本表不把候选写成正式资源或听感通过。


## Web 加载画面修复

| 编号 | 优先级 | 范围与验收 | 状态 | Owner | 记录 |
| --- | --- | --- | --- | --- | --- |
| QA-EXP-20261003-003 | P2 | 复用已有晴天小院资源恢复加载页风格；桌面/横屏/竖屏文字可读，进度/失败/重试/首帧与版本语义保持，正式发布后冷加载复核 | 已发布；公网三尺寸加载/重试核验通过，GAME-QA可复测 | `CODEX-LEAD-ASSISTANT` | [#167](https://github.com/narutojzm1-dot/youjia/issues/167)；GAME-QA复测，不改游戏或新资源方向。 |

## 用户指定独立 QA

| 编号 | 优先级 | 范围 / 验收 | 状态 | Owner |
| --- | --- | --- | --- | --- |
| QA-20261003-001 | P1 | 归档本轮体验报告与证据，补齐每天 08/12/16 冒烟、20 深测及报告 PR 规则；不开发修复 | 报告与规则完成原内容修订；GAME-PM解决集成冲突，候选待最终独立审核；持续测试 | `GAME-QA`（身份 PR164 已合入） |
