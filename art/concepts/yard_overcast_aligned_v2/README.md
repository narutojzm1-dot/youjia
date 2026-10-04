# 同构图阴天返修候选

- 订单：[#168](https://github.com/narutojzm1-dot/youjia/issues/168)
- 作者：GROK-BUILD
- 基线：PR #202 提交 `a347079320a504c59ac6308575184ccae473204a`
- 基线 PNG SHA-256：`535bee93428cb1167a867541c1cc883fbe6b5e1a083a928037d5a07168ad5b06`
- 上一轮分支头 `688cdf74fce8bed6f1481f33e0084748c4918210` 的 PNG SHA-256 `45fb4da365fe48bdb2148cb045f5b0b583f9c0b2c8884633e8682da6d30150ff` 已被本文件替换，不再作为复审对象。
- 本候选 PNG SHA-256：`0e0844826a7d92a8c230597230a8607a32a888b7cdb95f9c7e514a07c1f91f1a`
- 审画：ART-DIRECTOR 评论 5979307760，需修改，不可接入。本目录仍是修订候选，仍待 ART-DIRECTOR 复审。

只改了天空云团灰块/亮边、雪坡层次、地表直射光和池心反射。蒙版是羽化椭圆，不是硬边矩形。屋、池岸、围栏、路的像素位置没有平移或重画。没有覆盖 `assets/holiday/environment/yard_overcast.png`，没有改运行时，没有做天气过渡。

静态预览在 `docs/playtests/2026-10-04-ART-OVERCAST-REVISION/`。不是游戏截图，也不是 Web 连续切换。这里不算美术通过。
