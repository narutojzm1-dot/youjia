# 2026-10-06 12:01 独立冒烟体验报告（供用户查看）

Agent-ID: GAME-QA。本人实际普通输入游玩；不委派、不开发修复、不发布游戏。**核心冒烟闭环及6个原生专项通过；旧相册错配仍在，阴天纸边异常复现；真实音频和完整流程未覆盖，不足以判定全量发布通过。**

计划北京时间12:00，实际心跳12:01:09.484，延迟69.484秒；具体游玩结束见[environment.json](evidence/environment.json)，原生12:07:24—12:08:33。并非完整游戏深测或准点完成声明。上一份PR479仍开放，最终80feb046e8fd4edd9eb583f0ff767f814be2af9a，不覆盖其历史报告。

## 版本、环境和来源

- 普通线上首次与关页重开DOM均为`game-3e06802`，GitHub可解析完整SHA `3e0680210b69665a5a46ad295ed3fe71e10d512a`。Windows指定Chrome实例，第一次1646×894，关页重开自然视口1646×838；未人为设备模拟。既有假期第7天、花朵及旧相册，未重置/清缓存/写存档或注入游戏状态。
- 安全fetch与报告准备时main为0cc6d794c80b1dd94ec5b79c4d7deab980c5ce65，与线上不同；本地HEAD从267b0cb安全切换到线上对应3e06802，原生测试确实跑此SHA。Release/tag查询均为空；无Release不能冒称正式Release验证。本轮独立HTTP公开PCK字节数和SHA256见[public-pck.json](evidence/public-pck.json)，不等于浏览器内存或完整manifest核验。
- 影响清点：相对上一轮d210，原画阴天对齐及字体Theme/提示集成进入此版本；自动测试选提示样式/真实输入/天气/音频与探索/鱼携带回归。静态清点只判断覆盖方向，不算实玩通过。
- 浏览器两次入院鼠标命令超时，后续截图证明已入院；属于操作工具超时，未当产品BUG。Godot隔离APPDATA及每套件匹配XDG/marker，先验证用户数据目录；未触碰Chrome生产存档。

## 实际体验与证据

| 项目 | 实际操作与结果 | 证据 |
| --- | --- | --- |
| 启动 | 实际进度加载壳水彩小院，随后花纸标题，入院正常 | [01实际加载壳](evidence/01-initial.png)、[02标题](evidence/02-title.png)、[03院子](evidence/03-yard.png) |
| 动物交互 | 近处点羊，反馈“你轻轻摸了摸羊。” | [04](evidence/04-sheep.png) |
| 手账 | 打开、往后翻、合上正常；历史第1页仍绵羊题词配马/羊驼 | [05](evidence/05-album.png)、[06](evidence/06-album-next.png)；不冒称新照片缺陷 |
| 暂停/音频 | 三组按钮各关开1循环，恢复原开着100%状态；未真听 | [07](evidence/07-pause.png)、[08音乐关](evidence/08-music-off.png)、[09环境关](evidence/09-environment-off.png)、[10总静音](evidence/10-muted.png)、[11恢复](evidence/11-audio-restored.png) |
| 核心散步闭环 | 点门前路径、Space出门→点击沿路走→Space停看圆石→拾取→放回→重拾→R回院，显示圆石收好了 | [12入口目标](evidence/12-explore-entry.png)、[13散步](evidence/13-explore.png)、[15发现](evidence/15-discovery.png)、[16中文演出](evidence/16-pick-6.png)、[17放回](evidence/17-put-back.png)、[19收好](evidence/19-stone-stored.png) |
| 恢复 | 真关首标签、普通新标签，仍同构建；第7天/花朵恢复 | [20标题](evidence/20-reopen-title.png)、[21恢复](evidence/21-restored-yard.png)；未独立核对圆石累积库存 |
| 晴阴回归 | 普通天气按钮切换，房屋/山体/池塘/围栏主要构图保持；阴天左右纸边云带截断异常两帧可见 | [21晴](evidence/21-restored-yard.png)、[23阴](evidence/23-overcast-stable.png)、[27复核](evidence/27-overcast-repeat.png)、[30最终晴](evidence/30-final-sun-stable.png) |

