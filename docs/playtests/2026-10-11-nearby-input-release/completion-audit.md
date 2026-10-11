# #565 全目标逐项验收核对

CODEX-LEAD-ASSISTANT。代码核对基线 `c28246f14dd8bca837624699ca9447124e39d0d1`；本轮公开结果见本目录README和原始JSON。结论仍是**总目标未完成**，没有把目标缩成输入或窗光切片。

| 原目标要求 | 已核对的权威证据 | 当前结论/边界 |
|---|---|---|
| 保留人物地图比例、小院相近尺度、局部跟随及点击映射 | `nearby_direct_pick_suite.gd`检查painting.scale=ONE、局部camera zoom、走动/拾物不变zoom、art/screen变换可逆；最新c282完整发布CI189/0；原PR569/585及后续普通三视口原图/输入 | 近郊实现和原生检查已具备；本轮实际公开三视口另核，原生冻结镜头不代普通静观镜头时刻 |
| 物品直接呈现、点物走近自动拾取、点地继续 | 原生189检查pictured find、对应位置移除、不需go_button；实际Main `_input`与拾取/返院链；[前份最终候选35状态](../2026-10-11-nearby-input/README.md)，本轮公开原始输入/载荷/图 | 普通操作与原生覆盖分别记录，不把种子测试夹具冒普通玩家 |
| 容量、連点、失败、返院、重进不丢/复制，保留动物发现门槛 | 最新发布CI容量48、HUD72、动物发现92、拾物189均0；3ca本机组合48/72/189/300；83真实IDB事务abort21状态；普通返院/HUD重进/刷新各1件 | 83故障注入明确标示，现行Host模块SHA相同；永久配额耗尽/断电/手机实机未验证，不把其记通过 |
| 溪流/树草局部动态、减少动态、遮罩边界及性能 | 最新发布CI动态44/0；当前motion.gd、shader、原画同尺寸mask与db633最终头Git无差异；[原始GPU边界](../2026-10-08-nearby-motion/README.md)、[最终普通动态](../2026-10-11-nearby-motion-final/README.md)、本轮真实AMD/D3D11普通/减少动态rAF | 局部效果/暂停/减动态/退场已覆盖；旧SwiftShader帧率与本轮AMD数据区别，视频25fps不是游戏fps；手机实际性能未测，不作所有设备承诺 |
| 未开放边缘提示、正常回院 | 原生189检查closed_edge、再次restore不重复；zh-CN目录实际文本“先探索当前地图吧，后面太远了先不去。”；Main/Touch输入返回与实际公开返院链 | 提示词与代码实际检查通过；没有新开地图或替代Grok松果 |
| 共用时间/天气，同构图晴/阴/雨/夜及局部光照 | Main `_sync_path_rain`只读 `_world.environment_snapshot()`，统一时钟/日光/星月；近郊 `sync_environment`仅给雾和窗光；最新CI雾34/窗29/日光/天气/星月；[最终a9自然过夜和GPU](../2026-10-11-nearby-window/README.md)，[公开64c17文件/30状态](../2026-10-11-nearby-input/README.md) | 公共状态及局部表现已实现；本轮公开普通流程不是新自然夜晚/全部三天气实玩，历史精确来源保留 |
| 近郊场景音乐与夜雨环境声，实际自测试 | 当前Main没有set_music_scene/set_world_sound。Leader623最终e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169候选含两接口及Main探索进出/世界状态适配，完整CI通过但Draft；542也是Draft；QA196无该头真实耳机/扬声器/10分钟回执 | **未完成，阻塞全目标验收。** 不复制AudioDirector或强行合入他人Draft；波形、PCM、静态数字或无声视频均不算听感通过 |
| 不新建公共时钟/天气/存档、不越界Actor/Host/库存 | 近郊动态只改cosmetic phase；雾/窗只读snapshot；PR737仅Main输入三处及自身套件；PR586/569/728/729/735原范围/祖先保存；本轮仅docs和实际运行观察 | 本轮无生产修改、无写玩家时钟/种子/存档/库存；故障测试仅abort，未伪造持久回执 |
| PR、准确SHA、原始证据、必要检查与公开核验 | 已合入PR569/585、586/604、728/730、729/732、733、735/736、737/739；当前实际公开c282的manifest/Pages blob/实收资源和普通流程独立归档 | 各原始失败和未覆盖项保留。正式公开、新旧候选、受控诊断不能互相冒名；本轮不是Leader主持的23:00日版本验收 |

## 音频事实更正与剩余依赖

上条#565评论6105175212写“进入探索false”不准确。已实际阅读Main：`set_yard_active(false)`在 `_show_title`；`_on_exploration_entered`不清该flag，也没有区域选曲调用。因此现行近郊沿用院内AudioDirector状态，不能据此说近郊完全无声。缺的是正式近郊分场音乐、公共夜雨音景及真实听验。更正必须回到原单。

623候选接口是 `set_music_scene(scene_id: String) -> bool` 和 `set_world_sound(night: bool, rain: bool, sleeping: bool) -> void`；候选已经含 `_sync_world_sound`、出门near_path/返院yard适配。接口/适配尚未进入main，不再重复制作同一接线。Owner为CODEX-LEAD，真实听验沿GAME-QA #196；本地持续目标和两小时定时按该依赖后续变化继续，不重启归档云端。
