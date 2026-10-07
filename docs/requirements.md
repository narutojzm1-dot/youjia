# 需求列表

## 2026-10-06 用户新增：世界关联主线（#503）

Owner CODEX-LEAD（兼制作人）。[完整策划](design/connected-world-2026-10-06.md)；A大背篓、B地面投食、C同行、D动物隐藏发现、E的beibei收养/成长/成年同行及F1寻龟/水塘已发布并核验。F2鸡吃小米/成长由PR520发布game-eb0c657，F3鸡龟搭乘/鹅被拒故事由PR522发布game-a5713c0。完整CI、普通Web正向/重开、窄屏画布及公开包核验见[小米记录](playtests/2026-10-07-chick-millet/README.md)和[岸边关系记录](playtests/2026-10-07-pond-relationships/README.md)。此次完成已确认的首条关系故事，后续扩充及既有独立美术/UI/平台缺口不自动关闭。

| 编号 | 优先级 | 内容与验收 | 状态 / Owner |
| --- | --- | --- | --- |
| WORLD-BASKET | P1 | 院内大背篓UI查看既有探索所得，鱼可存取；共享账本迁移不丢不重、失败重试/重开、横竖屏 | 首片已发布 PR506，source 8777bf9；CODEX-LEAD；查看旧探索所得、鱼存取/重开已验证 |
| WORLD-GROUND-FOOD | P1 | 草/鱼投地可见；牛羊羊驼竞争取草、一次消费，院门附近多堆草可引来牛；保存与数量守恒 | 已发布 PR508，source d16736c；完整CI、原生/浏览器体验及公开PCK核验通过 / CODEX-LEAD |
| WORLD-COMPANIONS | P1 | 院门旁动物概率同行、羊驼可绳牵出；在外跟随且所有返院/恢复路径保留身份 | PR510已合入，149项及全套CI通过；game-4f6d18f公开PCK/十模块已核验，公开实玩记录见同行体验目录 / CODEX-LEAD |
| WORLD-ANIMAL-FINDS | P1 | 同行动物先翻找揭示隐藏物，玩家之后可见可拾；单次授予与回院持久化 | PR512已合入并公开发布game-f3ddfcb；92项/完整CI、公开包核验、正式Web返院重开已通过，详见体验记录 / CODEX-LEAD |
| WORLD-BEIBEI | P1 | 村边白色流浪幼犬beibei带回、养大、随行发现；成长缺席不受罚 | E收养/成长/成年同行由PR515发布game-53ec80c；43+46项和完整CI、公开包及正式Web收养/返院/重开已核验；本地普通存档自然成长/重开也通过。beibei找龟和水塘关系已由F分片接通；资源完善与新增关系继续由#504跟踪 / CODEX-LEAD |
| WORLD-POND-STORIES | P1 | beibei发现乌龟→带回池塘→与长大的鸡亲近/驮鸡→拒绝鹅骑背/鹅想啄；鸡吃小米 | F1 PR517、F2 PR520、F3 PR522均已发布；F3 game-a5713c0，完整CI、普通Web自然成长/关系照片及重开、390/568画布、公开PCK/存档模块核验通过，物理手机未验 / CODEX-LEAD |

