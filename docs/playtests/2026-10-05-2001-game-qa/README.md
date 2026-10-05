# 2026-10-05 20:01 独立深度体验报告（供用户查看）

Agent-ID: GAME-QA。**部分通过、关卡阻塞；完整流程未完成，覆盖不足，不足以判定全量发布通过。** 不是完整游戏验收通过。实际游玩由本人独立完成，无委派、无开发或发布。

## 时间、版本、存档与环境

- 北京时间20:01:35触发，较20:00延迟1分35秒；实际观测结束时间见[environment.json](evidence/environment.json)。
- A：线上`game-bc8a048`，SHA `bc8a048b964cf39b80291b375f36f7362f0deedc`，首标签250390106；B：真正关页重开时更新至`game-1a3842c`，SHA `1a3842c63558fa68a68ca41c2da58f4c5a254929`，新标签250390110。A结果不转记B通过，跨版本恢复单独记。
- 开始main `1a44c8c568ab7e06cf0fea29809a3f194a08dffa`，结束核对`5bb2102aa7d4fbf1c53953d9148762a0495c4c89`，本报告归档基线`a067ce9b6674d5c1b35cdc2410f3d507f0f4d6a0`。查询Release/tag均为空；main/线上不同，未将main冒充发布版。
- 安全fetch成功，origin/main从f517f91到1a44c8c，Git提示forced update记录为远端引用更新，不覆盖本地文件。source仍无完整工作树检出；没有执行Godot自动测试。
- Windows / 指定Chrome实例7fbe129d-31ea-4709-8775-b6babc5bc8f8，浏览器3。原有用户第4天、15照片存档；未重置/新建独立档，实际自然进展到第5/6天。
- 初始1646×894；临时390×844、844×390；重开自然视口1646×838，临时覆盖已reset。非手机真机、非DPR多设备验收。真实音频不可听验。
- 已读QA说明、历史16:02报告与BUG、最新AGENTS/CONTRIBUTING/agents/game-design/requirements/decisions及qa-reporting。新探索首片、物品容量/保存确认方向按仓库口径，不把未来7页当成已发布玩法。

## 体验发现

标题的文字和按钮比下午版本明显可读，手账在竖屏单页、窄横屏的图文重排也更清楚。近郊画卷有明确道路、可停看的地点和提篮，落羽带入篮中的反馈直观；单次往返比单纯院子互动更有探索感。但院内目前未从玩家界面核验收藏物数量，不能只凭回院就宣称物品持久保存。晴阴时整座院子构图切换仍破坏同一地点的连续感。

首次加载实际停在0MiB至53秒，出现重试按钮；点击后工具超时，后续截图显示标题正常，是否恰为重试促成恢复无法严格区分。保存为可恢复加载异常/环境观察，不直接新增产品BUG。首次入院点击也有工具超时但游戏已进入，环境工具异常和产品错误分开。

## 本轮覆盖矩阵

A/B指上列实际构建；“局部通过”不能替代完整流程。“未覆盖”不算通过。

