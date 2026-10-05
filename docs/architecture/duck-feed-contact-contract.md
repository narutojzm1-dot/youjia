# 成功投鱼：嘴前相遇公共表现契约（研究接线边界）

CODEX-LEAD承接 #122 comment5997679517，回应Producer5994489875。选择已授权成功投鱼的**嘴前相遇**，不要求候选继续低头到地面，不增加落地鱼/拾取/奖励规则。状态为可复用模型与真实标定已交，尚未生产接入。

## 身份与变换

资源369 ecfd97a2aaeed1aa4c73455db80526595834180c，1254画布喙(1110,807)、地锚(590,1177)，来源hash见证据。候选不是已上线attend，不替换CastArt注册。

`tools/duck_feed_contact/contact_model.gd.pixel_world(sprite,pixel)` 先依Sprite flip翻图坐标，应用offset/centered，再经实际Sprite完整世界变换；当前生产鸭通过actor负scale镜像，纵深/父变换均保留。现工具仅完整纹理Sprite，不声称支持region/atlas多帧裁片。鱼图未来必须定义自己的接触像素锚，令其世界点与嘴点相等，不能只让两个sprite中心靠近。脚锚不移动、原画比例不调整、喂食距离不扩大。报告世界坐标和viewport.canvas_transform后的屏幕坐标。

## 短时序与取消

从既有YardWorld成功分支时刻开始，业务立即按原规则消耗鱼/发事件；视觉可拒绝或取消，绝不决定消费是否成功。0–0.2秒安定朝向；0.2–0.5秒工程低弧到嘴；0.5–0.7秒嘴前静态接触；0.7–2.2秒可接原关注收尾，鱼画面消失。弧高min(4世界像素,距离×0.08)，只用于克制的短轨迹，非鸭缩放。低动效0.2–0.7秒仅静态接触，不走轨迹。不要求额外咀嚼帧。

模型必须由每个recipient长期持有，不能每次成功new实例绕过间隔；to_global仅世界变换，不含Camera投影，screen需另外应用实际canvas/viewport变换。region/hframes/vframes裁片不在本工具支持范围。

5秒视觉间隔内新的业务成功照常消耗，不能续期或抢旧视觉。移动、posed演出或exit取消画面且保留间隔，结束/大delta不残留。模型advance必须由未来调用者喂真实foot/posed/attached；模型不持有业务状态、不读存档、不发成功事件。现模型只是建议接线可复用实现，不代表生产已有完整取消绑定。

## 可复用入口与未完成

`FeltActor.acknowledge_feed`保留原2.2秒/5秒；`YardWorld` toss_fish成功分支仍唯一决定消费。未来接线由Leader在资源合规后承接，不碰Main/Host/Cloud/input。Producer继续369逐脚/左右连续切换：数学脚锚一致不表示脚轮廓一致。无正式鱼sprite，当前小点/十字只工程诊断；来源点尚未证明为生产人物手部，需未来真实取点。照片应捕捉实际画面而非编造已咀嚼，真实Web/低动效入口/手机/包体验未交。

证据：[受控原生院景与29+24检查](../playtests/2026-10-05-duck-feed-contact/README.md)。不关闭30/122，不称新增玩法或已上线。
