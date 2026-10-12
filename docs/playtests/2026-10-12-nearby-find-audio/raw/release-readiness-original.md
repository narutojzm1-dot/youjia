# 2026-10-12 获批声音发布核查与接续

Agent-ID: ENGINEERING-SUPERVISOR（本轮兼声音体验审阅）。本报告是发布判断及原 Owner 接续要求，不是听感通过或合入授权；不接管 CODEX-LEAD 的集成发布。

## 核查结论

- 本轮核对 main `25aa96a26b8a18900c2400d7f9edd2c195151437`。公开 manifest 的 sourceCommit 同值，entry 为 `game-25aa96a`，publishedAt 为 2026-10-12 16:45:41（北京时间）。
- 本批 **14 项源素材获批；只有 01、04 已在当前正式源码中接入，且对应源码版本已有公开部署**。02、03、05–12 仍在候选；16、17 仍是隔离素材许可。不能把此表写成“14 项已上线”。
- [听验台账](https://github.com/narutojzm1-dot/youjia/blob/e2e55284ac53c65d98db5f10479a234e2fe3364e/docs/audio/hearing-2026-10-12.md)目前在 PR738 候选中，main 同路径尚不存在。请 Leader 随最先交付的已批准声音切片同步主线台账，避免许可信息被大型餐食 Draft 长期隔离。保留原台账与作者提交，不重写用户结论。
- PR738 当前完整头的 [CI38218699992](https://github.com/narutojzm1-dot/youjia/actions/runs/38218699992) 已成功。“当前 CI 待核验”已解除；普通 Web 当前组合、实体手机/后台生命周期仍未齐。
- **13–15 继续禁止正式播放**。13 R2 已送听不等于通过；14、15 原声被退回。本轮未制作、替换或重新送审任何素材。

## 证据边界

本轮完成的是远端源码/候选/评论审查、Git 树比对与公开产物实字节核对，没有运行 Godot 套件或声称真人听验。

| 公开产物 | 实收字节 | SHA-256 | Git blob SHA-1（与 gh-pages 一致） |
| --- | ---: | --- | --- |
| game-release.json | 2252 | `c5f167fb3f672b074f212977acd7fc489aab2be018f3a3f61ae7eca5caf1e238` | `60437a9d69390d7a83f753a6571dca021fe0d56a` |
| index.html | 360314 | `472532827760a7dbb643fdfc75efdf007c93979c47ae1a4a831fb7f39f8de607` | `c06046dac3b7eb3d947cbb15ac50dda4c34b5226` |
| game-25aa96a.pck | 74453332 | `863aab0f1e39fce4f42d0fc2204b0f5b891467163c1a66067ba5868ac7351acc` | `58f9b86eac36facc5cc4ba7ecedcc527896f38b8` |

PCK 的 SHA-256 同时匹配公开 index.html 中的资源完整性声明；[发布工作流38223517645](https://github.com/narutojzm1-dot/youjia/actions/runs/38223517645)成功。本轮未另做全部引擎/存档模块校验，不把产物校验当声音运行验收。

普通公开页面实际显示 `game-25aa96a`，但本次云 Chrome 返回「此浏览器不支持 WebGL2，无法启动游戏 / Missing browser features: WebGL2」。因此本次**未进入游戏、未验证出声、未覆盖手机**；不据此推断所有用户浏览器故障。

复用已有 [PR752 软件证据](https://github.com/narutojzm1-dot/youjia/pull/752)：旧 main5d23 + 623e00f 组合的普通 UI 27 状态、约700秒缓存观测和797.76秒软件录音有效，但不能覆盖新的整合头，也不是耳机/扬声器10分钟听感证明。不重复要求作者制作同一软件录音。

## 逐项发布判断

表中“已部署”只表示源码接入及该版本公开产物可追溯；整合听感、循环接缝、设备表现另行判断。所有使用许可严格绑定文末完整哈希。

| 编号 | 声音 | 当前 main / 公开版 | 已有候选或真实入口 | 原 Owner 的剩余动作 |
| --- | --- | --- | --- | --- |
| 01 | 院内白天音乐 | **已接入、对应版本已部署** | AudioDirector `yard.music`；主线与623同一资源 Git blob | Leader 保持获批字节；623整合后复验白天/夜间/进出场景淡化，QA补混音与设备听感 |
| 02 | 近郊白天音乐 | 未上线 | 623 已有 `near_path.music` / 场景切换适配 | Leader接续623到当前主线；Assistant只验近郊消费与往返，不再制作分场音乐 |
| 03 | 夜晚音乐 | 未上线 | 623 `night.music`，公共时钟驱动 | Leader复验两地自然入夜/天亮及切换中再次反向，不能保留旧白天轨尾播 |
| 04 | 院落白天环境 | **已接入、对应版本已部署** | `yard.ambience`；主线与623同一资源 Git blob | 保持环境30%输出上限；与17互斥，明确最终路由 |
| 05 | 蛙虫及偶发嘶声 | 未上线 | 623 `night.ambience` / RegionalSoundscape | Leader整合；QA核实际夜间混音、完整循环及长期舒适度 |
| 06 | 雨声 | 未上线 | 623 `rain.ambience`，公共真实天气驱动 | 晴阴雨反转、昼夜雨与暂停/静音均验；不改天气概率 |
| 07 | 睡眠呼吸/呼噜 | 未上线 | 623 仅确认后的 `house.stage == "sleep"` | 合并738房屋逻辑时保留真实 sleep 判定；保存未决/拒绝、做饭、刷牙均不播；醒来/标题即时停 |
| 08 | 界面打开 | 未上线 | 720 `UiInteractionAudio.play_open` 与 Main 钩子 | Grok保原叶子，补缺件安静降级；Leader整合并验真实鼠标/键盘/触屏一次操作一次声音 |
| 09 | 界面关闭 | 未上线 | 720 已修 visible→hidden 才播，幂等 hide 不响 | 不重修已闭环幂等问题；补反复开合/面板切换/静音/解锁实际链 |
| 10 | 界面翻页 | 未上线 | 720 只在成功翻页调用 | 首尾无效页0次、有效页1次、快速连续输入与70ms去抖一致，不用人为无播间隔类比边界 |
| 11 | 做饭持续声 | 未上线 | 738 MealAudioHost→真实 cook，已接线且哈希匹配 | **不重做Main接线**；Leader沿738修缺件替代音、补同SHA普通做饭/暂停/失焦/接管/退出 |
| 12 | 锅勺声 | 未上线 | 738 做饭叶子周期派发，停止/许可分开 | 同11；检查退出与恢复不积压补播，循环接缝与锅勺混合听感独立验 |
| 16 | 发现拾物 | 未上线；获批WAV不在生产树 | **真实成功入口已有**：near_path_scroll.pick()在take/swap成功后 _start_reveal→FindReveal.play；SOUND_PATH仍指缺失旧OGG | Assistant沿既有近郊范围接获批WAV映射/许可，Leader接续旧Producer资源；不重写拾取逻辑、事务、展示或存档 |
| 17 | 不等间隔阵风 | 未上线；仅339隔离候选 | 128秒完整环境轨，尚无生产映射；不是每阵风另触发的单发音 | Leader接续已停止独立运行的Producer；接入同一环境底层槽位，与04互斥，补场景/昼夜/雨混音验证 |

**16的最小改动边界：** `scripts/exploration/find_reveal.gd` 当前加载 `res://assets/audio/sfx/exploration_find_get.ogg`（main树不存在），资源为空即无声；获批文件是 `discovery_soft.wav`，不能只改扩展名假装无损转码。复制获批原字节到正式导出路径并显式引用/导入；保留 `near_path_scroll.pick()` 已有成功判定和 `settle(true)` 的暂停/失焦/离场停止语义。声音不负责添加库存。失败/取消/满篮未接受/重复输入不响，成功take及现有swap展示各一次；释放物件不响。若改由公共cue播放，应保留独立声部停止和不补播，不能只加一行play_cue丢失生命周期。

**17的路由接续：** 04/17都获批并不要求同时叠加。原339是替换候选，采用时先提交明确的“场景×时段×天气→底层文件”表及04保留/回退位置。可供Owner验证的默认方案是院内白天用04、近郊白天用17；这是工程建议，**不是用户已决定的场景配乐方案**。若沿原语义用17替换04，必须如实写04不再是当前默认播放项，不能凑14项“同时上线”。不新增玩家设置页、不另建AudioContext；切换时保持单一底层选择、环境整体30%上限与夜雨权重，验证04/17不重叠。

## 两处新发现：缺件时会播放未获批替代音

这不是已复现的正常游戏错误；是源码明确存在的异常路径，违反本批许可仅覆盖锁定文件的边界。正常完整资源包仍须实测。

1. **PR720 `scripts/presentation/ui_interaction_audio.gd::_register`**：register_cue失败会调用 ProceduralSfx.tone 生成另一种音并register_stream。请GROK-CONTRIBUTOR在原PR改成安静降级，资源缺失/损坏不得生成替代音；补对应负向检查。08–10原素材不改，已解决的幂等hide不重做。
2. **PR738 `scripts/presentation/meal_audio.gd::_load_cook_stream / _register`**：cook资源缺失会生成72→88Hz tone，spoon/hunger缺失也生成fallback tone。请CODEX-LEAD在已接入的738副本完成同类安静降级并保留原作者谱系；缺流时不调用空player.play、不反复报错，必要时测试替身仅留测试。**不要求Grok再做一套Main宿主**。叶子原单747仅同步处理范围，避免两边同时改同一修复。

13禁播当前在 `scripts/game/meal_audio_host.gd` 的 `HUNGER_AUDIO_APPROVED := false`，本轮核实为false；合并747 R2时仍保持。拒绝自动生成替代音也不等于批准13。14/15没有正式资源/调用，不因同组其它声音获批开启。

## 原 Owner 接续与有限验收

- **CODEX-LEAD**：沿623/738现有分支集成，处理共享 `autoload/audio_director.gd`、Main及房屋状态冲突；保留623的分场/夜雨/睡眠适配、738真实cook/13禁播与当前Cloud输入/焦点修改。核查时623/720/738/747返回mergeable=false，需在最终整合头重核，旧CI不能覆盖冲突解法。339/359当前可合并不代表可发布。当天可交付切片通过后推进，不把全部声音捆绑等待13–15返修或766施工完成。
- **GROK-CONTRIBUTOR**：720仅处理本叶子的缺件降级和实际UI链问题，资源已批准不重制；747的13仅在新用户确认后接续，不重复寄同版R2。所有最终修改仍由Leader复核完整SHA并合入。
- **CODEX-LEAD-ASSISTANT**：沿已接近郊职责处理16最小适配、02/17的场景兼容与往返；不复制Leader公共时钟/音景。原359中的Cloud/Producer标注为历史分工，不能重新派给已转UI的Cloud或已停止的Producer。
- **CURSOR-CLOUD**：保有整体UI及输入/焦点，只有真实方法冲突时协调，未在本轮转交新的音频Owner。
- **GAME-QA / #196**：消费Leader给出的同一最终SHA可运行导出，报告普通Web与实际手机分别覆盖；素材获批无需重新要求用户听01–12/16/17原文件。

必要的最小矩阵（用真实操作和实际输出对应，不新增空泛全量审批）：

| 场景 | 必须观察的结果 |
| --- | --- |
| 全新页面首次点击/触摸入院；解锁被挂起后下一次真实手势 | 背景和Godot短音两条实际输出链均可恢复，无伪解锁、无重复启动 |
| 小院↔近郊、自然昼夜、雨变、睡眠→醒来 | 选择正确获批轨、淡化连贯，04/17互斥；07只在确认sleep |
| 各循环越过实际尾→首；音乐/环境合听至少10分钟 | 耳机/扬声器记录有无接缝、爆音、明显重复/突兀起停；软件loop=true不能代替听感 |
| 音乐/环境分别关开、0音量、总静音、快速/慢速各10次 | UI状态与实际声源一致；关后不被迟到回调复活；恢复不用退标题；30%环境上限保持 |
| UI开合/翻页；take/swap成功与失败；真实cook进入/退出 | 成功事件与实际声音次数一致，取消/失败/无效页不发成功声；短音不排队 |
| 暂停、相册/背篓阻塞、失焦、切后台/锁屏、返回、回标题/重进 | 背景按既有duck/暂停契约，做饭/拾物按既有停止契约；不残音、不积压补播，重入只有一组有效播放器 |
| 适用手机 | 至少记录实际iOS Safari及项目支持的Android Chrome覆盖/未覆盖；横竖模拟不算实体设备，恢复可能需要新手势须实报 |

每项结果须绑定：完整源码SHA、最终候选/公开构建、PCK哈希、浏览器及设备/输出设备、操作、听到的现象/计数、证据路径、未覆盖。最终发布再核公开manifest→PCK→必要真实事件，之后才能把对应行改为“正式验收通过”。

已有本地HTTP审批拒绝及本次WebGL2缺口不得写成通过；由具备适用运行条件的原Owner/QA接收当前导出。留言不等于已接收，本报告不声称他们已开工或承诺完成时间。

## 冻结版本索引

| 项目 | 本轮读取的完整头 | 当前结论 |
| --- | --- | --- |
| main / 公开source | `25aa96a26b8a18900c2400d7f9edd2c195151437` | 01/04已部署；本次浏览器不能运行 |
| PR623 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | Draft；原头CI37842298365成功，待当前主线整合/实际音景验收 |
| PR720 | `f840f409ad14af1d21c594d1832da8ccc9d5f5d5` | Open未合；CI38151539553成功，需缺件降级及普通Web链 |
| PR738 | `e2e55284ac53c65d98db5f10479a234e2fe3364e` | Draft；CI38218699992成功，11/12已候选接线，13禁播 |
| PR747 | `e2b30e85d36b411d18a91ab1e18cf8f4e9ca1635` | R2送听，未批准13；本轮按head查询PR workflow为空，不能标绿 |
| PR359 | `0e07ef5eabcd5766726d1c9d95904b1ad8ef54e3` | Draft隔离素材16，真实成功入口已有但音频未映射 |
| PR339 | `75b0834994ad0b20e2b7cf2835b06fbad443e223` | Draft隔离素材17，无正式路由 |

## 14项获批文件锁定

以下转录738听验台账，只限定使用许可；Git树比对证实01/04在main与623同blob，其他12项获批文件不在main，禁止把同名不同字节当批准。

| 编号 | 内容/源路径 | 听验结果 | 锁定来源提交 | 文件SHA-256 |
|---|---|---|---|---|
| 01 | [院内白天音乐](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/bed_yard_music.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `2a01d83a2c6dfb14181dfd6a53b9c249591e18ad03f57e8f70f6a9ba57afd86c` |
| 02 | [近郊白天音乐](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/bed_near_path_music.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `3286356d45ffd5668f079ddffc7a3f687e4d38a5e9d1ef1c9387feff7b02a38a` |
| 03 | [夜晚音乐](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/night_music.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `76fdd7217aa67b3f19092a8509da247081234802047c3b92a4bdd439c201b7c2` |
| 04 | [院落白天环境](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/bed_yard_env.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `239efcb8235acb56e12450c2e40e409336c1c139403a07ee8b4803f621bde241` |
| 05 | [夜间环境：蛙、蛐蛐及偶发蛇嘶](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/night_air.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `f7c2f79bf76e9f1b779c3fe1ec2e2b3a690e1e8f7ce2de835b80b3dfd0f1de4c` |
| 06 | [雨声](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/rain_air.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `ffaaccb1e6eb3c94ea65dc372e90d302f57ddad78979032b36998e20ab9c2a05` |
| 07 | [睡眠呼吸和呼噜](https://github.com/narutojzm1-dot/youjia/blob/e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169/assets/holiday/audio/sleep_breath.ogg) | 通过，允许接入 | `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169` | `daefb9625d82b615fa9e379256a15b8041704745c21fdb7847582291d716c120` |
| 08 | [界面打开](https://github.com/narutojzm1-dot/youjia/blob/4bed08efb1538cb7285eb9b88debd9c1b53d34e2/assets/holiday/audio/ui_grok/ui_open.tres) | 通过，允许接入 | `4bed08efb1538cb7285eb9b88debd9c1b53d34e2` | `6e094f93b74226defa0df05e5272176cf74b3ac7d5f564b161efd954325297d7` |
| 09 | [界面关闭](https://github.com/narutojzm1-dot/youjia/blob/4bed08efb1538cb7285eb9b88debd9c1b53d34e2/assets/holiday/audio/ui_grok/ui_close.tres) | 通过，允许接入 | `4bed08efb1538cb7285eb9b88debd9c1b53d34e2` | `c670c37223508ff27bad6779d6f48e39cb29e3090eae643854c37231f7d6a718` |
| 10 | [界面翻页](https://github.com/narutojzm1-dot/youjia/blob/4bed08efb1538cb7285eb9b88debd9c1b53d34e2/assets/holiday/audio/ui_grok/ui_page.tres) | 通过，允许接入 | `4bed08efb1538cb7285eb9b88debd9c1b53d34e2` | `72227f6cd751846f7b352bd2b268ca1e4250aab628a5552ac5fc9c56c6c19f90` |
| 11 | [做饭持续声](https://github.com/narutojzm1-dot/youjia/blob/b303b742c9bda94ace56eee6f88373d267780af5/assets/holiday/audio/meal_grok/cook_loop.tres) | 通过，允许接入 | `b303b742c9bda94ace56eee6f88373d267780af5` | `2e9824a0be6cd199d4383d9593a4e184fb41ca9c558b5f91f340d7ef52f5ce1b` |
| 12 | [锅勺声](https://github.com/narutojzm1-dot/youjia/blob/b303b742c9bda94ace56eee6f88373d267780af5/assets/holiday/audio/meal_grok/cook_spoon.tres) | 通过，允许接入 | `b303b742c9bda94ace56eee6f88373d267780af5` | `b72eab1b9bf06842928aea36183a10f277b828cef21bfada150108b3ad700414` |
| 16 | [发现拾物提示](https://github.com/narutojzm1-dot/youjia/blob/0e07ef5eabcd5766726d1c9d95904b1ad8ef54e3/art/concepts/producer_discovery_audio_v1/discovery_soft.wav) | 通过，允许接入 | `0e07ef5eabcd5766726d1c9d95904b1ad8ef54e3` | `14d19c82019fe48ee7fa9b2d843e8bfc69fe155c59ef736e255ac40e8975aea3` |
| 17 | [不等间隔阵风替换候选（与04比较）](https://github.com/narutojzm1-dot/youjia/blob/75b0834994ad0b20e2b7cf2835b06fbad443e223/art/concepts/producer_env_irregular_v1/env_irregular_candidate.ogg) | 通过，允许接入 | `75b0834994ad0b20e2b7cf2835b06fbad443e223` | `17c1eeee67fae2dbf5790a5d2a7a8d14e8462b0c0660a06c831bc5eb60d595d9` |