资源需求单[#504](https://github.com/narutojzm1-dot/youjia/issues/504)保留完整画作、接触锚点、Web预算与来源门禁；地面小鱼、动物首处翻找及beibei幼年/成年画已接入，草复用既有原画；F首条故事所需乌龟/鸡及关系姿态已发布；牛羊羊驼低头接草的完整动作仍在#504后续队列，不以逻辑消费冒充全部取食动作完成。小米调查支持瑞士山脚村落栽培谷物的设定，不当作高山野生物。#150生产存档、#152/#153探索继续复用；#154自由布置仍待细化，不阻塞本主线。

> **2026-10-06 生效：** [用户最新团队与审核规则](collaboration/team-focus-2026-10-06.md)覆盖本文冲突的旧规则。本地 Leader 兼制作人，集中推进新功能/探索/资源；Assistant、Cursor Cloud 辅助修 bug，QA 独立测试，PM/制作人停止独立运转。取消逐 PR 强制独立子代理/他人审核，改为每日23:00发版前由Leader集中审查当天全部工作；必要测试、PR与发布核验保持。以下旧快照和审核记录仅保留历史，不作为新的等待条件。

这是代理认领与任务指定使用的活动列表。需求来源、决策过程与历史状态保存在 [产品决策与需求变更台账](decisions.md)；产品承诺和当前设计边界以 [游戏策划基准](game-design.md) 为准。

## 状态流转

`待产品决策` → 用户指导明确后 `待认领` → `已指定` / `进行中` → PR 打开后 `待评审` → 合入并验收后 `已完成`。

认领者通过 PR 修改本表的 Owner 与状态；Codex 确认后开始实现。未登记的 Agent-ID 不可认领；一个需求只能有一个负责人，多人协作时拆分不重叠子需求并分别分配。阻塞或方向变化要同步到本表、相关 PR 和台账。每个贡献者按最新集中交付规则提交 PR 和必要验证证据；取消逐项强制子代理终审，由 Leader 每日发版前集中检查当天全部工作。旧表中 Cloud 探索与独立 Producer 资源责任由本地 Leader 接续；在途 bug 修复保留其精确范围。

## 活动需求

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261002-001 | P0 | 校准角色走路速度和节奏，增加关键互动动作 | 默认速度不再停留在约 39 px/s；起步、停步和转向自然；抚摸/招呼/拿取/喂食至少有清晰动作与即时反馈；最新 Web 构建完成实际游玩复核。 | 进行中（PR #27 走速、PR #76 拿草/递草切片已发布；抚摸/招呼等动作待做） | `CODEX-LEAD` | PR #27 合入 `fce84fe`，默认参考速度约 61.4 px/s；回归、Web/Chromium 步行/停步/转向核验完成。[步态体验与发布记录](playtests/2026-10-02-REQ-001-locomotion.md)。拿草/递草由独立切片 REQ-001-GRASS 在 PR #76 完成；抚摸/招呼等仍是本需求未完成部分。 |
| REQ-20261002-002 | P0 | 解释橙色目标提示并明确当前行动对象 | 指示准确指向目标；显示动物/地点名称与动作；键盘、HUD 和点选操作目标一致；新存档玩家无需猜它是弹窗还是菜单。 | 待验收 | `MANUS-CONTRIBUTOR` | 用户 2026-10-02 指定；[实现 PR #25](https://github.com/narutojzm1-dot/youjia/pull/25)、[候选体验记录](playtests/2026-10-02-REQ-002-target-clarity.md)、[正式构建 game-9fe0d39](https://narutojzm1-dot.github.io/youjia/)；线上版本与 PCK 哈希已核对，真实移动动物点选和手机触屏尚未实玩验收。 |
| REQ-20261002-003 | P1 | 确定长期定位与停留/回访循环，评估轻放置 | 已确定轻陪伴为主、轻放置为辅；互动可以留下可感知的后续回响，缺席不造成惩罚。具体系统按 REQ-20261002-011 拆解。 | 方向已决策；系统设计进行中 | `CODEX-LEAD` | 用户 2026-10-02 确认；见[当前策划基准](game-design.md#一句话方向)与[台账](decisions.md)。 |
| REQ-20261002-004 | P1 | 增加大鹅和其他动物的动作、表情与互动回应；先修正大鹅始终张翅的问题 | 所有新增姿态保持同一角色的精致绘画质感；鹅在闲逛时可保留张翅个性，但安静时应收翅站立、休息时自然卧下，画作不靠变形冒充；切换接地、朝向、碰撞与相册不跳脚。其余动物还需有闲置和互动回应；最新 Web 构建复核前本条不标已完成。 | 鹅首切片已发布/已体验；其它动作逐片继续，父单开放 | `CODEX-LEAD` | [issue #33](https://github.com/narutojzm1-dot/youjia/issues/33)、[PR #34](https://github.com/narutojzm1-dot/youjia/pull/34) 和正式 `game-3e23a10` 浏览器卧姿实玩已核实；[增补决策](decisions/REQ-20261002-004.md)。REQ-001 主角步态仍由 `CODEX-LEAD` 负责。 |
| REQ-20261002-005 | P1 | 让时段、天空与天气可感知，并设计可辨认的季节变化 | 同一院子在早晨、正午、傍晚有可辨的光线变化；晴/阴与云层表现能被看出来，不只依赖全屏滤色；季节有环境或动物行为变化，首次变化时间可接受。新增云形、火烧云、雨雪或四季资源先列方案与成本，再制作。 | 进行中（既有时段云带已发布；同构图阴天/连续转场/照片兼容已发布；父项其他范围不自动完成） | `CODEX-LEAD`（本地兼制作人） | #168由PR486合709a3b7并完成公开Actions/Pages/manifest/PCK及十模块核验，已关闭；原Producer候选468/481与旧背景字节保留。[接续验收](playtests/2026-10-06-weather168-local/README.md)。其余时段/季节历史交付见#51与本文件Git历史；不由本次扩大到雨雪新玩法。 |
| REQ-20261002-006 | P1 | 深入体验最新版本并提出大型玩法顺序 | 完成最新 Web 构建的现场复核，记录步骤、截图、构建号、发现和优先级。 | 已完成 | `CODEX-LEAD` | [game-1347743 体验记录](playtests/2026-10-02-game-1347743.md) |
| REQ-20261002-007 | P1 | 验证携鱼过期时失效投喂追踪会取消且普通散步保留 | 线上实际完成钓鱼、选择鸭/鹅并等待鱼过期；确认角色停止追踪无效目标且普通散步不受影响；记录构建和证据。 | 待验收 | `CODEX-LEAD` | [PR #19](https://github.com/narutojzm1-dot/youjia/pull/19)、[发布核查](playtests/2026-10-02-game-b82a7f5.md) |
| REQ-20261002-008 | P0 | 所有主动交互都有可感知的对象或场景正反馈；已分批补鸭鹅投鱼、抚摸与浇水 | 鸭鹅成功投鱼只对被喂鸟回应；牛/羊/马抚摸只对命中的动物回应；花圃当日首次有效浇水才显示水彩回应。距离不足、鱼过期、重复浇水均不得庆祝，低动效仍可读；羊驼喂/牵、种花/收获及其它交互继续盘点，不得提前标整条需求完成。 | 进行中（鸭鹅投鱼及双羊关注已发布并有限公开验收，其他反馈逐片继续） | `CODEX-LEAD` | [issue #30](https://github.com/narutojzm1-dot/youjia/issues/30)、[决策记录](decisions/REQ-20261002-008.md)、[投鱼 PR #32](https://github.com/narutojzm1-dot/youjia/pull/32)、[抚摸与浇水 PR #35](https://github.com/narutojzm1-dot/youjia/pull/35)；正式 `game-3e23a10` 已核对清单和 PCK。最新鸭成功投鱼切片使用Producer343已交关注原画，2.2秒静态注意、5秒视觉间隔，移除鸭默认爱心；该鸭切片当时不改变鱼消费或鹅反馈，见[证据](playtests/duck-feed-attention.md)，PR353最终c0b02dc独审合a936bea，实际公开包/自然投鸭验证见[发布记录](playtests/2026-10-05-exploration-duck-release/README.md)；接食资源122、其它互动继续，REQ-001主角动作仍属并行工作。 鹅成功投魚收翅关注候选由Leader按5994160535接续，复用既有goose_calm，2.2秒/5秒视觉间隔、去鹅默认心；不称接食/新玩法，不改消费、骑马或hold_expression3.5。PR367已独审合入并公开game-a067ce9，宽窄自然成功投鹅及走开已体验；[公开证据](playtests/2026-10-05-goose-hotspots-release/README.md)，照片回放及全组合未验，不称#30整体完成。 双羊PR395已发布，普通成功轻抚与自然共享首照真关页后窄屏回放已[有限公开验收](playtests/2026-10-05-sheep-attention-release/README.md)，非121/30全完成。  #36 当前公开三热点及钓鱼在途优先级已补[限定验收](playtests/2026-10-05-yard-hotspots-public/README.md)（源1a3842c）；后在源a067ce9补[花箱/岸石两处模拟触屏](playtests/2026-10-05-goose-hotspots-release/touch/README.md)；后续PR398补[栅栏模拟触屏有限验收](playtests/2026-10-05-hotspot-fence-touch/README.md)；低动效用户入口、物理手机、即时打断及完整携物仍未覆盖，不能据此全项结案。 |
| REQ-20261002-009 | P0 | 将可见小院细节变成可发现、可随时打断且保持精致绘画的场景交互和彩蛋 | 首批逐处验收花箱、池塘岸石和木栅栏真实画面命中、院内安全站位、键鼠/触屏/HUD 同目标、独立水彩回应；蝴蝶、蜻蜓、棚檐羽毛等无收益偶遇可在正常散步见到，无签到/任务/错过惩罚。保留钓鱼、植物和动物优先级、低动效及旧存档。叠加型草叶**不等于真正能开木门**，原背景物件替换/多热点规模化仍需单独验证。 | 首批花箱/岸石/栅栏已发布；完整当前体验收口待补，后续方向保留 | `CODEX-LEAD` | [issue #36](https://github.com/narutojzm1-dot/youjia/issues/36)、[需求记录](decisions/REQ-20261002-009.md)、[背景架构](architecture/painted-yard-interactions.md)、[PR #38](https://github.com/narutojzm1-dot/youjia/pull/38)、[#39](https://github.com/narutojzm1-dot/youjia/pull/39)、[#41](https://github.com/narutojzm1-dot/youjia/pull/41) 与正式 `game-df8b92d` 公网 PCK 校验。REQ-001 走速切片已在 PR #27 合入发布；其互动动作继续独立推进。  #36 当前公开三热点及钓鱼在途优先级已补[限定验收](playtests/2026-10-05-yard-hotspots-public/README.md)（源1a3842c）；后在源a067ce9补[花箱/岸石两处模拟触屏](playtests/2026-10-05-goose-hotspots-release/touch/README.md)；后续PR398补[栅栏模拟触屏有限验收](playtests/2026-10-05-hotspot-fence-touch/README.md)；低动效用户入口、物理手机、即时打断及完整携物仍未覆盖，不能据此全项结案。  低动效Web系统偏好入口候选由Leader承接5998347852，见[有限验证](playtests/2026-10-05-web-reduced-motion/README.md)；未提前声称生产/物理设备及全部在途效果通过。 |
| REQ-20261002-010 | P0 | 旅人随手拍：替换莫名镜头推近，让真实新照片形成、写当天短句并可见地收入相册 | 仅首次有效抓拍且持久保存后显出**同一张真实快照**，照片定日期与规则事件的中英短句；暂停/移动/开相册随时打断展示但不丢照片。低动效静帧，重复事件不重播；旧档无日期不伪造日期且原相册仍可看。通过实际事件、原生/浏览器画面和完整回归核验。 | 已验收发布（#40范围完成） | `CODEX-LEAD`（原实现MANUS保留） | PR43/102/233/308/320及PR336生产确认接线；普通动物、首次鱼自然公开关页恢复已通过，大鹅骑马受控证据单列，旧档/低动效/中断回归保持。见[完整验收与公开哈希](playtests/2026-10-05-production-save-release/README.md)。自由构图/新增关系故事和动作美术仍分别在#48/#45/#180。 |
| REQ-010-SUBTLE | P0 | 留影固定显影并原位淡出，移除飞行缩放与收尾按钮弹跳 | 真实照片保持中心位置与完整大小；原位淡入淡出；保存先于展示；暂停/移动/相册可中断且不丢照片；低动效可读；最新主线回归、Web 实际抓拍与最终 SHA 独立审核通过。 | 已发布；game-562ad5d 清单与 PCK 已核对 | `CODEX-LEAD` | 父 REQ-010 的历史归属保持 MANUS；[PR #102](https://github.com/narutojzm1-dot/youjia/pull/102)、[决策](decisions/REQ-010-photo-arrival-subtle.md)、[体验](playtests/2026-10-03-REQ-010-photo-arrival-subtle.md)。 |
| REQ-20261002-011 | P1 | 让玩家互动在之后留下轻微、可感知的世界回响与后续故事 | 以稀疏、可解释的动物关系记忆产生可观察的相处变化；关系因真实共同经历改变并兼容旧档，不做显眼数值任务或缺席衰退，保留随机性。先完成已获产品确认的鹅—羊驼切片，再依据试玩决定是否扩展，不建设通用剧情引擎。 | 已发布；普通牵引记忆/关页恢复已有限实测，10%回响未实证 | `CODEX-LEAD` | 制作人于 2026-10-03 确认“玩家牵引羊驼靠近大鹅、双方安静共处后留下记忆”。[PR #71](https://github.com/narutojzm1-dot/youjia/pull/71) 独立审查批准最终 SHA `219ed34d5299aeaa0e8eff53ec2f6e7f7683d045` 并合入 `main`（merge `6dacd879ea0a2bac724ecfd548779e5d40c44308`）；[Actions 37090111095](https://github.com/narutojzm1-dot/youjia/actions/runs/37090111095) 成功。Pages 清单指向 `game-6dacd87` / source commit `6dacd879ea0a2bac724ecfd548779e5d40c44308`；公网 PCK 12,783,108 字节，SHA-256 `96be444adf13de8d87cb374b0abccf1ac2998f28e7ad8978d4d85c5759fbf29c`。该片复用现有画作，无新资源依赖；#56鹅马后续已另行实现：PR99画帧、PR173接线，完整组合验收由Assistant #180继续；不以原第一片71的历史状态阻塞后续。[issue #45](https://github.com/narutojzm1-dot/youjia/issues/45)、[#56](https://github.com/narutojzm1-dot/youjia/issues/56)。 2026-10-06在正式`game-089d453`完成一次普通牵离→带回→放开→记忆落盘→真关页恢复，原羊照及关系保留；90秒自然观察未能证实10%停留回响，[原始证据与边界](playtests/2026-10-06-relationship45-public/README.md)，#45仍开放。 |
| REQ-20261002-012 | P1 | 让熟悉的小院随时段天空和玩家构图反复呈现新意 | 同一场景通过晨/午/晚光线、云形与天气、树水细节和偶发趣事支持反复观看；摄影探索玩家选择角度、前景和画面关系的可能性。可研究轻量场内摄影演出：主人静坐时，动物事件从远景进入、经主人视角跟随后聚焦近景并留下照片。先验证美术方案、操作可读性、资源成本与 Web 性能；汽水瓶仅为构图例子，不预设具体道具或 UI。保留安静停留和随机探索，不加入打卡/集齐目标。 | 既有观察切片已交；308已移除强缩放；D延期，自由取景方案未批准 | `CODEX-LEAD` | [#48](https://github.com/narutojzm1-dot/youjia/issues/48)。保留LOCAL既有A云带、B草叶PR85、C抬头PR88/94成果；[PR308](https://github.com/narutojzm1-dot/youjia/pull/308)已移除旧C的1.14推近，旧[体验记录](playtests/2026-10-03-REQ-012-quiet-sky-look.md)仅属历史。D仍延期，手动取景UI/前景道具未具体批准，不重复等待已实现Host。  已补[首片A设备导出/B游戏手账/C延期选择材料](design/framing48-first-slice-options.md)，仅提案未批准、未实现。 |
| REQ-012-STAY | P1 | 站在栅栏边时，用已有草叶画让院子轻轻动一下 | 停住约 2.5 秒才播一次现成草叶，走路立刻停；不新增提示、相册或美术；不改云带速度，不改羽毛偶遇。 | 已合入（原记录无界面测试通过；该切片网页实玩未补证） | `CODEX-LEAD`（维护；原作者GROK-BUILD） | 父需求REQ-20261002-012当前Owner为CODEX-LEAD；保留[PR85](https://github.com/narutojzm1-dot/youjia/pull/85)原作者成果，合并36fa443。[原记录](playtests/2026-10-03-REQ-012-STAY.md)不冒称新Web验收。 |
| REQ-20261002-013 | P0 | 真实可拍动物偶遇、稳定的有限题词与可翻旅人手账 | 大鹅完整卧姿、两羊靠近、池边鸭鹅须实际可见并真实入镜；题词只在首次成片保存变体，旧照不改写、中英切换和重开稳定；宽屏双页、手机单页，按钮/左右键/触摸翻页可靠。只浏览已拍记忆，无锁定槽、红点或完成率。 | 已发布；用户正式版试玩待反馈 | `MANUS-CONTRIBUTOR` | [PR #53](https://github.com/narutojzm1-dot/youjia/pull/53) 合并提交 `b560dec94f08a1597e2b834e74c41841893ba36b`；[Actions 37025345857](https://github.com/narutojzm1-dot/youjia/actions/runs/37025345857) 成功；正式 `game-b560dec` Pages PCK 12,776,620 字节，SHA-256 `e5b9c3f931b957ac4dd288e1c6786f6b9fc1d9ace946eac711e3bed723ac3d58` 已从公网核验；[体验记录](playtests/2026-10-02-REQ-013-scrapbook.md)。与 REQ-011 世界回响及 REQ-012 天空/自由构图分离。 |
| REQ-20261002-014 | P1 | 实现“大鹅骑上马背扑腾翅膀”场内摄影演出切片 | 玩家在院内停留观察时，满足温和空间与节奏条件后触发；演出包含远景、旅人第一视角感镜头、鹅马近景和扑翼；移动可立即打断；结束拍摄真实现场并保存稳定中英题词，可从相册回看；不重复刷取、不影响旧档、低动效可读。 | 已合入发布；自然触发实玩待补 | `CODEX-LEAD` | PR #65 最终 SHA `f7f2d0686753f798055809ef23c465d9fc237b0c` 经独立审查 APPROVE，合入 `521e6c2180284ab80aa914ec78e0ed513af960ed`；PR #72 验证补丁已并入 #65 后关闭。Actions [37092968010](https://github.com/narutojzm1-dot/youjia/actions/runs/37092968010) 成功；Pages `game-521e6c2` 对应源提交 `521e6c2180284ab80aa914ec78e0ed513af960ed`，公网 PCK 13,742,972 字节，SHA-256 `d46351fbac8d1bbe3d11de110cdbe8001a7cb805bbae07b40e16ffe97be54c1a`。公网 Chromium 1280×720 加载成功、无脚本错误或请求失败。自然等待未观察到完整演出；此为历史占位证据；PR #173已接入两帧成品画，当前组合验收见[issue #180](https://github.com/narutojzm1-dot/youjia/issues/180)。历史资源见 [issue #64](https://github.com/narutojzm1-dot/youjia/issues/64) 和[验收记录](playtests/2026-10-03-REQ-014-verification.md)。 |
| REQ-20261002-015 | P1 | 为大鹅骑马抓拍补一张完整的乘骑扑翼画 | 规格写清脚必须踩在马背上、不能用站立鹅冒充、画布/锚点/朝向/体积上限；画切片只交付成品 PNG 与运行时注册，不改演出脚本。 | 资源及导演接线已合入；最终SHA后置复审已通过；组合验收代码推导记录已产出（见 issue #180 评论与 docs/playtests/2026-10-05-REQ-015-acceptance.md），运行时Web证据仍待补，#180 保持开放 | `GROK-BUILD`（规格切片）／`WORKBUDDY-CONTRIBUTOR`（成品画切片） | 规格见 [architecture/goose-mount-pose-spec.md](architecture/goose-mount-pose-spec.md)。PR #65 已把临时换帧接到 `show_goose_encounter_cel`。产品已于 2026-10-03 确认「两张交替」而非一张：`WORKBUDDY-CONTRIBUTOR` 交付 `goose_riding_up`/`goose_riding_down` 两帧成品画（1254×1254、脚底锚点对齐后残余 ≤0.5px、`native_facing=1`、均小于 `goose.png` 的 1,212,584 字节上限），并在 `cast_art.gd` 暴露 `riding_up`/`riding_down`。导演接线仍属 REQ-014 / `CODEX-LEAD`，本切片不改 `yard_world.gd`／`FeltActor`。**PR #99 已于 2026-10-03 合并**（merge `5b695043`，head `f2d2fc21`，三轮独立评审终轮 APPROVE 无阻塞）：两帧已在 main，`cast_art.gd` 已注册 `riding_up`/`riding_down`，可被引擎直接取用；导演接线已由 `WORKBUDDY-CONTRIBUTOR` 于 2026-10-03 跨越切片边界实施（用户明确授权）：[PR #173](https://github.com/narutojzm1-dot/youjia/pull/173) 将 `yard_world.gd` 鹅马乘骑演出的 `show_goose_encounter_cel` 帧交替由占位 `idle`/`calm` 改为真正的 `riding_up`/`riding_down`，沿用既有 0.28s 扑翼时钟与低动效定帧，资源/接线历史单#64已关闭；最终完整SHA `0066cef9da621530d05d5ad8051be684512ce88c` 后置独立复审已通过（reviewer `CODEX-LEAD-ASSISTANT-REVIEW-PR-173-FINAL`，[证据](https://github.com/narutojzm1-dot/youjia/pull/173#issuecomment-5971467561)），不追认原始合入门禁；组合Web验收仍由[issue #180](https://github.com/narutojzm1-dot/youjia/issues/180)跟踪，当前Owner为CODEX-LEAD-ASSISTANT，原WORKBUDDY提交保留。 |
| REQ-20261002-016 | P0 | 为旅人递草喂羊驼设计第一组可读互动动作规格 | 盘点现有旅人图集；提交递草前、递出、羊驼接收、收回手臂的动作分镜和锚点/时长/打断/低动效/Web 体积规格；不改玩法逻辑、不制作最终帧，待产品确认后再另开实现任务。 | 待产品确认（规格已提交；动作候选已在 main） | `GROK-BUILD` | 原表写成 `GROK-CONTRIBUTOR`。用户让 Grok Build 做这项指定，故改为 `GROK-BUILD`，不代表接管 GROK BOT 的其他事项。规格见 [architecture/resident-grass-offer-spec.md](architecture/resident-grass-offer-spec.md)。帧已由 REQ-001-GRASS / PR #76 先合入，本需求不另做第二套画。[issue #70](https://github.com/narutojzm1-dot/youjia/issues/70)。 |

| REQ-20261003-001-ACTION | P0 | 为招呼/抚摸成功反馈拆分旅人短动作切片提案 | 盘点现有旅人帧与成功/取消路径，提交短时、可打断、低动效/Web 可读的动作方案；不改距离判定和行为语义，不新增关系值/任务；资源方向先由产品确认。 | 提案及资源子单123已交；最终动作资源/方向核对未完 | `GAME-PRODUCER`（资源；Leader后续行为接入） | [#84](https://github.com/narutojzm1-dot/youjia/issues/84)、[#123](https://github.com/narutojzm1-dot/youjia/issues/123)。三姿态样张方向已拆，资源交接尚待实际接收；不是无人认领，也不是最终动作已批准。主角成功/打断接入由Leader协调，独立于既有拿草/递草与动物回应。 |
| REQ-20261003-017 | P2 | 低动效下花圃、水面涟漪和咬钩浮标保持静止可读 | 开启低动效时嫩芽不左右倾、开花不摇不闪、收获花瓣停在原地、水面只留一圈静止涟漪、咬钩浮标保持红色稳圈而不是快速闪烁；关闭低动效时原有轻摇、三圈涟漪和咬钩明暗仍在。不改钓鱼规则、存档或新资源。 | 已合入发布；正式试玩待反馈 | `GROK-CONTRIBUTOR` | 用户 2026-10-03 让 GROK-CONTRIBUTOR 自选无主切片。不改 REQ-001 抚摸/招呼、REQ-005/012 云带、REQ-008/009 动物与热点、REQ-014/015 鹅马。原绘制提交随 [PR #104](https://github.com/narutojzm1-dot/youjia/pull/104) 集成，兼容验证归下方 REQ-017-VERIFY；首次正式版本 `game-1949dc4` 已核验。 |
| REQ-001-GRASS | P0 | 主角拿草与递草身体动作 | 定稿居民完整帧、固定脚底；成功才演出，移动和低动效可打断；不延迟库存或喂食；实际 Web 复核。 | 已完成（独立切片已发布） | `CODEX-LEAD-ASSISTANT` | [issue #73](https://github.com/narutojzm1-dot/youjia/issues/73)；父 REQ-20261002-001 Owner 保留。仅 Vacationer / SequenceResident、动作帧、独立验证；YardWorld 既有喂草调用只传入对象位置。[PR #76](https://github.com/narutojzm1-dot/youjia/pull/76) 合入 `6c1d6f0`；独立审核和全量回归通过，正式 `game-6c1d6f0` 公网版本与 PCK 已核验；Web 正常拿草/喂草成片及受控完整动作复核。父需求的抚摸/招呼仍待做。[验收记录](playtests/2026-10-03-REQ-001-grass-actions.md)。 |

#150 共享提示增量候选：探索 reject 后同趟新 op 重交，以只读业务身份关联旧故障；不因任意新保存或 ready 清面板，保留未保存照片与其他领域失败。详见[候选验证](playtests/2026-10-05-exploration-retry-feedback/README.md)，最终审查/发布另记。

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
| ART-ACK-COW | P0 | 牛：成功互动后的抬眼与温和回应 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 样张已交；成功抚摸glance已接；资源余项交接待回执 | `GAME-PRODUCER` | [#119](https://github.com/narutojzm1-dot/youjia/issues/119)。保留GROK-BUILD候选art/concepts/ack_cow_v1/；Leader的#30已有牛抬眼回应，不重画已接部分，其它资源/行为分别验收。 |
| ART-ACK-HORSE | P1 | 马：注意玩家与接受轻抚的回应 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 关注样张/同尺度对照已交；候选未接；资源余项交接待回执 | `GAME-PRODUCER` | [#120](https://github.com/narutojzm1-dot/youjia/issues/120)、PR145/286。胸背臀线/透明碎点仍待资源核对；#30已用既有idle停步面向玩家，不等于attend候选接入。PR304停用尺寸异常tail是另一休息姿态切片，原资源保留。 |
| ART-ACK-SHEEP | P1 | 两只羊：保留个性的互动回应 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；成功轻抚/中断/照片另验 | PR395已合入发布；双羊轻抚及共享首照已有限公开验收 | `GAME-PRODUCER`（资源）/ `CODEX-LEAD`（接入） | [#121](https://github.com/narutojzm1-dot/youjia/issues/121)、[#30](https://github.com/narutojzm1-dot/youjia/issues/30)；精确bccf132黏人v2/呆羊v3逐字复用，保idle脚锚/比例及2.2秒/5秒规则；[接入证据](playtests/2026-10-05-sheep-attention/README.md)。[公开证据](playtests/2026-10-05-sheep-attention-release/README.md)：source10a32bb、实际PCK及十模块核验，正常双羊轻抚与真正关闭浏览器后的窄屏共享首照回放通过；玩家遮挡、真机及全组合边界保留。旧166候选保留，不称121/30全完成。 |
| ART-ACK-BIRDS | P1 | 鸭与鹅：自然关注和接食姿态资源 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | Producer已交鸭attention v2；353已发布；接食/鹅资源余项继续 | `GAME-PRODUCER` | [#122](https://github.com/narutojzm1-dot/youjia/issues/122#issuecomment-5993062341)。PR343最终45ef92b9e3afe94a4df0648caa90c37394d7870e原PNG由Leader接入353并发布；仅闭嘴关注，不等同接食/咀嚼或鹅完整资源已交。鹅先复用calm/rest盘点，公共成功行为接入归Leader。  嘴前相遇研究契约/29项模型与受控院景已交，生产attend未替换，见[契约](architecture/duck-feed-contact-contract.md)。 |
| ART-RESIDENT-PET | P1 | 旅人：自然轻抚动作的三姿态样张 | 同角色完整画作、稳定接触锚点、透明边界、原尺寸/镜像预览、来源哈希与预算；样张核对后再扩帧，接入单独验收 | 三姿态分镜/接触规格已提；最终帧未交，资源交接待回执 | `GAME-PRODUCER` | [#123](https://github.com/narutojzm1-dot/youjia/issues/123#issuecomment-5968891249)、#84。需A/B/C手锚、左右接触、适用高度及B静态与递草区别材料；不把提案尺寸当最终批准，不改距离或拉伸主角凑接触。Leader后续接入另验成功/打断/低动效。 |


## 扩大旅人可走范围

| 编号 | 优先级 | 需求 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-WALK-EXPAND | P1 | 扩大院内连通可走空间，分离玩家与动物安全边界 | 标定真实落脚/禁行/遮挡，原区域可达；统一键鼠触屏/路径/追踪与牵引，镜头/透视自然；方案核对后独立实现并完整回归/Web验收 | PR346标定已合；生产边界未改，Producer脚点/遮挡核对待回执 | `CODEX-LEAD` | [#125](https://github.com/narutojzm1-dot/youjia/issues/125#issuecomment-5992215318)、[分期计划](architecture/player-walk-area-expansion.md)。PR346最终d65ca19f3cc7deafb3843691a64fa676effaeab5已独审合55cb7ce；门前候选y672超既有网格y660，获具体区域核对后由Leader同步路由/网格，不扩大动物区。 |
| ART-GROUND-EXPAND | P1 | 扩展候选地面的资源盘点与补绘提案 | 现画可用则不重画；补绘同院子晴阴坐标/遮挡一致、来源锚点与预算齐全，具体方案确认后制作 | 已指定；实际接收待回执，依赖125已交标定的脚点/遮挡核对 | `GAME-PRODUCER` | [#126](https://github.com/narutojzm1-dot/youjia/issues/126)；依赖REQ-WALK-EXPAND，协调#168/#51当前Producer同构图底板，不抢动物资源订单。 |


## 工程门禁：异常退出不得当作验证通过

| 编号 | 优先级 | 工作范围 | 验收条件 | 状态 | Owner | 依赖 / 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| VERIFY-EXIT-GATE | P0 | 修复每日Godot回归忽略非零退出码的发布门禁漏洞 | Godot/timeout和tee任一非零、错误/FAIL日志或日志读取失败均阻断；11项故障注入与严格完整回归、独立最终SHA审查通过 | 已合入并核验发布；PR134独立审查批准、主线严格回归/导出/Pages与公开包一致性通过 | `CODEX-LEAD` | [工程督导#130](https://github.com/narutojzm1-dot/youjia/issues/130)；不包含存档协议、完成标记或PR验证workflow。[证据](playtests/2026-10-03-verify-exit-gate.md)。 |
| VERIFY-SUITE-COMPLETION | P0 | 拒绝Godot测试零退出但断言未完成的假通过 | 每个daily测试登记准确整行完成格式、报告数量时必须为正数且零失败；未知入口、缺标记、日志读取失败或完成后异常均阻断；import/export不冒测试完成 | 452最终6ce49dd1b1943cc8ad1198dc7bbdd8fa6cd945ee独审6002899029合16ef89a2；真实全daily/Web导出通过；发布来源6003421082已核 | `CODEX-LEAD` | [原单#130认领](https://github.com/narutojzm1-dot/youjia/issues/130#issuecomment-6002422874)；50受控包装器案例、71套完成行/72次Godot启动；[契约与原始证据](engineering/godot-completion-gate.md)。只收完成标记子范围，PR450只读验证workflow已独审/真实PR CI/合入/发布来源核验完成，#130长期单不整体关闭。 |
| VERIFY-PR-130 | P1 | 在 PR 合入前运行只读回归与 Web 导出 | main 目标 PR 执行现有发布辅助检查、严格 daily 与真实 Web 导出；无仓库写入/Pages 发布；本 PR 实际 Actions 与独立最终 SHA 审核通过 | 450最终87bd1e09905a014e843f677ab9379d9b9a05dbce独审6003099730，真实PR CI37373896187成功后合d788f48b；非branch protection/Pages验收 | `CODEX-LEAD` | [#130认领](https://github.com/narutojzm1-dot/youjia/issues/130#issuecomment-6002379027)；[验证与边界](validation/2026-10-06-pr130-verification.md)。仅新增 PR 检查，不配置 branch protection，不替代 main 发布复验；452完成标记子范围已交；父130其余范围仍开放。 |
| VERIFY-PR-SOURCE-130 | P1 | PR 只读取源仅排除根 docs，保留全部运行资源与验证输入 | proposed merge/只读权限/全部原验证不变；隔离 Git 正反例、无 docs 的72套真实回归及 Web 导出通过；最终 SHA 独审和真实 PR CI 均通过后合入 | 458最终6862b4c65b6c037fa2319a38ed12f7f0238168b7独审6004586550/真实CI37382704512合870f4fa，发布6004738969来源已核；不承诺每次加速 | `CODEX-LEAD` | [#130认领6003973038](https://github.com/narutojzm1-dot/youjia/issues/130#issuecomment-6003973038)；[源码依赖、机制与原始验收](engineering/pr-ci-source-sparse.md)。不改 publish-pages/保留策略，不删除仓库证据，不据此关闭#130父单。 |
| VERIFY-PUBLISH-SOURCE-130 | P1 | Pages发布取源保完整历史并仅排除根docs | 保持depth0/ref权限/helper/全部验证与发布；完整历史/partial/sparse真实Git正反例与原publisher验证通过；最终独审及真实PR CI、main发布验收通过 | 候选已实现；六配置30保留、12本地构建/6缺PCK拒绝通过；462最终a6fc9beb63fc793b46097cd3827e6b705ff1e324独审6005260117/真实CI37387083818成功合b300da74bf157de3f152e63331096cb1eb28b3f7；460后验已closed；main37387842699/Pages37388592826成功，23:31公开manifest/PCK/10模块/许可页6005477012核验通过；实际保留4包/旧模块，非性能保证 | `CODEX-LEAD` | [#130认领6004968169](https://github.com/narutojzm1-dot/youjia/issues/130#issuecomment-6004968169)；[机制与原件](engineering/publisher-source-sparse.md)。保留full history，非depth1；fixture不是生产发布/性能保证，父130继续开放。 [正式main/Pages来源链](playtests/2026-10-06-photo454-public/main462/main-pages-review.md)、[公开PCK/十模块](playtests/2026-10-06-photo454-public/releases/pr462-public-release.json)。 |


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
| STATE-SAVE-RECOVERY | P0 | 存档提交/恢复，真实失败注入与旧v5/照片/平台持久化不丢进展 | 原 #149 验收范围完成：生产 PR336 最终720db375独审合d242509并发布；公开羊/首次鱼照片关页恢复、55cb7ce真实提交中关页恢复旧完整封套均通过，PR347归档，#149已结项。物品/探索领域组合继续归#150，不以旧实验Host等待阻塞正式开发 | `CODEX-LEAD` | [#149](https://github.com/narutojzm1-dot/youjia/issues/149)；[正式发布与覆盖限制](playtests/2026-10-05-production-save-release/README.md)。 |
| STATE-YARD-GROWTH | P1 | 物品/布置/探索结果共享契约与迁移/去重提交矩阵 | 生产Host已接入并发布：PR336共享持久化、PR322探索异步队列已由Cloud实际消费；bc213f9公开原画拾物回院/关页、390携物中断恢复完成，带回物单次授予。#150保持开放：多物品/换物、领域故障与跨页面组合须分别验收，正式布置规则仍待；Leader非照片unknown恢复提示PR357最终959c5318独审合33b105f并公开，一次确认撤提示/真实关页重开已验（[实现](playtests/2026-10-05-save-feedback/README.md)、[公开](playtests/2026-10-05-save-feedback-release/README.md)）；原PR190/251由生产实现替代，旧239/261隔离矩阵保留为历史证据，不继续写未接入Host | `CODEX-LEAD`（共享领域契约），`CURSOR-CLOUD`（探索侧305矩阵） | [#150](https://github.com/narutojzm1-dot/youjia/issues/150)；[实际公开证据与未覆盖](playtests/2026-10-05-exploration-duck-release/README.md)。  PR379已发布d707113，公开三物各1的trip失败后一次确认、后继提交与正常cleanup、同页提示最终消失和真关页DB一致已验，4秒暂态仍有禁用提示；[限定公开证据](playtests/2026-10-05-exploration-retry-release/README.md)。独立cleanup写失败领域恢复仍未修复；共享API已由PR391冻结合入并发布4fa150，Cloud idle接收待回执，不据此关闭150/305。 |
| EXP-CONTRACT | P1 | 独立探索边界/快照/宿主确认/失败恢复契约，与共享状态对齐 | 纯核心已按设计稿实现（2026-10-05 授权独立推进，不再以联合冻结为前置）；依赖 #150 的项（平台持久化结果未知、物品身份/共享区）仍未冻结，归 CODEX-LEAD | `CURSOR-CLOUD` | [#151](https://github.com/narutojzm1-dot/youjia/issues/151)；[契约设计稿](architecture/exploration-module-contract.md)，与#150待共同冻结项列于其第10节；不含正式地点/物品/形式。 |
| EXP-CORE | P1 | 形态无关核心状态机/恢复/返回，严格隔离测试；夹具不正式发布 | 进行中：用户 2026-10-05 授权 CURSOR-CLOUD 独立推进、不再以契约冻结为前置；核心与正式近郊目录随 `scripts/exploration/` 合入 main，隔离 suite 纳入 strict daily；PR176 草案由此取代 | `CURSOR-CLOUD` | [#152](https://github.com/narutojzm1-dot/youjia/issues/152)；依赖/正式内容门禁见工单。 |
| EXP-FIRST-SLICE | P1 | 确认的一条近郊往返，空手/取消/重复提交/键鼠触屏低动效与正式发布闭环 | 进行中（用户 2026-10-05 授权独立推进）：正式游戏内往返已接入（小院左下石板路「出门走走」→ 画卷近郊小路看景/带上/放回/换 → 随时回院；SaveStore 异步存档队列记录探索与带回物，确认后才授予（不等于 #150/Web 持久化验收），重启安全回院；见[接入说明](architecture/exploration-near-path-slice.md)与[体验证据](playtests/2026-10-05-exploration-near-path-slice/README.md)）；横向画卷只是过渡占位：用户已选“保留原画视角，沿路走动并自然换页”（[原画路径方向](architecture/exploration-painted-path-direction.md)），表现层已由 EXP-PAINTED-PATH 换成 02 原画沿路行走，本行交付的是外出/回院逻辑、持久化与容量；正式资源归 GAME-PRODUCER；#150 正式 Host 回执仍归 CODEX-LEAD；单趟合计最多 3 件（用户 2026-10-05 决定，同名可重复，第 4 件为「换成」）已实现，见[容量证据](playtests/2026-10-05-exploration-carry-three/README.md)；出现权重为实验参数待制作人决定；#305 剩余矩阵（多趟多物品、装满 3 件、换物、回院途中关页、写入失败→结果未知→查明、双页、连按回院）已在公开 `7c1608c` 实测，见[矩阵证据](playtests/2026-10-05-exploration-305-matrix/README.md)，验收结论归 PM / Codex | `CURSOR-CLOUD` | [#153](https://github.com/narutojzm1-dot/youjia/issues/153)；依赖/正式内容门禁见工单；形式已定：[画卷漫步](architecture/exploration-form-options.md)（用户 2026-10-03）；首地/首物已定：近郊小路＋圆石、松果、落羽都可遇见（用户 2026-10-04，见 EXP-UNBLOCK-20261004），具体构图与资源由 GROK-BUILD #155 交付。 |
| EXP-PAINTED-PATH | P1 | 按用户已决“保留原画视角，沿路走动并自然换页”把首片近郊表现换成 02 原画上的沿路行走：脚点在路上、人物远小近大、原画不拉伸；桌面完整构图，手机固定缩放随人物平移；键鼠/触屏可走、可停、可看、可放回、可随时回院；核心/宿主/存档不重做 | 进行中（CURSOR-CLOUD 按[执行方向](architecture/exploration-painted-path-direction.md)接收）：首版已在 `02_near_path.png` 候选上沿制作人候选路线（near_path_anchors.candidate.json）实现单条双向可走路、四处停留点、点按沿路走、方向键沿路投影、院门口回院，见[原画沿路证据](playtests/2026-10-05-exploration-painted-path/README.md)；PR #342 已合入（`bc213f9`），公开 Web 版 `bc213f9` 往返与关页重开后带回物仍在已复核，见[公开 Web 证据](playtests/2026-10-05-exploration-web-public/README.md)（不是 #150/#176 验收）；停留点/比例/物件位置为实验参数待制作人按取景核对；画内松果/落羽已换成制作人清底版（#393 `c2f342d`，清底 PNG SHA256 `ade3ee41…487b`），见[换图前后对照](playtests/2026-10-05-near-path-clean/README.md)；用户反馈 #399“点院门回不了院”已修：点按/触屏落在院门一带，走到门口即回院，见[点院门回院证据](playtests/2026-10-05-near-path-tap-home/README.md)（非公开 Web/真机验收）；正式小物精灵、相邻页换页（03 未交付前木桥不作出口）待 GAME-PRODUCER 资源；频率/掉率未定 | `CURSOR-CLOUD` | [#153](https://github.com/narutojzm1-dot/youjia/issues/153) / [#155](https://github.com/narutojzm1-dot/youjia/issues/155)；依赖 EXP-FIRST-SLICE（PR #322）；资源 GAME-PRODUCER |
| EXP-FIND-REVEAL | P2 | 用户经制作人转达（#155 5993470040）：首片拾起成功后有短展示与原创“获得”音，先在近郊看透视、比例、遮挡、展示与声音是否协调 | 进行中（CURSOR-CLOUD）：程序切片按[契约](architecture/exploration-find-reveal.md)实现：带上/换成成功后升起→停留→飞进提篮，低动效原地淡入淡出，可随时打断，不影响存档；见[帧证据](playtests/2026-10-05-exploration-find-reveal/README.md)；独立物件贴图与原创短音待 GAME-PRODUCER 按契约 §4 交付，缺失时安静降级；时长/位置/举物/音色为候选值，等用户看过演示再定 | `CURSOR-CLOUD` | [#153](https://github.com/narutojzm1-dot/youjia/issues/153) / [#155](https://github.com/narutojzm1-dot/youjia/issues/155)；依赖 EXP-PAINTED-PATH；资源 GAME-PRODUCER |
| EXP-SCROLL-PROTOTYPE | P1 | #153 队列第 1 项：test/ 下独立最小项目的画卷漫步交互原型，键盘/触屏/停下观察/相机边界/视口变化；几何占位，不接 SaveStore/Main/AudioDirector，不进正式导出 | 原隔离研究已验收结项：PR #204 最终 head `c086b76` 经独立复审（`CURSOR-CLOUD-REVIEW-PR-204`）APPROVE 后合入（`e07bf44`），隔离测试 154 项；高 DPR 真机复测交 GAME-QA #156，竖屏取景交 #201 | `CURSOR-CLOUD` | [#199](https://github.com/narutojzm1-dot/youjia/issues/199)；CODEX-LEAD 指定；[原型说明](architecture/exploration-scroll-prototype.md)；数值为实验参数，不冻结；只证明隔离交互，不是正式功能。 |
| EXP-RETURN-ADAPTER | P1 | #153 队列第 2 项：模拟小院与假 Host 下 `request_return` 后先使院外输入/相机/连接失效再开放院内；unknown/迟到确认/明确失败都可在院内移动且不显示虚假已保存 | 隔离适配已交付：PR #207 最终 head `a2e0043` 经独立复审（`CURSOR-CLOUD-REVIEWER-200`）APPROVE 后合入（`2e33d50`），隔离测试 150 项、13 个变异均被门禁拦下；该原型仍按 PR #176 固定 SHA `e2a6d70` 运行时取出核心（正式核心现已在 `scripts/exploration/`）；真实宿主与 H2/H3/H4 仍归 CODEX-LEAD | `CURSOR-CLOUD` | [#200](https://github.com/narutojzm1-dot/youjia/issues/200)；[开工评论](https://github.com/narutojzm1-dot/youjia/issues/200#issuecomment-5976367738)；沿用 #156 Q10/Q16/Q17；引用 PR #176 核心须注明依赖分支，不证明耐久保存或强退恢复。 |
| EXP-FIRST-EXPERIENCE | P1 | #153 队列第 3 项：停下看景、空手中途返回、带一个占位物中途返回三种体验研究，首片节奏/构图需求与资源接口交接包 | 隔离研究切片已交付：[PR #210](https://github.com/narutojzm1-dot/youjia/pull/210) 最终 head `be60a64` 经独立复审（`CURSOR-CLOUD-REVIEWER-201`）APPROVE 后合入（`f5ca6f3`），隔离测试 261 项；[研究说明](architecture/exploration-first-experience.md)含节奏/构图需求、资源接口表、地点/物件候选与 6 条待决项；首地/物件种类已由用户确认；正式构图/资源待 #155；正式接入沿用现有 SaveStore 文件提交（#153，不等于 #150/Web 持久化验收） | `CURSOR-CLOUD` | [#201](https://github.com/narutojzm1-dot/youjia/issues/201)；[开工评论](https://github.com/narutojzm1-dot/youjia/issues/201#issuecomment-5976771165)；含 GAME-PRODUCER 补充的横竖屏同一停留点取景比较与「走近—松手观察—选择／不选择—中途回院」连续操作检查；与 GROK-BUILD #155 交接，地点/物件种类已决，不再重复征求；画面/资源规格交专业审阅。 |
| EXP-HOST-RECOVERY-GATE | P1 | #150 R2/R3 真实浏览器验收驱动：同一 context、同 origin 下，在“意图已完成/提交前”和“提交完成/回执前”关页后用新页恢复；双页锁竞争；无 Web Locks 阻断；丢回执、错身份、重复/迟到回执与真实 abort 分别出证据；业务授予不重复 | R2/R3 测试侧已交付并合入：#247（`2d2054f`）、#257（`73fe3d5`）；本轮把 #257 中仅经代码审读的 resolve 持续失败上限（模拟错误）与 ack 真实事务 abort 加入正式矩阵，并修正夹具重开后 payload 写成浮点数的问题。驱动/夹具 `e4f9e24` + Gate `f096a4a` + R1 PR251 `2edb2e7`，Godot 4.7.2/Chrome 148 连续两次 14/14 PASS（109 项），变异验证能拦住修复前夹具；PR261 最终 `98d5182` 经独立复审 APPROVE 后合入 `3956afb`。#257 最终 head `47838bf`；CODEX-LEAD-ASSISTANT 的两条异常路径一次性补证 PR259 已合入 `b3f77cc`，已由本矩阵常驻覆盖。只证明隔离候选，不是正式 Host 冻结或 R4 | `CURSOR-CLOUD`（仅测试侧驱动） | [#239](https://github.com/narutojzm1-dot/youjia/issues/239)；[接收与接口候选 v1](https://github.com/narutojzm1-dot/youjia/issues/239#issuecomment-5981415664)。范围：`test/save_recovery_web/**`、`tools/verify_save_recovery_web.sh`、`docs/architecture/save-recovery-web-acceptance.md`。不复制或重写存储实现，不接正式 SaveStore/Main，不建第二套 Host；R1 封套/意图/协调器/恢复入口与 R4 迁移仍归 CODEX-LEAD，接口由 CODEX-LEAD 与 ENGINEERING-SUPERVISOR 核对。 |
| YARD-DECOR-PROPOSAL | P1 | 仅同一占位物的可逆布置隔离对照：2–3 个候选位置与自由放置，预览/取消/确认/收起/换位置；键鼠/触屏横竖屏与低动效 | 隔离对照原型已交付（PR216）；PR232空间修订已合入70c170d，独立审及ART静态材料通过（5981854171）；正式布置/真机/持久化仍待 | `CODEX-LEAD-ASSISTANT`（仅此原型切片） | [#154](https://github.com/narutojzm1-dot/youjia/issues/154)；Leader 明确拆分见本单交接。仅 test/ 隔离项目与 docs，不改 Main/YardWorld/SaveStore/PhotoMoment；#125/#150 正式门禁保留，探索核心仍归 CURSOR-CLOUD。 |
| ART-EXPLORATION-PROPOSAL | P1 | 先资源盘点/规格/构图提案与来源预算；最终画另批 | PR248构图/资源复用提案1d647c31ed0e76a912979940431aabab63ebce95已交，制作人5981844802候选方向通过/消费接口已核，ART5983411469已对同SHA批准仅构图提案，独立review5407926310已APPROVE并合入601d683896d811e2f17cb389e7d0d8104d16e36a；仅提案，不接入 | `CODEX-LEAD-ASSISTANT`（小物样张；关键背景GAME-PRODUCER） | [#155](https://github.com/narutojzm1-dot/youjia/issues/155)；依赖/正式内容门禁见工单。 |
| QA-EXPLORATION-GATE | P1 | 独立失败矩阵/夹具与候选验收、发布和共同维护交接证据 | Q01–Q17矩阵已交；原型Web/真机补测已指定但待执行；正式平台联合验收待交付 | `CODEX-LEAD-ASSISTANT`矩阵 / `GAME-QA`原型补测 / `CODEX-LEAD`平台实现 | [#156](https://github.com/narutojzm1-dot/youjia/issues/156)；依赖/正式内容门禁见工单。 |


## 同构图阴天原画修复

| 编号 | 优先级 | 范围与验收 | 状态 | Owner | 依赖 |
| --- | --- | --- | --- | --- | --- |
| ART-OVERCAST-ALIGNED | P1 | 以晴天母版重绘阴天，几何/交互锚点不动；完整画、叠图与实际尺度预览、来源哈希；美术审核后用新路径接入，保留旧照片资源 | 已完成并公开发布：批准的同构图原画以新路径接入，3秒连续转场/反转/暂停/低动效，照片记录实际天气层；Windows2021项与完整Linux CI、新照片刷新和旧版阴天照片回放通过；公开源709a3b7已核。原v1-v7退回与最终冻结例外记录保留在#168和原产物。 | `CODEX-LEAD`（本地兼制作人；接续GAME-PRODUCER） | [#168已关闭](https://github.com/narutojzm1-dot/youjia/issues/168)，[PR486](https://github.com/narutojzm1-dot/youjia/pull/486)，[实际验收与范围](playtests/2026-10-06-weather168-local/README.md)。QA继续独立复测；#51父项不随此片关闭。 |


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
| QA-EXP-20261003-003 | P2 | 复用已有晴天小院资源恢复加载页风格；桌面/横屏/竖屏文字可读，进度/失败/重试/首帧与版本语义保持，正式发布后冷加载复核 | 实现已发布；49596同版三尺寸×normal/reduce六fresh加载/真实JS失败/DOM重试/首帧/普通入院原范围实测满足，证据PR469最终1714f0c36c6f72eb8ff76dfa9805ac20c1d9a992独审6006848968后合c50188a417920e3f400c833ebcf44fe9f28c89b4；原范围已关闭 | `CODEX-LEAD-ASSISTANT`（实现）；CODEX-LEAD委派QA支援，GAME-QA角色保留 | [#167](https://github.com/narutojzm1-dot/youjia/issues/167)；[42原图、12次包核验及首次采集失败原件](playtests/2026-10-06-loading167-acceptance/README.md)。浏览器尺寸模拟非真机；不冒全游戏/全帧验证，不改运行代码或新资源。 |

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

### 2026-10-05 Assistant #333：发布包按真实历史保留最近四组

已修随机SHA字典序误判旧包问题。PR334实际首次发布安全fallback保留6组，不冒keep4通过；发现真实历史R重命名遗漏后继续PR340，仅加--no-renames及真实R100回归。最终3949238eac55800a9dbcf80d17c589dc7234b384独立APPROVE，合main9fd261d876a8777403a8697b4b9b7f8d17d4d1a8；11项/原生全daily/导出、Actions37289044064/Pages37289768031均success。实际公开game-9fd261d三资源完整字节/blob匹配精确gh-pages97e70a5aa2b825fffb7c68227b72b554e7b33757，实保留current/ba6/8cf/fd2四组，删三最旧整组且旧保留文件未变，见[分阶段正式证据](playtests/2026-10-05-web-bundle-retention-release/README.md)。只闭环发布保留缺陷，不恢复旧策略已删包，不覆盖Leader存档/Cloud探索，不把a75游戏实玩冒9fd复测。

### 2026-10-05 Assistant：同构建公开音频与加载技术复验

已按#195/#234/#167登记，只读公开game-a75ae22真实鼠标：两轨各10次慢快开关、0/50/静音/恢复、继续、离院PCM清零/重入两轨及Web Audio真实gain独立变化通过，见[音频矩阵](playtests/2026-10-05-public-audio-matrix/README.md)。零按住时长80/180ms合成点击两次未切换记录保留，完整通过版本明确80ms按住与600/180ms等待，不冒极快输入根因或真机/真人耳听/后台全通过。三尺寸明确WASM延迟保留真实加载画面→首帧→标题→入院及受控一次engine-JS失败/真实按钮重试通过，见[加载矩阵](playtests/2026-10-05-public-loading-matrix/README.md)。未改代码/资源，父音频/加载QA余项仍开放。

### 2026-10-05 Assistant #231：旧鱼保留时第二竿未钓到的提示

CODEX-LEAD-ASSISTANT按最新缺陷队列接收与原单5990509435认领，只修YardWorld._tick_fishing两条miss通知：carry有效时明确本次未钓到、手中之前那条鱼仍在；空手/到期提示和鱼状态/20秒/概率/计数/投喂不改。新专项16项修前2失败/修后全过、Godot4.7.2完整daily及双语横竖受控Web、正常标题入口自然两竿实玩通过，见[证据](playtests/2026-10-05-fish-miss-feedback/README.md)。原276仅同步S2通知断言，历史未审原帧不冒完成；Leader149150/Cloud322不覆盖。PR329最终f37b37292a7c52652ffadba42fa5d19c804c594e独立APPROVE后合main a75ae229430ef4f0329953af70e213ca7d59d622；Actions/Pages成功，实际公开game-a75ae22三资源完整下载字节/哈希与精确gh-pages一致，正常公网自然两竿新提示/可投旧鱼已看图且errors=[]，见[正式发布证据](playtests/2026-10-05-fish-miss-release/README.md)。仅提示子项完成，父231其余验收保持开放。

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

### #149/#150 PR336 生产接线（CODEX-LEAD，已发布验收）

可信启动、单队列意图、严格持久回执、原文来源保全和旧页分歧下载已随PR336最终720db375独审合main d242509并发布。完整daily/原生200+恢复24及受控迁移/abort通过；公开羊照片返回首页/真正关页恢复及首次鱼照片恢复通过，manifest/PCK/十个模块源哈希一致。见[发布验收](playtests/2026-10-05-production-save-release/README.md)。#149补公开真实inflight关页恢复A封套后，按原可靠提交/恢复验收范围完成；#150物品身份/去重与业务组合继续，不混为149的无限前置。Cloud探索接线按已交真实异步回执完成，不再等待共享宿主冻结。

## GAME-PM 17:20：已决与接收收尾

用户原画视角/沿路走动/自然换页由本地制作人332同步，Cloud1535991376468明确接收并交32290ea8562c896641f48da224f80da97ec69921280容量3候选，独审/合入待，不重复问地点/容量/画幅。155brief/337路径候选有真实产物，PM校awaiting-receipt为in-progress，runtime_ready=false不冒正式美术；Producer300/317精确接收及285本地交接成立。阴天/圆石局部像素方式待用户、339真实听验待，只阻对应资源；338局部Main范围已Leader授权且本轮公网竖屏低对比复现，Grok首次回执待。Leader336/Assistant340341仍在途不重新调度。逐人SHAs/时间/范围/版本目标与4图公开补证见[本轮报告](pm/2026-10-05-1720-coordination.md)。

## REQ027假期天数小纸签

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-027 | P2 | 手机横竖屏上「假期第 N 天」可读、不压目标纸片 | 天数用 `INK` 字加小纸底，挂在暂停按钮正下方、同宽；五种视口中英文都不压提示和按钮。`test/day_label_layout_suite.gd` 173 项通过，未修 main 上 33 项失败。 | 已独审合入、公开发布与DPR2/3体验通过 | `GROK-CONTRIBUTOR` | 来源 #338（#242 评论 5990837592 观察）。只改 `Main._build_hud` 的 `_day_label` 与 `_layout` 天数分支；不碰存档、启动、#322 探索。Leader 已按作者请求补 daily 入口与真实 DPR2/3 横竖屏浏览器复核（本地候选，待独立最终 SHA 审查/发布）；[证据](playtests/2026-10-05-daylabel-integration/README.md)。决策见 [decisions/REQ-20261005-027.md](decisions/REQ-20261005-027.md)。  PR345最终558fd938独审合3de05fc，公开四组横竖DPR2/3与manifest/PCK/十模块源hash通过；[发布证据](playtests/2026-10-05-daylabel-release/README.md)。额外暂停提示遮挡另交#348，不冒全UI无瑕。 |


## BUG-PAUSE-NOTICE-20261005（#348）

- Owner：`CODEX-LEAD-ASSISTANT`；已按原单5994018758接收、5994245883登记方法范围。PR377最终52a2be7b独立APPROVE5995013227合046871fa，正式发布与公网通知复验完成。
- Goal：进入暂停当次隐藏提示，迟到提示不压音量控件；暂停/相册/确认框期间不耗阅读时间，恢复后正常可读与到时消失。保留单通知替换语义，不新增玩法或承诺。
- 路径：Main._process仅顶部通知计时/显示、_toggle_pause末尾、_show_notice_key与_on_fish_caught显示入口、两私有显示守卫；test/pause_notice_suite.gd与daily独立入口、专用证据。Leader保存/REQ029目标纸片、Cloud探索、相册/标题及资源方法均保留。
- 结果：真实Main受控UI双语四视口168项，原基线112失败→候选0；正确4.7.2最新a067组合完整57次启动门禁通过，含相册45914/目标纸片4653。自然中文横竖DPR3候选普通入院→暂停约8秒墙钟→恢复保留完整引导，旧公开game-1a3842c恢复已丢失；同帧漏洞由native定位，不冒精确复现旧500ms持续遮挡。
- 分支：`work/codex-assistant/pause-notice-visibility`；PR377完整52a2be7b720e26d306d4d9c90ea8dd8471dfb87a独审合046871fa803f3eebd8b9900092bb07ff70671d52。Actions37313949152/Pages37314697585成功，真正046 CI58次启动(57验证+1导出)；公开15文件与Pages15798ce/tree03d6129匹配，PCK25269536/SHA256f556a65726ef66bd5a15d37af01baed92d2af707bef4c647050efdb74d40f808。两组18条自然公网game-046871f/errors[]与原图已验，通知切片完成；[正式证据](playtests/2026-10-05-pause-notice-release/README.md)。

## BUG-ALBUM-LANDSCAPE-20261005（#350）

- Owner：`CODEX-LEAD-ASSISTANT`；状态：已发布并完成本切片复验。来源 #40 原摄影范围已由 Leader 验收关闭，本单是独立新排版缺陷。
- 目标/范围：短横屏照片、日期题词和既有正文完整可读、不覆盖页脚/导航；仅 Main._album_page / _photo_card、专用布局 suite/五实际照片夹具与 daily。照片/存档/探索/标题/音频契约及其他 Owner 方法保留。
- 交付：PR #351 最终 `e8ec19faab9faefec9a8ea8510556c29d325b8eb` 经独立 CODEX-LEAD-ASSISTANT-REVIEW-PR-351 APPROVE（5993710899）合 `bc8a048b964cf39b80291b375f36f7362f0deedc`。首 bec5 REQUEST_CHANGES 长英文/页码越界已返修；全部合法静态文案/八视口/双语/导航与数据检查45914项，原版3190失败→修订0；正确4.7.2完整strict gate与CI通过。4.6.3误用运行明确作废保留。
- 正式验收：Actions37304525517、Pages37305137774 success；实际公开game-bc8a048的13资源及HTML/manifest共15文件完整bytes/Git blob/tree相符，十模块SHA256/相对导入一致。普通同旧profile真实关闭重开、六视口/五历史照片翻页12记录，全部8历史字段相同、gen16/pendingfalse/errors[]；英文由原生几何覆盖，Web为中文。见[正式原生/Web/公网证据](playtests/2026-10-05-album-landscape-release/README.md)。
- 剩余：#195受控并发40中2次短点击未响应根因仍待；真机/真人听验、稀有全流程与整体心流不冒通过。#40不重开；制作人看图状态另表保留，不代产品认可。

## GAME-PM 18:20：生产接口与探索接收已落地

336已发布，149/40原范围347验收收口，322最终7e4b46b59014989b804f5b4cc273501a6eabb831异步队列适配独审合81d225c15962a32d7a48a066154859488a155aa4；305旧实验固定Host前置/queued已由PM更新生产组合范围，真实公开带回物验收仍待，不以模型代Web。345作者请求集成已由Leader独审合3de并公开DPR2/3验证，349归档待；350相册排版Assistant在途，348toast下一项待接收。Producer155实际三帧/比例遮挡已接，清底像素/阴天/圆石方式用户等待与339听验门禁保持。逐人SHAs/下一产物/实际窗口及game-3de05fc自然关页羊照片补证见[18:20报告](pm/2026-10-05-1820-coordination.md)。

## REQ028标题页文字纸片

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-028 | P2 | 手机横竖屏标题页的副标题、简介和操作说明看得清 | 标题列内容下垫一张贴合的半透明 PAPER 纸片（0.84、APRICOT 细边、圆角 18），随语言/尺寸重新贴合、忽略点击；副标题改深杏色 `a85d28`（对 PAPER 约 4.6:1）。文案、字号、按钮不变。`test/title_card_suite.gd` 251 项通过，未修 main 上 19 项失败。 | 已发布并公开DPR体验 | `GROK-CONTRIBUTOR`（原实现）/ `CODEX-LEAD`（集成收尾） | 每小时自选无主切片，来源为 main 6f553bf 原生 390×844/844×390 标题页截图。只改 `Main._build_title_screen` 与新增 `_fit_title_card`；不碰 #342 探索方法、#348/#350。Leader 完成本地与公开 Web DPR2/3 横竖屏标题/真实点击入院复核，最终09ff44be独审合7c1608c并发布；[本地证据](playtests/2026-10-05-title-card-integration/README.md)与[公开验收](playtests/2026-10-05-exploration-duck-release/README.md)。决策见 [decisions/REQ-20261005-028.md](decisions/REQ-20261005-028.md)。 |

## REQ029目标纸片按行数伸缩

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-029 | P2 | 手机横竖屏上左上角目标提示的纸片贴合文字：单行不留半截空纸，多行不溢出纸外 | `_fit_hint_panel()` 按实际行数设文字区高度（最少 32），纸片 = 文字区 + (18,16)，最少 48；文字垂直居中；`_layout()` 和 `_refresh_hud()` 都会重新贴合。文案、字号、宽度、位置不变。`test/hint_paper_fit_suite.gd` 4653 项通过，未修 main 上 4117 项失败。 | 最终独审已合入并发布；公开DPR2/3体验通过 | `GROK-CONTRIBUTOR`（原实现）/ `CODEX-LEAD`（集成收尾） | 每小时自选无主切片，来源为 main 33b105f 原生 390×844/844×390 截图和全部提示行数测量。只改 `Main._build_hud`、`_layout` 的目标纸片两行、`_refresh_hud`，新增 `_fit_hint_panel` 与 `HINT_MIN_TEXT_HEIGHT`；不碰 #348 通知、#350/#351 手帐。Leader保留作者0005c4e提交，补daily登记/UID/组合导出；真实中文DPR2/3横竖屏由内部协作pet30_impl复核通过；英文仅native几何，生产无切换入口；[完整证据](playtests/2026-10-05-hint-paper-fit/README.md)。正式PR362合1a3842c，Actions/Pages/公开PCK及十模块已核，四组真实公开体验通过；[发布验收](playtests/2026-10-05-hint-paper-release/README.md)。决策见 [decisions/REQ-20261005-029.md](decisions/REQ-20261005-029.md)。 |

## REQ030确认纸片窄屏适配

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-030 | P2 | 手机竖屏上「现在离开吗？」确认纸片完整显示在屏内 | `_fit_confirm_panel()`：宽 = min(420, 屏宽−24)，高 = min(240, 屏高−24)，居中；建页和 `_layout()` 都会重新贴合；宽屏仍 420×240。文案、字号、按钮、行为不变。`test/confirm_panel_fit_suite.gd` 562 项通过，未修 main 上 78 项失败。 | 已合入并发布；公开四视口鼠标几何已验，触摸#382独立待修 | `GROK-CONTRIBUTOR`（原实现）/ `CODEX-LEAD`（集成协助） | 每小时自选无主切片，来源为 main 5bb2102 原生 360×640/390×844 截图（纸片左右各出屏 30/15px）。只改 `Main._build_confirmation_screen`、`_layout` 末尾一行，新增 `_fit_confirm_panel`、`_confirm_panel`、`CONFIRM_PANEL_SIZE`；不碰暂停页、#348 通知、#350/#351 手帐。PM20:20已登记作者认领，Leader保留作者2b71d6c并补永久daily100755。runtime6f9d15b原生562及完整严格daily通过；候选Web390/360 DPR2/3鼠标打开/取消/恢复与旋转通过，touch一次未定位、续玩/重置/英文Web/真机未验；[完整集成证据](playtests/2026-10-05-confirm373-integration/README.md)。 PR373已发布e0d699b，Actions/Pages与公开PCK/十模块核验通过；四页完整源绑定，mouse打开/取消/恢复、旋转共13原图已验，见[公开验收](playtests/2026-10-05-confirm373-release/README.md)。不称touch通过；#382公开复现独立PR386在审，不将候选当已修复。决策见 [decisions/REQ-20261005-030.md](decisions/REQ-20261005-030.md)。 |

#150 idle cleanup共享接口已冻结并发布（PR391，5995152650）：新增只针对已提交formal会话的冻结参数＋队首CAS清理提交，明确写前拒绝，不prepare、不覆盖新trip/无关字段，不增磁盘schema。Cloud领域重试与Main提示关联尚未接入，不能称同页恢复已修。[接口契约](architecture/exploration-cleanup-commit-contract.md)。最终9d2dcd88e447628f610b230b397661c9cf2469ae经独审5995798603合4fa150819c304b03fb6a36a149e71d4bcd911000；Actions/Pages及实际公开PCK/十模块已核，[发布归档](playtests/2026-10-05-cleanup391-release/README.md)。只冻结共享接口，不代表Cloud已消费、领域恢复或Main提示已完成。

#305/#150 探索侧 cleanup 接线（CURSOR-CLOUD 接收 5999078476）：`ExplorationHost` 收尾（回院确认后与重启 close）改走 `request_exploration_cleanup`，登记 cleanup op；明确写失败/查明被拒时，仅本页会话仍停在同一收尾且存档仍是同一原记录才重交同一冻结请求（最多 2 次），`PRECONDITION_CHANGED`、新旅程已开始都不重交；未知保持等待；隔离记录与契约外记录保留原直接写。Main 只把同一 cleanup 此前失败的原样快照绑定到重交编号，确认后精确清除、队列空闲收起面板。见[验证记录](playtests/2026-10-05-exploration-cleanup-wiring/README.md)；内存队列与真实 SaveStore 的 headless 检查，不是公开 Web 受控故障复验。

#305 保全修订候选（Leader认领6000660890）：427合入cdec仍保留INVALID_ARGUMENT普通写回退，真实Native未知扩展复现可覆盖current。现仅取消该回退，保留原记录/原失败并停止同页重交；普通写故障有限重试不改。新领域到Native51项修前15失败、修后通过，47bb完整70次strict与导出通过、真实Web受控单次cleanup故障恢复通过，普通单停点返院/真重开有限通过，待最终独审发布；不是已发生公开用户事故。证据见[候选档案](playtests/2026-10-06-cleanup-invalid-preservation/README.md)。

### EXP-LIVING-WORLD 方向约束（用户2026-10-05补充，沿 #153 / #155 执行）

探索程序 Owner CURSOR-CLOUD；原画/物件/音频与需求细化 GAME-PRODUCER。状态：用户方向已确认，内容/参数待首片体验后细化，非实现完成。近郊重访允许合理物品或空手，掉落遵循生态与季节；动物偶遇/天气同为风景；各片区环境音及音乐应契合环境，近郊可偶闻微弱家鹅叫。先完成首片人物透视+发现/获得动态音画体验，不一次扩展多季节、种子功能或全部动物事件。详见 game-design.md 的“探索是生活中的机缘与风景”；不以本记录替换未决概率/时间机制或现有可靠保存验收。

## BUG-AUDIO-TOUCH-20261005（#388，父#195）

- Owner `CODEX-LEAD-ASSISTANT`，实际在研；原单接收/范围5995550836→5995599284已收窄。旧横屏master点297实际在按钮外，推断已撤回；新的正确中心公开game-e0d699b横竖DPR3单tap未静音，原生两回pressed/TuningStore true→false。
- Goal：三音频按钮一回触屏手势只切一次，长按释放/拖取消、鼠标/键盘、纯touch fallback保持；仅Main._input音频按钮已有GUI按住时不重复手动emit，其他400ms过滤/frame guard/存档/后端/资源/探索完全不动。
- 分支 `work/codex-assistant/audio-touch-routing`；648真实GUI原生项旧Main168失败→候选0，最新5c2运行组合完整4.7.2 strict59启动exit0、普通本地Web横竖DPR3共62条index/errors[]通过，基线到efda仅docs变化。最终完整SHA独审/PR/合入与正式公开仍待，index不冒上线。[完整证据/失败/边界](playtests/2026-10-05-audio-touch-routing/README.md)。
- #195原并发两次短输入根因、物理设备/真人听验/BFCache/全心流保留；只交388音频路由切片，不关父单。

2026-10-05合入前保留Leader4fa最新cleanup两运行文件及daily新入口，完整4.7.2再跑60次启动exit0、普通最新组合index62记录/errors[]；Main仍5b8e6c1，仅一处音频触屏命中判断。[最终组合证据](playtests/2026-10-05-audio-touch-routing/INTEGRATION.md)。完整SHA独审/正式公开仍待，不用旧59组合日志冒新包。

### #150 双页占用启动指引（已独审合入/已发布/普通双页已体验）

CODEX-LEAD仅将可信open回复的精确OPEN_FAILED + `Error: writer_owned_by_another_page`分类为前端SAVE_WRITER_OWNED；提示回原页或关原页后重试。不放宽单写者锁、不改变Host/Cloud/Main/磁盘格式；其他故障保持失败。PR404最终ab358411604a667541042c638f17ba87c93a4ece已获独立终审5996902915并合入；公开源c1a2b0f4ec5966b4955c54e7be3934933482aff2的Actions/Pages与实际PCK/十模块核验通过。真实普通双页占用→关闭原页→点击重试→原照片恢复，三阶段只读DB完整封套一致；见[公开证据](playtests/2026-10-05-writer404-public/README.md)。仅该启动指引闭环，不代表#150整体或Cloud领域cleanup恢复完成；不冒触摸/真机/全部失败矩阵。

### REQ-20261005-031 短横屏标题页（PR392接力验收）

| 编号 | 优先级 | 目标 | 验收 | 状态 | Owner | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-20261005-031 | P2 | 可用高度300–360的横屏标题列完整可见 | 保持高于360既有布局，缩紧标题列且常规尺寸恢复；浏览器DPR2/3短横屏显示和普通入口可达 | 已独立终审合入/已公开发布/公开两视口已体验 | GROK-CONTRIBUTOR；Leader完成门禁/发布验收 | PR392已合入ee2fce7a0988f92b7760a7f64bda81f7a32239ed；候选六组DPR2/3验收及必要回归完成。公开同源CSS568×320 DPR2、640×300 DPR3正常标题/许可/相册/入院通过，含一组旋转恢复；Actions37325681616、Pages37326582200成功，公开PCK实际哈希已核。见[公开原始证据](playtests/2026-10-05-title392-public/README.md)及[原决定](decisions/REQ-20261005-031.md)。浏览器鼠标模拟视口，不冒真实手机地址栏、触摸或低于300覆盖。 |


### REQ-20261005-032 原生开源声明小窗（PR402集成候选）

| 编号 | 优先级 | 内容 | 验收条件 | 状态 | Owner | 来源与边界 |
|---|---|---|---|---|---|---|
| REQ-20261005-032 | P2 | 原生开源声明首开与存活窗口缩放适配 | 首开竖屏/短横屏、同窗缩窄/恢复桌面、正文保全、确认/取消关闭及释放监听；daily永久覆盖 | 已独立终审合入/已发布；原生候选已体验，公开Web外链防回退通过 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（已授权集成） | 保留作者c496ec1祖先；[原决定及增量](decisions/REQ-20261005-032.md)、[原生证据](playtests/2026-10-05-licenses402-integration/README.md)。PR402最终80238c32abfe7feffe2c5361ee1220a98205c65a独审5997465923后合入/发布82f902a0f22f50032bff9acbe542d0f1953ae684；[公开来源与Web防回退证据](playtests/2026-10-05-licenses402-public/README.md)。仅非Web声明模块修订，正式Web烟测不冒原生窗口体验；Web HTML、Main/存档/探索不变。 |


23:20 PM REQ032状态追记：最终80238c32abfe7feffe2c5361ee1220a98205c65a独立审查5997465923通过后合82f902a0f22f50032bff9acbe542d0f1953ae684；原生124与关闭/queued-resize60边界为原独立审核证据，PM未重跑。当前公开HTML/game-release.json已实际82f完整源绑定，非Oct5日冻结06da；PM近郊鼠标/键盘覆盖不是原生dialog验收，完整公开文件字节核验仍分列Owner证据，不再称此head待独审。
### REQ-20261005-033 新照片短横屏布局（PR422集成候选）

| 编号 | 优先级 | 内容 | 验收条件 | 状态 | Owner | 来源与边界 |
|---|---|---|---|---|---|---|
| REQ-20261005-033 | P2 | 新照片相纸及说明适配短横屏与显示中旋转 | 常见≥320×300视口完整显示；正常淡入中旋转/系统低动效切换不延长截止、不补播、不改变照片；真实中英文题词可见；daily永久覆盖 | 已独立终审合入/已发布；公开短横屏初始reduce转屏与自然相册链有限通过，竖屏在途未覆盖 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | PR425最终57145610a6ce637558d7835b7011fa87702c7fb4独审5999409006后合入并发布ecea67dba1afc9b99b6097970e4965fbcd99c53a；[正式有限证据](playtests/2026-10-05-photo425-public/README.md)。保留作者813c2d4祖先，与423偏好入口组合；[原决定](decisions/REQ-20261005-033.md)。不改相册、照片规则、存档或输入；极小窗口不承诺，英文仅受控原生验证。 |
| REQ-20261006-034 | P2 | 可用高度≤360的横屏相册整页留在纸面内 | 紧档收紧外框、标题、间距及按钮，真实字高决定书页；常规尺寸与同窗恢复兼容；daily永久覆盖 | 433已独审合入并发布；一照中文三短屏及关页新页视觉恢复有限通过 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保留作者db89cf3祖先；[正式source c6e5c9b证据](playtests/2026-10-06-album433-public/README.md)，未覆盖翻页/英文/触屏/真机；[决定](decisions/REQ-20261006-034.md)。仅相册外框排版，不改照片卡、存档、输入或探索。 |
| REQ-20261006-035 | P2 | 标题页声明链接普通、悬停、焦点和按下在纸卡上均清晰 | 全文字态深色对比≥4.5:1、焦点2px边框≥3:1；保持文案/尺寸/原生与Web声明入口；daily永久专项 | 439独审合089d453并公开；CI71验证启动+1导出通过，正式四视口各态/4鼠标与1桌面Tab→Enter新tab打开返回通过；442证据独审归档合e77d5a37后413已按原范围closed completed | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保留436原b542祖先；[决定](decisions/REQ-20261006-035.md)、[正式证据](playtests/2026-10-06-title439-public/README.md)。原生数值专项与公开可读性分列；不冒Web像素对比实测/全可访问性/实体手机/触屏/原生许可窗口，未改382或Cloud。 |
| REQ-20261006-036 | P2 | 暖纸主按钮键盘焦点、点击后和按下时文字仍可读 | 焦点/按下用 INK，悬停/悬停按下沿用深色；焦点为无填充、外扩2px的 TITLE_ACCENT 描边，保留原底色与杏边；专项纳入 daily 永久门禁。 | 444授权接力集成；4.7.2专项5080、完整daily72次启动及Web导出通过；三视口普通键鼠候选有限通过，main85f后探索218通过；451最终f72e27be6a768dc14303b06f6fdf3a4a0c21dc00独审6002776769合de4ba422；451发布来源6003231423已核；候选普通输入与正式字节分列，非382修复/真人听验；454公开a0bb普通实际按住/确认取消6004433457有限通过，Tab/ShiftTab可见焦点NOT VERIFIED转459，不冒全键盘可访问性。 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保留444原 cda5ab8ded8384f3f3b7bfeccf996652b65a1a9c 祖先；[决定](decisions/REQ-20261006-036.md)。只改 Main._soft_button/_soft_focus_ring 与专项入口，不碰382输入/modal/slider、声明链接、存档或探索；[集成验证及边界](playtests/2026-10-06-soft444-integration/README.md)，真实Web验收单列。 [正式按住/取消证据及焦点边界](playtests/2026-10-06-photo454-public/README.md)，[459仍待验证](https://github.com/narutojzm1-dot/youjia/issues/459)。 |
| REQ-20261006-037 | P2 | 新照片相紙照片四周不再透出後面的院子 | 不透明暖紙襯底覆蓋原相框透明窗；沿用照片、題詞、時間與縮放；專項納入 daily，完整回歸、Web導出及普通新照寬窄/低動效驗收通過 | Leader授權集成候選：550/門禁50與Web直接exit0，四組普通羊首照/相冊通過；首次外層差異原件保留；補4根metadata重導出0且394舊payload完全同一；454 finald9302cdce4a7293d14df773ba50d7c5f231291c4獨審6003668335及真CI6003952106成功合a0bb75e；公開HTML/manifest已a0bb，正式PCK/10模組6004247545已核；4546004433457公開普通390×844首照/相冊/按住確認取消/真關頁同context恢復currentgen2保持有限通過；459焦點未驗通另待接 | GROK-CONTRIBUTOR（原實現）；CODEX-LEAD（授權集成） | 保留447原 faf507ae47a1bd999a32b3720b22cf3391ea5b1e 祖先；[決定](decisions/REQ-20261006-037.md)，不改相冊、存檔、輸入或玩法；[集成證據及邊界](playtests/2026-10-06-photo447-integration/README.md)。 [公开普通原件及明确局限](playtests/2026-10-06-photo454-public/ordinary-inputs-a0bb/README.md)。 |
| REQ-20261006-038 | P2 | 暖纸按钮禁用时仍有浅暖纸底、柔墨字与细边 | 字对不透明禁用底≥4.5:1，尺寸/圆角/文案/何时禁用及行为不变；专项和准确正计数完成行进入daily | 原实现455已授权Leader接力；910b候选真实4400、完整73套+import、Web导出通过；普通两尺寸空手帐见证据；460最终8a401350fedc57e59db86649b57ffd747649144f独审6004787590/真CI37383994819合9623ba22；正式來源及两模拟尺寸空页普通后验6005141719通过，writing等真实路径未覆盖 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保留原c792真实祖先；[决定](decisions/REQ-20261006-038.md)、[候选与边界](playtests/2026-10-06-soft455-integration/README.md)。仅Main._soft_button禁用态及常量，不改382输入/modal/slider、454相纸、照片/存档规则或探索；writing等为原生夹具，不冒真实普通存档体验。 [正式公开来源与两尺寸原件](playtests/2026-10-06-photo454-public/soft460-public/README.md)。 |
| REQ-20261006-039 | P2 | 新照片上方快门文字在院子明暗背景上清楚可读 | 一行后加贴合文字的近不透明暖纸片，随字淡出、切语言/尺寸重贴；行框几何、文案、墨色、照片与时长保持；专项纳入daily永久门禁 | 作者461已授权Leader集成；fd887候选真实1290、完整74套+1import75启动、Web导出通过；中文正常动效390/568普通羊首照与相册已验；464最终0f4226dc6710ef3a11099baf45f707bbfd4fd30e独审6005708356/真CI37389414385合49596fa93bff3c29edfe441898017158c6e469a3；实际公开包与两尺寸普通中文首照/退场/相册6006021492有限通过，长提示/英语/减弱普通UI未验 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保原742b真实祖先；[决定](decisions/REQ-20261006-039.md)、[候选及覆盖边界](playtests/2026-10-06-photo461-integration/README.md)。仅PhotoArrival快门纸条，不改Main/382/459、相册存档与探索；英文/低动效只算原生夹具，长提示及所有HUD不冒覆盖。 |
| REQ-20261006-040 | P2 | 暂停页音量滑条在暖纸面板上看得清、填充方向明确 | 浅暖轨道、深杏填充、24px矢量手柄；保Main路由/焦点方法，新增真实两轨鼠标输入与gain/同实例重排验证，专项与完成格式纳入daily；Web普通及HiDPI有限体验另验 | 原466授权Leader集成候选；源146c真实双slider输入267/0、原样式708及77suite/78运行、严格Web均通过并留原件；首次夹具267/4失败保留；源146c同页DPR2两尺寸普通两轨click/held/release/横竖重排有限通过；新49cf组合Cloud278与严格新Web通过；新组合普通/DPR3、最终非作者独审和真实CI待，未发布；原作者199红测/PNG仍仅原文报告 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保原1759真实祖先与9blob；[作者决定](decisions/REQ-20261006-040.md)、[集成说明](playtests/2026-10-06-volume466-integration/README.md)。24px改变原生Slider有效鼠标行程，不能以命中rect字段未改冒全输入不变；382已接/459待接，均不在此修复。 |
| REQ-20261006-041 | P2 | 鼠标悬停提示与暖纸 HUD 一致且可读 | 保持文案/延迟/位置算法；近不透明纸底/柔棕边/墨字；中英五尺寸受控原生 hover、离开消失与鼠标开合手帐；正式普通UI固定中文；专项及正计数完成行进入 daily | 已由PR488合入3e0680210b69665a5a46ad295ed3fe71e10d512a；保留原作者和480全部证据，最新天气组合Windows424项、完整CI37407249231及Web通过；主线Actions37408055655/Pages37408754626与公开manifest、实际PCK、10个存储模块均核验通过，已公开发布。按10月6日授权不等逐PR外部审核，日版前整体审查保留。 | GROK-CONTRIBUTOR（原实现）；CODEX-LEAD（授权集成） | 保留原4ab54d7完整祖先；[决定](decisions/REQ-20261006-041.md)、[集成证据与未覆盖](playtests/2026-10-06-tooltip473-integration/README.md)。不改Main/project、400/466/382、存档或探索；alpha.97不宣称绝无透底。 |

### 2026-10-05 23:00轮 Assistant 本地接续 #388

用户归档旧云端会话并指定本地接续及每小时调度；原提交链保留，PR394连续合并最新主线至0c7f，运行候选c35ffedda64e6f0b98b72f62ad5b8afa49c67df4。独立预审确认标题、存档占用、许可适配、近郊清底与各方台账完整保留。Windows此前71561组合59调用通过；最终c35组合Actions37333455347完整未改Linux strict64次启动、发布辅助检查及Web导出通过，19导出文件实际SHA256匹配；最终普通导出包横竖DPR3浏览器62事件/18原图/errors0、真实后端与活动增益一致。失败环境日志和未覆盖范围保留。最终完整SHA终审/合入/正式Pages与公网后验继续，不以候选当发布，不关闭父#195，不替代#382；近期#399/#400由用户指定制作人跟进，本片不重复接管。

详见[本地接续原始证据](playtests/2026-10-05-audio-touch-routing/local-continuation/README.md)。


### 2026-10-06 00:20 GAME-PM最新接续

394最终ff33c16655c530ef0755a7a36f588ad70b46289f已独审合348029a62a5952a7d7f5af5190147cf756934e14/正式发布，旧c35候选及待合文字保留历史，公开62事件仍原作者收尾；410最终29e独审合0c7，组合348已发且Producer清底视觉认可；382/305具体接收、399400最新Producer接续和168返修仍未完。 [逐人原证据及下一动作](pm/2026-10-06-0020-coordination.md)；[滚动候选](release-prep/2026-10-06.md)。不重复Oct5节点发布/邮件。

00:27后最新覆盖：Assistant419最终71de2c4a2e45074aaa9f8ac661e1d9ad50cfab01独审合ea6e8e82924ffdf5a8f899a4b3485cfacf1f3339，394公开横屏31状态/15资源已验，竖屏超时未执行/整体exit1，388不关闭；Cloud418当前1194d33898207f32fa643e39059f61fa2e08bc9b已有399实现产物、独审待，Producer最新跟进与Cloud实际作者分列，PM5998667627已衔接不重复同方法、双方接收待。305领域接线未交，不拿399修复代它。


### #399 正式触摸补验未通过

2026-10-06 #399正式触摸补验：公开ecea67dba1afc9b99b6097970e4965fbcd99c53a两fresh触摸样本出现异常初次入院/恢复表现，唯一只读重试普通路面触摸后、点门前已回院；未确证根因、未修复，不关闭399。Producer继续跟进，Cloud418既有作者，Assistant382输入边界在途不冒新修复接收。键盘/携物触门仍未有效覆盖；已有鼠标空篮通过分开保留。见[原始证据与假设边界](playtests/2026-10-06-exploration399-touch/README.md)。


### 2026-10-06 01:20 GAME-PM最新状态（覆盖旧等待快照）

388由421同源竖屏补验结项，382已实际接收但最终实现SHA未交；Cloud305已接收未开工，418最终5499dc3a8e94619af773c2052a8204a34c82b0f5已独审合入/发布；Grok422原813c2d467134489635ec98c99f7046d3a5d8cdb7已保祖先集成425并公开ecea67dba1afc9b99b6097970e4965fbcd99c53a。用户UI交Grok授权242/5998731892落实413标题链接配色拟交GROK-CONTRIBUTOR（5999714180），尚未回执则保原OwnerAssistant queued；Build仍额度暂停。168本地3f2da4270fc6488da42eaa4ec45ca43768bb778a候选完整审画/归档独审已通过，冻结例外/上传/接入未完成，顶栏5999747225已校正。 [逐人证据/实际窗口/端到端下一交付](pm/2026-10-06-0120-coordination.md)。不冒Leader在途同构建QA完成，不重复日发布或用户已收到产品问题。


提交后最新覆盖：Cloud305已开PR427，head a69979b5c7148034d1598ea00ba6de2c413aa5d0，领域cleanup与Main最小失败revision关联候选已交，216/216/daily为本机检查，独审/公开故障复验/合入未完；不再将该Owner当前写为未开工。此前时间快照保留。


### 2026-10-06 #399 公共启动生命周期保底（432已发布，有限公开验收）

CODEX-LEAD按[原单认领](https://github.com/narutojzm1-dot/youjia/issues/399#issuecomment-5999958180)只修复一次标题触摸重复启动：play只在标题受理、await存档期间启动互斥，失败恢复后可再进、合法restart保留，音频解锁保持真实手势栈。[诊断与专项](playtests/2026-10-06-holiday-start-once/README.md)。14项原生专项、68次启动完整daily与Web导出通过；独立普通候选触摸/键盘空篮正常返院通过；432最终0c3b3e079ac98f082670e10f73b83b246f86e8b6独审合96f090a63e0997244924a7463bd0e52a025b57b1并发布，正式两fresh触摸/键盘空篮正常返院有限通过，[同源公开包及实际UI证据](playtests/2026-10-06-holiday432-public/README.md)；不关闭#399，不修改Assistant382输入Owner或Cloud427清理范围，不将公开异常全部归因于尚未完整复现的迟到重建。


432同源公开携物补验随后完成：一次自然趟松果1＋圆石2（3件2种），touch移动/门＋普通E/T收取，正常返院后真关页新页。无背包UI，数量保全另由只读records/current封套前后完全相同gen12/session=null/serial1支持；中间gen8保留、不作最终篮子。[原件与限制](playtests/2026-10-06-holiday432-public/carry/README.md)。未覆盖落羽/全DB/故障矩阵/实体设备，不关闭399；不重复432邮件。


432发布证据档整合至433已合main c6e5c9b8b1764f8c41eb492b56b4d11da7f1386b；433公开CI在途、未公开验收，不算入432同源证据。427 c6c1已合main cdec7a6a5b8f13307048e60f6e1f57d49f5b5881，但INVALID回退共享保全缺口未修，Leader已拦停该源Actions37356141984发布；433安全CI37355933384继续。旧“305未开工/427在途”为历史记录而非当期状态，不冒合入等于修复或发布。


### 2026-10-06 02:20 GAME-PM门禁与接收最新核对

427已合cdec但INVALID_ARGUMENT直接写回退仍未修；PM6000625525给Cloud后续修复PR/保全回归与Leader含cdec发布门禁最小精确交接，两方回执未见，不能以旧APPROVE冒解除或只等QA。432启动防重入已发96f并有限正式touch/key空篮通过，433最终aad4独审合c6e5/保Grok原db89祖先，未证正式发布，候选与线上分列。305/413原单顶栏与168旧Build制作/LOCAL逐张接入步骤已直接纠正为最新事实/端到端授权，不增逐级审批。 [逐人完整SHA/窗口/仅阻塞与下一产物](pm/2026-10-06-0220-coordination.md)。


### 02:38实际接收与产物增量（优先于本轮前段时间快照）

Leader已在305/6000660890实际接收并取消仅含风险cdec的发布37356141984，未回滚main；新分支work/codex-lead/cleanup-invalid-preservation只接ExplorationHost._cleanup_rejected的INVALID保全补丁与精确测试。242/5999575285的18:37编辑报47bb594（只见短SHA，完整最终head待交）、5类未知字段真实Native51通过/修前15失败；完整daily/Web/最终独审仍在途，不能称最终门禁解除。Cloud保持探索领域Owner，原PM6000625525要求Cloud另开同一回退修复被此明确接力覆盖，勿并行重复；Cloud对风险及接力的本人回执仍未见，不再写Leader未接住。

Cloud242/6000756272于18:38:12实际交375 Draft v2完整head18c049b1b1b11dd2f8b748689287be35182a355e，深暖灰纸片/竖屏稳定篮名底板、v2横竖帧、隔离191/191与daily通过。下一Producer审v2运行认可或具体返修→Cloud接合格资源/真实动态/最终独审；尚非runtime-ready或发布，音频真实听验另列。该新产物不代cleanup接力回执，不因部分风险写整人等待。

434最终7d9d15e5001baa9dc208981af20b67dbe188014d独审6000711461合515f3550c41555dd4ccc160a767d0f72ccc584d2，已保留432正式空篮和松果1＋圆石2自然趟、触门返院及真关页新页的原档；数量为只读current封套前后相同gen12/session=null/serial1支持，无背包UI，不是全三种/全DB/故障/真机验收。399保持开放。433正式c6e5（427前）已由Leader18:34:43核PCK27086076B/SHA256 f80ba8f58617ca6d4e91ce86deb80416f71f09286d7e2faaca99c48ae6d340c3和十模块；其普通公开三尺寸相册复验在途。PM自己的四图被测仍96f，不冒本人重玩或听验。合并完整保留434原始证据，不制造重复测试。


### GAME-PM 03:20最新接收覆盖

438最终e43f1901ddf1c6f7847dea18b5df51aeaf7a6670独审合83b893035d76e9cdd1966b724fb748fab5e3ef59并发布，INVALID保全最小修订已交；Cloud6001369069明确接收/未重复同方法，旧接力未接收已解除。413由Grok436原b5423a67c9ca7aa0d9fd414a2d6ed1a5eadfbd31实际认领交付，439最终68084b6cffc52e5911c49f1004b4da5154281671独审合089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21并发布；父单正式组合/各态验收仍在Leader实际持续轮次，不重复测试/不全关。375新753f1795831e1f3be8032796f6e50b754dd55413清底v2横竖视频/独立画面审核已交，Producer运行认可/耳听待。168远端原件/专业例外/接入、Assistant382最终实现head仍未交，不把别人的合入冒执行。详见[13身份最新产物/范围/窗口](pm/2026-10-06-0320-coordination.md)。


### 2026-10-06 #400 Leader 镜头交接保底子范围

按[原单协助认领6005299861](https://github.com/narutojzm1-dot/youjia/issues/400#issuecomment-6005299861)，CODEX-LEAD只修静观已持有镜头→鹅马仅预热→预热取消的共享框架空档：预热不提前清旧hold，原移动取消/自然到期释放，phase≥0实际接管才yield。只改World一个方法；Main输入、背景与探索不改。v2真实原代码FAIL202/34失败，最小修正PASS202；normal/reduced同tick接管前quiet仍active且hold≈0.4，无误release，之后实际相机平滑归零。组合33bd含464原作者，75套+import76启动、64mock（新增14）、2Node、retention11、本地publisher与严格Web均exit0；[完整证据及失败原件](playtests/2026-10-06-camera400-handoff/README.md)。候选390普通静观→ArrowRight→回稳有限通过，前后实取同源PCK/模块；静观顶部112/138px浅纸空带另属遗留构图缺陷，不通过总体验收。最终独审/真实PR CI和公开状态单列，不把原生夹具当用户截图复现。GAME-PRODUCER仍是#400总体验收Owner，原图来源/构图与resize/天气/探索返回未完，不关闭父单。


### 收尾时最新实际产物（覆盖前段等待快照）

Cloud242/6006407904实际00:24:25Z确认本会话审查返回即可续、后续小时触发是计划窗口非执行保证。467原最终392b330effb8dc345bbde4a140d0ba7dbf9821f7已由作者组织独立CURSOR-CLOUD-REVIEW-PR-467 APPROVE并实际PR CI通过，自行合main dbf6f5aa902ecefeb168657e81a3bb12d97dbcbd；已合不等于已发布，Actions/Pages/实际公开包及适用后验仍Owner收尾。原review三条低级意见（同尺寸不发信号使守卫覆盖偏弱/冗余left_behind/无现存重复setup路径）保留不冒全面覆盖。

Assistant实际新PR470279994052541f289c8fc205274552e2e9afe84b0交382确认层/暂停滑杆单手势隔离，264项修前96失败→修后0、音频648/暂停168/保存反馈50是作者原生报告，实际Web/最终独审未完成，旧79d CI不冒新279994最终CI。459仍未接收且不是470默认通过；无资源/Host/后端改动，原Owner保留。Leader167已有证据PR469749c36d343df09aaf0d9919e6cc2c6a618dcb752，独审未完成，不再只有计划分支。

465正式main37392967346/Pages37393667313已success，6006482881实核b9f公开PCK27090748B/SHA2562b719ae25bb58d91f4742e998faff212a3410a5ac1ecf47ed50c3fc7dbf0ca1f与10模块/license，普通390静观→移动00:27:03Z CLOSED仍见123px空带FAIL；因此源码/部署证明闭环仅World交接，400新投影依旧在途，Producer整体未完成。PM实际被测仍b9f，最新源码dbf含467未本人体验；不拿已合的新head代前段实际页。


独立终审时补核470远端head已变为84a310bc3c2df4b09146197f76ad8e4cbf9cf29a（API updated00:29:44Z），作者正文仍279994；新head内容/适用验证与独立终审需作者重新绑定，不能把旧279994或79dCI/原生报告当84a已审已验。Assistant已交实现这一事实保持，13行最新远端为84a，前段279994仅本轮初始产物快照。尚未合入/正式后验。


### 阴天精确专业门禁实际解除（独立终审期间最新覆盖）

PR468最终3f2da4270fc6488da42eaa4ec45ca43768bb778a已合175bfce8f9ef02991022188172de4cf3fec007d0。新6006526392由Producer转录独立GAME-PRODUCER-REVIEW-DUCK-ART专业复审，明确APPROVE该精确冻结范围例外和右侧底板美术返修，**不再仅候选归档批准**。雪框7257中实体4877精确同v1坐标/天空2380；y>=250的20437中实体18522同v1/天空1915，交集不相加，分类是制作mask+视觉不是独立自动语义分割。专业门禁据这份具体复审实际解除，不是PM意见代审；原RC只在精确候选范围解除，不授权任意改冻结区，不等ART个人再次签字。168顶栏及REQ005最新状态已直接同步。

Producer下一本人新路径天气接入，保旧图字节、照片capture/sanitize/setup拍摄时混合与光色表达、真实保存重载/旧照、晴阴反转/低动效/实际包体→最终接入SHA独审合发/同构建QA。天气/照片/运行发布尚未完成。前段Draft/待冻区例外/未合是当时快照已被本段覆盖；实际已解除上传和精确专业返修两项，不再往Leader或用户堆同一已授权审批。当前main175bf包含资源归档，PM实际在线仍b9f，不冒新阴天已经玩家可见。



### QA-EXP-20261006-004 独立复核待办

P2；状态：单次普通线上截图已观察，待复核。GAME-QA仅承担复现验证，开发Owner为CURSOR-CLOUD，467已修复并发布175bf，普通修复后复测仍待，不改现有探索职责。game-49596fa中文1646×894拾圆石时，短展示物品小标签呈方框状，其他中文正常。验收：在实际公开构建普通拾取圆石/其他物品，核对物品名清晰可读并记录版本及原始帧；如有修正另由原模块Owner认领和独审，不扩大为#456尺寸问题。见[报告13图及BUG步骤](playtests/2026-10-06-0815-game-qa/README.md)。


### 2026-10-06 #382 Assistant修复候选

Owner CODEX-LEAD-ASSISTANT，PR470。确认层触摸不穿到底层音量，同一触摸只拖其起始滑杆，GUI已按下的暂停/确认按钮等待release以免重复动作。最终运行时7c7d9d58d0c013f3f17c9902efe368d67f5642dd，270项原生、strict79启动及真实CI包三尺寸输入已验；[原始证据和限制](playtests/2026-10-06-modal-touch382/README.md)。候选，独审/合入/正式公开复核待，不代替195或459。

### 2026-10-06 #400 Leader 静观背景边界独立子范围

按[认领6006243273](https://github.com/narutojzm1-dot/youjia/issues/400#issuecomment-6006243273)，CODEX-LEAD在已合465的main `b9f68c3c5c4e70e16cefde9b4400bb1d553ff915` 上，只接World真实背景bounds/静观来源只读接口及Main静观/回程投影。动态保持无焦点基准已有覆盖，保留原留白，不加zoom、不延展原画、不改触发/hold/cooldown/鹅马顺序。390竖屏原画纵向恰填满，因此该轴抬头幅度受限；不声称原幅度仍保留。Producer仍为总体验收Owner，原2444×1502路径不据此结案。

精确584候选已实证：同一增强fixture的b9覆盖红样41894检查/2026失败、旧655接管连续性红样41912/4失败、584绿样44734/0；两红样均实际Camera/Canvas断言、无脚本资源错误。完整76套+import77启动、68mock（本片新增4背景完成注册，原14交接契约保留）、2Node、retention11、本地publisher及严格Web均exit0；首次阈值错误、缓存导入失败和被独审拦截中止的full-v1原件均保留。独立QA普通390静候/移动→568真实冷却后静候/移动→390及一次花箱操作有限通过，17完整PNG与前后真实HTTP包/十模块绑定；没有旧顶部纸带，横屏原留白保持。原生受控鹅马/两模式不冒普通Web；无第二reduce浏览器、原2444×1502因果或完整天气/探索总验收。随后保留已合476的最新main d21030dfc243926b7e6a1849151ada1eadab75ef及Cloud475的25个新增文档，Cloud467三blob和滑块原作者九blob完整保留；三验证入口保双方增量，静态78专项/79启动预期、实际fake门禁96例与Bash语法检查通过。584旧原生/普通Web不冒新增autoload/项目接线后的组合源通过；最终非作者SHA审查、组合真实PR CI/导出、合入与公开后验待完成。[完整原件与边界](playtests/2026-10-06-camera400-backdrop/README.md)。

#400本切片预审追加：静观边界约束与鹅马接管之间不能暴露旧raw偏移，Main以先前实际effectiveoffset作为新focus插值起点，新目标/zoom/速率不变。既有_start_holiday相机归零块仅同步清两个新增字段，受控回归验证前局确有非零有效位移、下一局立即清空；不改启动/保存协议。第一次full-v1因该独立发现主动中止、没有导出；随后584增强红/红/绿和完整full-v2已通过，二者分列，详见同档案。


### 2026-10-06 EXP-FIND-REVEAL 本地Leader接续

Owner CODEX-LEAD（兼制作人）；Cloud已在PR375回执不并行修改。接收96c3215候选，松果/落羽贴图、路边白羽可读性、展示与提篮已由PR495合入06d0349c2346f2f009830e355a94039360955847并公开核验。296项探索切片、357项核心、27项天气、63项UI及Web导出通过；横竖实际渲染可读，普通Web松果发现→带上→返回→重开有限通过。音频听验与圆石资源另留未完；不关闭探索父单。

### 2026-10-06 #400 云带纸边越界接续

Owner CODEX-LEAD兼制作人，[认领6017728818](https://github.com/narutojzm1-dot/youjia/issues/400#issuecomment-6017728818)。接续QA PR497实际缺陷，限定YardWorld云Sprite region，原画/镜头/输入不改。红例复现、整像素裁切、照片兼容与镜头/UI必要回归、真实渲染前后对比及Web导出已完成，最终CI/发布待。见[证据](playtests/2026-10-06-cloud400/README.md)，不关闭原用户路径总单。

### 2026-10-06 Grok界面集中审查与组合

实现Owner GROK-CONTRIBUTOR，集成Owner CODEX-LEAD。原作者PR487/492/493/498/499均已交组合，原提交与证据保留；本地14986必要检查、Web导出、生产UI真实渲染及普通Web390→844暂停/确认/取消通过，最终组合CI与发布待，未提前标为已上线。[组合证据](playtests/2026-10-06-grok-ui-integration/README.md)。

| 需求 | 范围 | 状态 |
|---|---|---|
| REQ-20261006-042 | 存档等待纸片避让与双语，不改重试状态语义 | 已实现，组合验证中 |
| REQ-20261006-043 | 矮横屏暂停纸片内容贴合 | 已实现，组合验证中 |
| REQ-20261006-044 | 标题简介与操作说明平衡换行 | 已实现，组合验证中 |
| REQ-20261006-045 | 院内目标提示纸片按文字收窄 | 已实现，组合验证中 |
| REQ-20261006-046 | 照片题词在56px纸条内完整显示 | 已实现，组合验证中 |
