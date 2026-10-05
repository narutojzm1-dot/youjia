# 互动与动物动作资源制作订单

历史2026-10-03资源Owner为GROK-BUILD。当前2026-10-05用户通知其额度耗尽，预计10月9日恢复，未完绘画改交GPT制作人 **GAME-PRODUCER**（接收/串行首交待核），见[人员公告](../collaboration/personnel-availability.md)。ART专业审画、CODEX接口与集成协调保持。

## 现状和缺口

main71595d2：大鹅已有alert/calm/rest，羊驼已有idle/happy/annoyed/smirk；牛、马、双羊、鸭主要依赖站立画，缺少与成功互动相配的可见表情/姿态。旅人已有步态、拿草/递草，轻抚专用资源尚缺，issue84已有三姿态提案。静态符号不能替代动物本身的回应。

已有GROK-BUILD #117/PR118交付候选鸭理羽、马尾扬、牛嚼草、羊休息与路旁资源，尚未合入/验收；沿用当前工作，不开重复单。路旁交互规则按原PR审查，不因本次资源委派额外批准。PR99乘骑画归WORKBUDDY，不重新制作。羊驼优先用现有表情，确有缺口再列资源单，不为了凑数量再画一套。

## 制作顺序

全部订单已指定，排队状态不等于未认领；不让其他代理抢同一资源。先收尾PR118现有候选，并开始牛单的单张回应样张；牛的原尺寸/镜像/接触基准确认后依次展开马、双羊、鸭鹅。旅人可以先并行画三姿态分镜，样张核对后烘帧，不并行修改动物接入。

| 订单 | 内容 | 资源Owner | 接入/行为边界 |
| --- | --- | --- | --- |
| [ART-ACK-COW #119](https://github.com/narutojzm1-dot/youjia/issues/119) | 牛：成功互动后的抬眼与温和回应 | GAME-PRODUCER（GPT绘画接力，待回执） | MANUS / #30映射；不改REQ004/008父Owner |
| [ART-ACK-HORSE #120](https://github.com/narutojzm1-dot/youjia/issues/120) | 马：注意玩家与接受轻抚的回应 | GAME-PRODUCER（GPT绘画接力，待回执） | MANUS / #30映射；不改REQ004/008父Owner |
| [ART-ACK-SHEEP #121](https://github.com/narutojzm1-dot/youjia/issues/121) | 两只羊：保留个性的互动回应 | GAME-PRODUCER（GPT绘画接力，待回执） | MANUS / #30映射；不改REQ004/008父Owner |
| [ART-ACK-BIRDS #122](https://github.com/narutojzm1-dot/youjia/issues/122) | 鸭与鹅：自然关注和接食姿态资源 | GAME-PRODUCER（GPT绘画接力，待回执） | MANUS / #30映射；不改REQ004/008父Owner |
| [ART-RESIDENT-PET #123](https://github.com/narutojzm1-dot/youjia/issues/123) | 旅人：自然轻抚动作的三姿态样张 | GAME-PRODUCER（GPT绘画接力，待回执） | CODEX协调主角接入；#84提案样张优先 |

## 交付合同

1. 一单一PR；优先一张关键回应候选与现有idle对照，不先做大图集。资源按对应cast_v2现有画布/比例；旅人样张384×448、脚底(192,420)。新动作是完整同角色画作，不能靠压扁/拉伸、局部符号贴纸冒充。
2. 实测alpha bbox、接触锚点、朝向、手/喙接触点和每帧字节；同动作各帧切换不跳脚，不能复制猜测锚点。提供左右镜像及院子原尺寸预览；新源PNG优先不超过对应idle大小，超预算先说明，正式PCK净增量由实际接入导出测量。
3. 母版放art，候选运行图、manifest数据、制作方法/参考/授权来源与SHA256成套交付；注册CastArt/manifest前与活跃PR核对共享文件范围，由CODEX协调，不在资源单悄悄改行为状态机。
4. 当前绘画接力GAME-PRODUCER先提交实际样张，CODEX核对角色一致性、锚点、比例和预览；制作人核对具体新画/动作方向后扩帧。无需重新确认已经指定的Owner或停住盘点/候选制作，但尚未定义的玩法不可随资源单加入。
5. MANUS明确成功招呼/抚摸/投喂等现有路径如何使用画作；不同互动可信区分，只有实际接受互动的对象回应，失败/取消不庆祝。新画不承诺每次必播，不改距离或库存语义。
6. 低动效保留可读静态关键姿态；资源可被真实照片快照保存/回放，旧照不改写。资源预览明确标注静态合成，接入后的Godot/Web实际像素、切换/打断/失败和独立最终SHA审核另行完成。无运行时接入时不写已发布。

后续更复杂日常动作、关系行为资源先基于实际资源缺口开新单。关系模型、触发/节奏、照片CG和代码架构由CODEX把关；不把资源委派解释为接管全部动物玩法。
