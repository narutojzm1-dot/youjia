# Cloud 当前可执行探索队列：只读范围审计

审计者：CODEX-LEAD 独立协作子代理 `leader_scope_audit`，不代表既有 CODEX-LEAD-ASSISTANT。观察时间为2026-10-05 22:00 UTC后。远端main `a0bb75e38e59032a6df72a2122af4403c3c3e816` / tree `8394f116f24295b0800824e90db1cf56d9334c1d`；本地同树 `d633d18dbe4ee54ffd04f8410e9d8f6defc7936f`。读取原单正文/末评论、GDD/规范/认领表、已合PR与真实代码；未开引擎/浏览器、未修改仓库或留言。

**结论：不是整个探索队列只能等375。至少有一项已批准适配边界尚未处理：拾物短展示在窗口变化时仍用旧屏幕坐标。可由Cloud立即独立复现、修正、验证；无需新增资源、用户选参数或Leader前置审核。** 这是源码发现，尚未实际运行复现，不冒称已在公开页面触发。除此之外，未发现另一个可安全直接开始的全新玩法功能；不能为填满队列扩七页、季节/种子、布置或重做原型。

## 1. 建议唯一优先切片：拾物展示跨视口变化的生命周期

### 已有授权与精确缺口

- [#153](https://github.com/narutojzm1-dot/youjia/issues/153) 已授权键鼠/触屏/低动效往返；[原画方向的适用验收](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/docs/architecture/exploration-painted-path-direction.md)明确要求「低动效、暂停/恢复、失焦、窗口变化无输入残留或人物丢出视口」。
- 已合 [PR372](https://github.com/narutojzm1-dot/youjia/pull/372) 与 [find-reveal契约](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/docs/architecture/exploration-find-reveal.md)已要求短展示在手机安全区、不压底栏、随时可打断；不需要批准新的演出玩法。
- `scripts/exploration/near_path_scroll.gd::_start_reveal`（237起）在拾起时计算一次屏幕 `from/top/basket`，交给 `FindReveal.play`。`find_reveal.gd::play`（54起）保存这三组屏幕坐标；`pose`（97起）整个生命周期仅对旧坐标插值。
- 同时，`NearPathScroll::_process/walk/_snap_camera` 与 `_refresh/_layout` 会依据新 viewport 更新相机、按钮和提篮；`_notification`只处理暂停/失焦，没有 `size_changed`、尺寸比较或展示重定位/收尾。展示本身不随相机移动（HUD CanvasLayer）。因此窗口变化时，场景/篮子已重排，临时展示仍留在旧屏幕位置。
- 独立读取 **PR375精确head `753f1795831e1f3be8032796f6e50b754dd55413`** 的这两个文件，仍是同一结构；375修改纸片、资源、停音，未补尺寸变化。不是提出其已做的v2返修。

静态数值旁证（纯源码公式，非引擎/浏览器实测）：已存在gate站距590的脚点约(1278.1494,608.7926)。1280×720全构图下，展示top.x约978.3078、光晕左缘约922.3078；缩到390宽而生命周期未结束时，旧横坐标整个在屏外。原basket终点y602，而390×844新篮位约732，终点也不再对齐。该推导不声称精确渲染帧或用户已报告此问题。

### Owner、方法范围与依赖

Owner仍 **CURSOR-CLOUD**，可在#153原单认领一个独立分支/PR，状态先“复现中”，给实际方法/下一交付；未回执不能写其已接收。该缺口属于其探索适配器，不把工作转给Leader/Assistant；不要改Producer #400的整体相机、绘画或Main输入。

允许最小修改：`NearPathScroll`尺寸变化检测与短展示收尾/重新定位接口、必要 `FindReveal` 生命周期方法、探索专项相应案例/体验证据。**不改** 375纸片配色/小物贴图/短音、电平、人物/路线比例、候选时长、掉落概率、Host、SaveStore、Main。375和本片同为Cloud拥有；作者在分支间保留原件并自行合入修正，不能由其他代理并行改它。

可按现有“展示可随时打断且不影响篮子”规则，在尺寸变更时安全收尾；或完整更新所有屏幕锚点。选择由Cloud按最小正确实现判断，不在本审计替其冻结新演出设计。不能用重新调用play导致重复声音、重置时长或重复授予。

### 独立可完成的验收

1. 先用现有main资源复现：1280×720拾起进入升起/停留/飞入时改390×844，并反向；加入低动效及568×320，记录精确源与阶段。普通Web可走正常路/E/T并在首个成功拾起时改视口；不要刷满篮或异名换物，不依赖375正式物件。
2. 受控专项可以固定现有核心seed到已存在站点，明确这是fixture：尺寸变化后一帧临时展示在新安全区/正确篮位，或按明确收尾策略已消失；不会留下屏外overlay、重新播放、二次`settled`/拾取、改carried/taken/存档授予。
3. 对照同一视口普通演出和reduce不回退；暂停/失焦/回院的旧收尾继续成立。用撤去尺寸处理的反证使新边界失败，避免只测试实现常量。
4. 真实Web普通输入的resize/横竖切换影像与只读状态证据；没有实体手机只能写模拟视口。作者自组织最终完整SHA独审、适用回归/导出后交付，不等待Producer听音或Leader签字。

这是一个适配功能的完整收尾切片，不建议再把每个视口或每个时相拆成工单。

## 2. 已做内容和排除项

| 原单/交付 | 实时依据 | 不能重复当作下一新任务 |
|---|---|---|
| #151/#152 | 核心314已进main，`ExplorationSession`/contract/catalog、严格357核心断言；原单最新Owner栏仍留314/尚无入口的旧快照 | 不按10月3日“契约未放行”旧评论重建核心；176 Draft是历史原型，非当前生产队列 |
| #153 PR322 | final7e4b46b…，merge81d225c… | 已有异步接入、三件容量/同名、换物、随时回院、暂停与恢复，不重做 |
| #153 PR342 | final678aa408…，mergebc213f9… | 原画沿路与固定缩放适配已交，不能重新做横走原型 |
| #305 PR368 | final4ca9fe3…，merge14084f9… | 多趟、同名换物、连R、关闭、双页等原证据已交；不重刷当新增功能 |
| #153 PR372 | finalbaaabd4…，mergee0bb109… | 拾物短展示程序已交；未交的是正式资源/听验，不再造第二个展示程序 |
| #399 PR418、432/434 | 门区域点击回院已合；启动生命周期与有限正式携物/关页已有Leader证据 | Producer跟进原反馈，不能抢其验收；不重改walk已修分支 |
| #305 PR427/438/441/443/445 | cleanup已修并正式验；445 finalfe56914…合8f464b2，只补typed夹具及真Main cleanup辨别，当前slice218 | 不重做INVALID、typed unknown或再刷两趟异名随机；异名与其余故障/真机仍由Leader/QA按原回执负责 |
| 近郊清底 | 当前runtime README明确已采用Producer393 c2f342d清底PNG ade3ee41…的WebP，main有真实前后证据 | 153旧评论/GDD历史中的“底图松果落羽还未清掉”不能视作当前待做代码 |
| #154 | OwnerLeader，216/217原型与232空间板已交；具体位置/自由度未批准 | 不能让Cloud接院内布置功能；样张/圆石语义位置归Producer既有资源队列 |
| #155/#375 | 375最新753f179 v2已交清底演示、白羽暖灰底及篮名底板；[实际回执6001368827](https://github.com/narutojzm1-dot/youjia/issues/155#issuecomment-6001368827)请求Producer认可 | 不另做资源或再做同v2返修。Producer实际看v2/听音、runtime-ready仍真实依赖 |
| #156 | GAME-QA原型/设备补测已指定，矩阵Q01–Q17已交，Leader共享平台故障Owner保留 | 不重建矩阵或把Cloud自测冒充GAME-QA独立验收/真机 |

PR372公开列出的“core拒绝、恢复旧旅程、回院补交、Esc没有单测”确实未被445补掉，但只为覆盖这些结构路径再造一套计数，不作为第二项优先功能。可在上面生命周期切片顺带保全相关边界；如以后单独安排，须有具体可失败回归依据，不能用测试数量填持续目标。

## 3. 真正外部依赖与状态修正建议

[Cloud22:00回报6003986205](https://github.com/narutojzm1-dot/youjia/issues/242#issuecomment-6003986205)写“等Producer…无受阻”，两者范围未分清。准确口径应是：**375正式资源接入等待Producer对v2明确认可/返修与听验；该等待不限制已批准的程序适配/生命周期验收。** 本次发现的resize切片可继续，未得到Cloud接收前只记建议。

- Producer：375 v2纸片/篮名资源可读性及runtime-ready结论；359短音真实听验/增益，路边落羽可读性、圆石正式候选/锚点、前景遮挡、03相邻页等具体资源仍按原单。旧媒体404已解除，不能继续记为访问阻塞。
- 用户/Producer：正式掉落频率/生态季节机制与时钟、多页到达重访/邻接和转场、展示候选时长/位置/音色、院内布置规则仍未冻结。不能从长期方向推导立即开发七页、交易、稀有度或季节系统；随机可空手已在现有目录实现，不能再做一遍。
- Leader/QA：#305异名换物/其余存储故障/实体设备仍未全覆盖，原Owner保持；不将此作为Cloud唯一队列。

除上述resize边界外，本次未找到第二个无需资源/产品选择且尚未实现的新增玩法功能。应明确这个小范围队列将耗尽，之后需要Producer交完整已确认首片材料或用户定后续可执行规格；不以无意义代码/验收探针掩盖外部依赖。

## 4. #180 / Assistant / WORKBUDDY 同方法冲突复核

已追加读取 [#180 原单](https://github.com/narutojzm1-dot/youjia/issues/180)全部正文及末页评论。当前顶部为 Assistant queued，明确「当前未实施本单代码」「不要并行修改…Cloud探索实现」；本单验收是大鹅骑马导演组合、演员尺度/朝向/中断、照片保存回放。末条 [5989070722](https://github.com/narutojzm1-dot/youjia/issues/180#issuecomment-5989070722)是Leader原生/Web兜底接管历史，**没有认领 `NearPathScroll` / `FindReveal` 方法**。WORKBUDDY保留资源/历史贡献，没有本次探索展示尺寸处理的活跃分支。

最新可见 [PM05:20回报6003217772](https://github.com/narutojzm1-dot/youjia/issues/242#issuecomment-6003217772)仍写Assistant382在途，其它WORKBUDDY无新本人回执/窗口未知；[ownership](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/docs/collaboration/goal-ownership.md)未将探索这两个方法划给180。开放PR中探索可见在途为Cloud自己的375、历史176；没有另一个Owner领取本尺寸变化处理的记录。结论仅限仓库可见事实，不推断私有未回执工作不存在。发153/242待接收时注明以上方法边界即可；不是接管180。

## 5. 给Cloud的普通操作复现单（先复现，后必要修复）

- 精确源码依据：[NearPathScroll `_start_reveal` L237](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/scripts/exploration/near_path_scroll.gd#L237)、[`_notification` L98](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/scripts/exploration/near_path_scroll.gd#L98)、[`_refresh` L416](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/scripts/exploration/near_path_scroll.gd#L416)、[FindReveal `play` L54](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/scripts/exploration/find_reveal.gd#L54)、[`pose` L97](https://github.com/narutojzm1-dot/youjia/blob/a0bb75e38e59032a6df72a2122af4403c3c3e816/scripts/exploration/find_reveal.gd#L97)。375同方法目前也无尺寸重排，前文已核其完整head。
- 采用已导出的对应候选或届时实际公开稳定构建，先下载manifest/PCK绑定真实源。fresh自用context，1280×720，正常首页/出门→沿路停下观察；不写seed、时间、人物位置、照片、存档，不在游戏内调用pick/play。普通点“带上”或T成功时记录画面，约0.15–0.40秒内用浏览器窗口尺寸操作缩为390×844，保原始连续截图/录像与输入时刻；同一个浏览器页面，无新增并行窗口。测试的变量就是实际窗口变化，设置viewport不等于业务状态注入。
- 若该站空手，按既有路径往下一站，最多单趟四站；全部空则明确普通展示路径未触发，不无限重刷，不改掉率。受控专项仍可确定覆盖，这两类证据分列。
- 第一判据：新视口中短展示是否仍可見，或已安全收尾；不可只看最终篮中有物。检查整个已现展示安全范围/卡片与按钮，不以一个坐标或最终静帧代连续画面。
- 第二判据：尺寸变化前后的唯一所得一致；正常随时回院后真实确认只授予一次。可只读存档旁证，不能注入或据此声称全305矩阵通过。未出现音频文件时只确认未触发新的播放调用，不声称真实听验。
- 先一个普通真实样本证实或否定静态风险，再将必要修复纳入前节完整生命周期专项及适用Web回归。低动效/反向resize可在专项确定覆盖；自然Web未命中其时相时如实记录。不得为了补截图延长展示候选参数、冻结游戏时钟或把受控截图冒普通操作。

第二切片本次不另推荐：368/372/305已有输入/往返证据，加重复计数不增加玩家功能；本片应一次覆盖调查→必要修复→无重播/仅一次拾取，不拆成几个空任务。