原始截图全部保留；16-pick-1至6及26-weather-1至6只是顺序截帧，不是固定帧率录像。14-route-arrived文件名保留，实际是沿路走途中，不凭该帧宣称已抵达；28-final-sun文件名保留，实际仍阴天，30才是最终稳定晴天。真实截图说明优先于旧命名。两份warn/error日志为空，仅证明本次捕获未见旧接口错误，不证明可听播放。

## 自动测试（与普通实玩分开）

Godot4.7.2.stable.official.ed1daf0bf，源码 `3e0680210b69665a5a46ad295ed3fe71e10d512a`。通过仓库verified_godot.sh，要求进程成功、完整错误扫描无失败、唯一登记完成行和正检查数；不是只看PASS。原生导入成功，以下6套件全部通过，合计**1,388检查**：

| 套件 | 检查数 | 边界 |
| --- | ---: | --- |
| paper_tooltip_style | 104 | 引擎真实悬停样式及主题；不是普通Web鼠标悬停体验 |
| paper_tooltip_interaction | 230 | 隔离原生Main输入、触屏/窄视口等夹具；非实体手机 |
| weather_transition | 27 | 定时、暂停、反转、背景资源及权重断言；不替代像素边缘验收 |
| audio_button_input | 648 | 按钮/滑杆输入和状态；不等于真实听验 |
| exploration_slice | 285 | 探索状态/归还/布局/存档夹具；非全部普通Web路线 |
| fish_carry_consistency | 94 | 隔离短时参数/携带存档回归；未普通Web钓鱼成功/过期实测 |

[原始results](native/results.json)、每套件完整日志和wrapper日志均归档。使用隔离目录，5个本轮Godot生成的tracked import变更先保存patch再仅恢复这些已知文件；实际tracked diff为空。[清理记录](native/source-cleanup.json)保留38个未跟踪UID，不删不提交。早晨文档“139生成UID”是状态行误计含import假阳性，本轮明确纠正，未改写旧测试结果。

## BUG台账与关卡

- QA-EXP-20261003-001：主要构图在新版限定桌面晴阴样本通过，其他设备/自然天气尚未全验，不全局关闭#168。
- QA-EXP-20261003-002：旧相册题词错配仍可见；历史生成版本未知，本轮未生成新照片，不否定既有新照片修复。
- QA-EXP-20261003-003：这次真的保存加载壳，限定本样本符合小院主题；标题页不作加载壳证据。
- QA-AUDIO-20261004-001（P1）：旧接口错误0/2，UI和原生专项通过；真实听验未做，保持待验。历史#231鱼携带问题只做原生94检查，Web普通成功捕获和自然过期尚未覆盖。
- QA-EXP-20261006-004：本轮中文圆石可读性修复回归通过，其他物品/设备未覆盖。
- QA-EXP-20261006-005（P2观察）：阴天云带截入纸边的竖缝两帧复现，关联已存在#400，不新开重复issue；不是确认原相机偏移同根因，也不把天气布局已改善和边缘问题混作一项。

完整步骤、预期/实际、严重度、版本、状态、样本率见[bugs.json](bugs.json)。**通过：上述限定启动/交互/散步/恢复、原生6套件；失败：历史相册视觉错配及阴天边缘验收；阻塞/不足：真实音频、全流程与全平台覆盖。发布关卡不放行全量。** 没有完成所有长期主线、全部物件/关卡、满篮替换、所有成长经济、失败重试、跨设备/浏览器/语言、长时性能与全部历史BUG的普通Web回归。

报告以独立PR提交，不直接推main，不开发或修复。仓库最新团队文件改为Leader23:00集中审查；本轮心跳仍明确要求最终SHA独审，因此保留未合入，不自审也不改仓库审核规则，交由Leader处理。