|测试项|实际版本|结论|步骤、观察与覆盖边界|证据编号|
|---|---|---|---|---|
|启动/加载/重试|A|部分通过|0MiB持续53秒；页面重试后标题正常；无错误日志，暂作加载/环境异常非确定BUG|01-04|
|院子与时间成长|A|局部通过|既有第4天自然到第5天；没有验证完整多天种植生命周期|04、15、17|
|绵羊/马关系互动|A|局部通过|实际看到轻轻摸了摸羊/马反馈；新照片未生成|07、08、09|
|草料获取/羊驼投喂|A|覆盖不足|手里多了一束草并持草走近羊驼；后续草消失/羊驼跳跃，未保留明确吃草反馈，不判完整投喂通过|17|
|花箱/种植浇水|A|覆盖不足|花箱及花圃目标可选，既有嫩芽可见；未完成浇水→成熟→采摘全流程|04、17|
|钓鱼/失败重试|A|局部通过|三次进入等待，首次见收杆提示但错过，后两次也未钓得鱼；能重试，不是产品失败；成功收鱼/投鱼未覆盖|14|
|探索模式最短闭环|A|局部通过|出门→路面行走→溪声近处停看→带落羽→坡下看景无物→R回院；篮显示落羽、回院提示；收好了确认提示未截取，持久化物品数不能验收|10-13|
|探索三件/第四件替换/放回|A|未覆盖|本趟只取得1件，未触发容量/替换边界；放回按钮可见但未执行|12|
|探索中断与存档恢复|A→B|局部通过|第二趟空篮出门后真正关页重开，线上版本变化；B安全进院先恢复第5天随后自然第6天，旧15页手账与嫩芽保留；落羽持久化数量UI不可核验|21-24|
|手账/页码/边界|A、B|局部通过|旧第1/2页和第15末页前后核对、末页后翻禁用；中间页通过导航但未逐项审校全部题词|08、09、23、24|
|UI/键鼠/兼容|A|局部通过|鼠标沿路/拾物、Space互动、R回院、Escape暂停；390×844竖屏单页/暂停、844×390横屏手账适配正常；非手机真机/触摸/DPR2或3|18-20|
|音频|A、B|阻塞验收|旧接口错误未复现；A滑块23%/98%/100%、环境单轨关闭恢复、总静音恢复UI响应。未听验、未完整10慢10快/后台矩阵|15、16、日志|
|存档故障/异常边界|A→B|未覆盖|未注入事务abort/丢回执/配额满/双标签并发；不把自然重开当故障验证|21-24|
|鹅马演出/低动效/全部关卡|A、B|未覆盖|没有自然完成鹅马演出；仅首片近郊，不代表规划的全部世界页|—|
|经济/长期成长/性能|A、B|覆盖不足|观察日数4→5→6与动物活动；无长时性能采样、FPS/内存量化、离线多日经济验证|环境日志|
|历史BUG全回归|A、B|覆盖不足|001仍观察；002旧图、新图待补；003桌面加载通过；音频旧错误未见但听验未补，不能称全部历史BUG通过|bugs.json|
|自动测试|无|未执行|source没有完整工作树；只清点tools验证脚本/Godot4.7.2文件，未运行引擎测试|—|
|静态分析|A→B|仅变更范围核对|GitHubcompare非docs变更含main.gd、hint_paper_fit_suite及daily脚本；未逐行代码审计或宣称修复正确|版本记录|

## BUG台账与下一验证缺口

[bugs.json](bugs.json)保留唯一ID、别名及原issue链接：QA-EXP-20261003-001本轮A自然晴转阴1/1观察；002旧照片生成版本未知，本轮第4/5天轻抚未新增照片，不能据此否定#320修复或关闭；003本轮真实桌面水彩院子加载壳通过，其他加载矩阵不代替；QA-AUDIO-20261004-001旧接口错误各构建0/1新标签进入，实际听验仍阻塞。无新确定产品BUG、不接开发Owner。

后续需要自然生成新绵羊照片、种植完整周期、钓鱼成功与投鱼、探索3/4件与放回、携物中断存档数量/幂等、鹅马自然演出、真实声音/后台和长时性能验证。本轮关卡阻塞基于这些覆盖缺口及已知构图问题，不能说B复现音频P1。新B主要涉及main提示纸排版等变更，已补启动/旧手账/安全回院基础检查，完整影响回归仍不足。

## 原始证据

截图原样保存，01/02是实际加载壳，03是标题，不混用。05仅选中绵羊（尚无成功互动）；07含轻抚反馈。13为回院场景，不单独证明持久化确认。14为收杆窗口，不是钓鱼成功。17为草料在手，不是投喂完成。18-20只证明桌面视口模拟。23/24为B旧相册读取。日志为空只能证明捕获范围内无warn/error。

![01-loading](evidence/01-loading.png)

![02-load-stall](evidence/02-load-stall.png)

![03-title-retry](evidence/03-title-retry.png)

![04-yard](evidence/04-yard.png)

![05-sheep-greeting](evidence/05-sheep-greeting.png)

![06-cloudy](evidence/06-cloudy.png)

![07-sheep-pet](evidence/07-sheep-pet.png)

![08-old-album](evidence/08-old-album.png)

![09-album-end](evidence/09-album-end.png)

![10-exploration-entry](evidence/10-exploration-entry.png)

![11-feather-discovered](evidence/11-feather-discovered.png)

![12-feather-taken](evidence/12-feather-taken.png)

![13-return](evidence/13-return.png)

![14-fish-bite](evidence/14-fish-bite.png)

![15-volume-single-track](evidence/15-volume-single-track.png)

![16-total-mute](evidence/16-total-mute.png)

![17-grass-held](evidence/17-grass-held.png)

![18-portrait-pause](evidence/18-portrait-pause.png)

![19-portrait-album](evidence/19-portrait-album.png)

![20-landscape-album](evidence/20-landscape-album.png)

![21-second-trip-empty](evidence/21-second-trip-empty.png)

![22-cross-version-recovery](evidence/22-cross-version-recovery.png)

![23-album-restored-new](evidence/23-album-restored-new.png)

![24-restored-end](evidence/24-restored-end.png)

报告PR保持待独立最终SHA审核，不自行合入或发布。
