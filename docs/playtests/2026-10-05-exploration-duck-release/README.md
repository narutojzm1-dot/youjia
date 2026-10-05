# 2026-10-05 探索首片、鸭关注与标题可读性发布验收

Owner CODEX-LEAD。CURSOR-CLOUD 独立完成探索实现/最终子代理审查并自行合入，Leader做后置接口审读、公开包校验与独立浏览器体验，不给Cloud增加前置批准。鸭关注由Leader内部实施助手完成，另独立终审。本文不是23:00日版本节点。

## 已核公开构建

| 构建/源SHA | Verify / Pages | 实际下载PCK | 范围 |
| --- | --- | --- | --- |
| game-81d225c / 81d225c15962a32d7a48a066154859488a155aa4 | 37296164897 / 37296675566 均success | 22,056,868bytes / SHA256 810d07f8ca0f910981e85161496728431653659994fddd17b0f1a124d2f3f6a3 | PR322探索首片及异步存档，横卷占位表现 |
| game-bc213f9 / bc213f9bea231ac01149d9c818d3fa149de83944 | 37297148195 / 37297539150 均success | 24,490,020bytes / SHA256 f0cd64865c4f857a486e15eb81aaa0200f17003a2fe7b8206e331be644afa731 | PR342保留原画视角、沿候选道路行走 |
| game-a936bea / a936bea68bfb37eea47b00c09e3767af74c72b61 | 37298031520 / 37298563842 均success | 25,260,420bytes / SHA256 fa4c431edaa836886f770949f3280d65491a287ee7689b5fd8f8c01231cf0991 | PR353成功投鸭关注及移除默认爱心，包含原画探索 |

每个public-release JSON为实际读取的公开manifest、HTML入口、下载PCK与gh-pages raw逐字节比较，以及十个版本化JS保存模块与manifest/源码比较；不是只检查Actions状态。独审作者head分别为PR322 7e4b46b59014989b804f5b4cc273501a6eabb831、PR342 678aa4089f60d7fdf932c8a9600883272fea01d1；原作者reviewer记录见PR。

## 自然体验与状态界限

- 严格版本证据用 `painted/`：每次新页面记录并核HTML/manifest，全部实际为game-bc213f9。1280正常标题→院左下路口→点击原画道路→溪声近处停看→随机圆石→带上→暂停/Escape→回院确认→真实page.close/newpage。携物阶段keepsakes为空，收到持久确认后圆石1、水位1、session=null；重开仍圆石1。
- 390与844旋转验证沿路输入、停看、拾物及布局。第一窄屏重开探针因context默认仍1280、点击用了390坐标而停标题，12帧不是恢复成功；原图/JSON/驱动保留，summary明确失败。
- 有效窄屏中断恢复证据在 `painted/narrow-final/`：独立默认390context，正常出门与自然拾圆石，外出携物时真正关页，新页再次核同一bc213f9后正常入院，圆石1、水位1、session清空。root及执行助手亲看关键原图，未注入种子、玩家坐标、携物或业务状态；IDB仅readonly观察。
- `scroll-initial/`保留最初过渡画卷材料。只有首页面绑定81d225c，重开未逐页采集build，恰逢342部署，所以不能将恢复全部归因于81单一版本。该路径的恢复JSON与空手另趟不增加物品是实际观察，但严格当前生产版本结论以上述painted为准。源driver保持原样，限制不隐去。
- 两套驱动均退出0，实际pageerrors为空；未采集console事件的运行不称console全零。Chromium软件渲染的宽窄视口不是手机真机或真实听觉验收。随机圆石恢复已验，落羽只实际拾取未完成该趟有效恢复；不据此声称三种物品、容量3/换物、配额/unknown/abort、双页并发和旧档迁移全覆盖。

后置存档审读确认：带回物、已提交水位与记录同一candidate；队首以当前confirmed水位去重；Host只消费自身op_id；unknown保留pending不重复授予；返回标题先探索收尾再flush。静态审读无有据P1，不能代替上述实际Web，也不关闭#150/#305全部组合范围。

## 美术和剩余Owner

原画视角和沿路行走已实际可玩；底图烘焙松果/落羽未清底、前景遮挡/独立物件未交，比例与停点仍候选参数。Producer负责资源，Cloud继续表现/页间玩法，不将公开发布冒成美术全部验收。照片短横屏#350及暂停提示遮挡#348归Assistant，未回执的下一项不能说已开工；阴天#168/#51仍缺合格底板，音频339仍缺真实听验/接线。腾讯云#198继续用户延期。

历史研究单#199按原作者5976320468交付申请及PR204最终c086b76独审/154项独立复跑验收结项；只完成隔离研究，高DPR限制仍#156。#200原型已交但hold→resize→return与close失败文案两条后置风险保留，见200#issuecomment-5992744128，不把正式探索上线直接替代遗留处置。

## 鸭关注正式发布

PR353最终c0b02dc660c795c8911c2f1f7fdeb906df7b4e9b由独立CODEX-LEAD-REVIEW-DUCK-ATTENTION批准，合a936bea。生产完整Actions门禁/导出和Pages均成功，公开包检查见pr353-public-release.json。真实公开Chromium151先严格核HTML/manifest完整source，正常标题、岸边钓获、Space投鱼给小鸭三、打开首次钓获照片：三张accepted原图由root和执行助手亲看，无默认heart；pageerrors与consoleerrors为空。没有线上observer、没有写入游戏位置/种子/状态；最初IPv6网络失败排除，连续Space后续帧不冒本次成功链。

成功后的实际纹理、2.2秒时窗、脚点不跳与宽窄屏绑定此前由只读候选observer和24项专项独立验明，见[实现验收](../duck-feed-attention.md)；公开截图不单独冒内部字段证据。原图来自Producer343 v2不重画，5秒是视觉间隔不吞合法鱼消费，鹅不改。#30和#122保留其余资源/互动，不因鸭关注完成就关闭全部。

## 标题纸片公开收尾（PR354）

GROK-CONTRIBUTOR原实现07f836a9d5b706dc3f7ca40d0b1ab00ea07efa99，Leader按作者请求补daily入口/REQ028与组合DPR证据；最终09ff44bece2c80abe7119411dd2645926422dff4经独立CODEX-LEAD-REVIEW-PR-354 APPROVE后合7c1608c7e826f458eaae979d48727b0e6e2bdf58。Actions37299200195、Pages37299735394均success。

实际公开game-7c1608c的PCK 25,261,236bytes，SHA256 ba8819c853ec0c0ec7c7bb6b19fabecfb9cc32f4930ecce27825bd4309689df7；HTML入口、10个存档模块与manifest/源码/gh-pages raw一致，见pr354-public-release.json。该构建包含前述探索与鸭关注，但前述各自体验仍归其实际测试SHA，不冒在本次标题测试中重做全部玩法。

`title-public/`四组844×390/390×844 × DPR2/3逐页核对HTML与manifest完整7c1608c，正常标题→真实鼠标点击入院，无游戏状态注入。八张标题/入院原图由执行助手逐张看，root另核横竖标题图；文字清晰、纸片不截断且入院后消失，page/console errors均空。首次独立APIRequestContext访问的IPv6网络失败发生于游戏交互前，改为页面同网络fetch采manifest后的完整四组才计通过；不是物理手机或所有合成像素WCAG验证。与#350相册/348暂停遮挡无替代关系，Assistant原范围保持。
