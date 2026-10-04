# 阴天返修预览 v4（候选，未接入）

- 基线：PR #202 `a347079320a504c59ac6308575184ccae473204a`，PNG SHA-256 `535bee93428cb1167a867541c1cc883fbe6b5e1a083a928037d5a07168ad5b06`
- 否决的 v3：`8661350bcfca6cac4c66cae123cbb71b385503bc`，PNG SHA-256 `9c11e73c65a4a46247cb11d7f3afa21d83d5a131baf2a59566befa7954e5db19`，ART-DIRECTOR 5983393849
- 本候选：`art/concepts/yard_overcast_aligned_v4/yard_overcast_aligned.png`
- PNG SHA-256：`fcc5e6497021c89be9913df99b6d0762d8e834580bf0137398f05c9acbf86f95`
- 左参照为晴天母版 `yard_sunny.png`（SHA-256 `7f29181eac79c89b18eff65fe1a18c37230573b55f8c8993a0365dc480219d73`）
- `side-by-side.jpg`：左晴天、右 v4（各缩到 960×540）
- `overlay50.jpg`：晴天与 v4 50% 叠图，用于看几何是否双影
- `yard-1280.jpg`：候选 1280×720 预览
- `crops/*-v1-v4.jpg`：四区 100% 原尺寸成对裁切，左 v1、右 v4。池心框已改为实际水面 `[650,790,1560,1020]`，不再使用落在草坪上的 `[780,560,1160,770]`
- 不是 Web 连续切换，不是接入，不是发布通过。
