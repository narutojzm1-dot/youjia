# 2026-10-06 16:01 独立冒烟报告（供用户查看）

Agent-ID: GAME-QA，本人普通输入测试，无委派、无游戏实现修改或发布。**启动、入口、散步拾物回院与既有存档恢复通过；2个原生P1专项742检查通过。历史相册错配、阴天云带纸边异常仍可见；真实听验及全流程不足，全量发布关卡未放行。**

计划北京时间16:00，实际触发16:01:36.591，延迟96.591秒；环境记录及游玩结束上界见[environment](evidence/environment.json)。原生16:04:19—16:04:38，不能伪称准点完成或完整游戏深测。中午报告PR494仍OPEN，最终b5ce241995391ee96eb6d77991f087fcb02d16f7；本轮新建独立档案，不覆盖前轮。

## 版本与环境

- 首标签250390144及实际关页重开250390148，DOM都为`game-3e06802`，完整SHA `3e0680210b69665a5a46ad295ed3fe71e10d512a`。Windows指定Chrome，首次1646×894，重开自然1646×838，未人为模拟设备。用户既有第7天、花朵与历史照片，未重置或清缓存、不注入游戏状态/存档。
- 安全fetch成功，main保持0cc6d794c80b1dd94ec5b79c4d7deab980c5ce65，与线上不同；Release/tag本轮查询均为空。[version.json](evidence/version.json)。原生源码保持线上对应SHA，tracked实际diff在运行前后为空。main与线上无新变化，不重复中午样式/天气/探索整套验证；按本轮要求执行高严重度音频/鱼携带专项。
- 独立HTTP公开PCK 27,554,756字节，SHA256 `f74721adbd43c97d16045d1179b8e83e4de16583c75f8f2c944c9c79df0d9df7`，与中午一致，[原件](evidence/public-pck.json)。这是公共资产读取，不等于浏览器内存或完整manifest/发布工作流后验。
- 重开入院一次鼠标操作超时，后续画面确认已经入院，属于环境工具问题，不计产品失败。截图存在短时旧帧，已单步追加核实，按可见状态标注，不能仅凭文件名判断通过。

## 普通实玩

| 项目 | 实际结果与范围 | 证据 |
| --- | --- | --- |
| 启动与入院 | 真水彩院子加载进度壳→花纸标题→第7天院子 | [01壳](evidence/01-initial.png)、[02标题](evidence/02-title.png)、[03院子](evidence/03-yard.png) |
| 绵羊 | 单步重测，明确“你轻轻摸了摸羊。” | [24](evidence/24-sheep-confirmed.png)；04早期帧未保留反馈，不能独立证明成功 |
| 手账 | 打开、翻至第3/4页、合上；历史第1页题词错配仍在，未产生新照片 | [05旧图](evidence/05-album.png)、[25实际翻页](evidence/25-album-next-confirmed.png) |
| 暂停/音频 | 音乐关闭、恢复；环境关闭、恢复；总静音后恢复，最终全开100%；仅UI状态 | [11实际静音](evidence/11-audio-restored.png)、[18音乐关](evidence/18-music-off-confirmed.png)、[19环境关](evidence/19-environment-off-confirmed.png)、[20稳定恢复](evidence/20-audio-stable-restored.png) |
| 散步闭环 | 点门前小路、Space出门→溪声点停看无物→继续走小路坡下→发现圆石→拾取入篮→R回院 | [12入口](evidence/12-explore.png)、[13空点](evidence/13-discovery.png)、[15坡下发现](evidence/15-next-discovery.png)、[16中文短展示](evidence/16-pick-6.png)、[17回院暂停](evidence/17-audio-current.png) |
| 天气 | 晴阴主要构图保持；阴天云带纸边竖截断仍在 | [03晴](evidence/03-yard.png)、[21阴](evidence/21-overcast-stable.png)；非连续视频，不声明所有过渡帧通过 |
| 保存恢复 | 真关首标签、新标签入院，仍同构建，第7天/花朵恢复、历史相册可读 | [22标题](evidence/22-reopen-title.png)、[23院子](evidence/23-restored-yard.png)、[25手账](evidence/25-album-next-confirmed.png)；未独立核验圆石累计库存 |

原始早期08-music-off、09-environment-off、10-muted实际仍显示开启，是滞后帧，不计关闭证据；11-audio-restored实际显示总静音，不计恢复；06-album-next仍第1/2页，25才明确第3/4页。原文件保留不改名，图注和事实以此为准。16-pick-1至6为连续截帧，不是固定帧率录屏。两份warn/error日志均空，只证明本次捕获未见旧接口错误，不证明播放可听。

## 原生专项与静态清点

Godot4.7.2.stable.official.ed1daf0bf，隔离APPDATA并先核OS用户目录，各套件独立匹配XDG/marker。由仓库verified_godot.sh执行，导入成功，严格进程退出/全日志错误/登记完成行门禁通过：audio_button_input **648/0**，fish_carry_consistency **94/0**，合计**742**。原始[results](native/results.json)、完整套件与wrapper日志、[runner](native/runner.py)均保留。这是原生夹具输入与短时鱼携带一致性，不能替代普通Web钓鱼成功、自然过期或真实听验。

静态版本清点没有变化，不算实玩测试；中午其他套件通过只引用历史结果，不计本轮新通过。5个本轮引擎生成tracked import变化先保存patch，仅恢复已知生成文件，[清理记录](native/source-cleanup.json)；未跟踪UID全部保留，不混入PR，不改游戏代码。

## 去重台账与关卡

沿用QA-EXP-20261003-001/002/003、QA-AUDIO-20261004-001、QA-EXP-20261006-004/005，完整步骤、预期/实际、严重度、复现率、版本和状态见[bugs](bugs.json)。001主要晴阴构图限定样本通过；002旧照片错配仍在；003加载壳样本通过；004坡下圆石中文限定通过；005同版纸边异常1帧再现，继续关联#400，不建重复issue、不认定原相机偏移同根因。P1音频真听未完成，保持待验；#231仅原生94检查通过，普通Web自然过期未覆盖。

**通过：本轮限定核心冒烟与2原生专项。失败：旧相册视觉错配与阴天纸边验收。阻塞/不足：真实听验、普通Web鱼成功/过期、长期主线、所有物件/关卡、满篮替换、成长经济、全部失败重试、跨设备/浏览器/语言与长时性能。未执行项不当通过，全量发布关卡未放行。** 下一轮20点深测维护覆盖矩阵，优先补未覆盖主流程和历史BUG；定时配置不代表其已经执行。

本报告只提交独立PR、不自审不合入。仓库集中23:00审查规则另记，本轮心跳仍要求最终SHA独审，保留待审由Leader接续；QA不承担开发。


## 提交阶段版本补记

16:01安全fetch时main为0cc6d79，没有中午后增量；生成报告分支时main新增06d0349c2346f2f009830e355a94039360955847（PR495松果/落羽正式视觉接入），所以本报告PR的真实父提交是06d0349。此新增影响find_reveal/keepsake_art/near_path_scroll及探索测试，尚未本轮回归，不套用3e原生/实玩通过。16:16公开HTML再次核实data-build与config.executable都仍game-3e06802；game-ca1fb67只是注释示例。当前已发布普通页面和新main候选分开记录，后续部署变化需补影响回归。上文无增量仅指开测时刻，不代表提交全程无仓库变化。

环境最初记录发生在追加25翻页证据前，现保留原记录时刻，另列本轮游玩结束上界，避免将较早的environment写入时刻当成最后操作精确时间。
