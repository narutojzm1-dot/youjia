# 同构图阴天返修候选 v4

仍待 ART-DIRECTOR 复审。不可接入。

基线是 PR #202 提交 `a347079320a504c59ac6308575184ccae473204a` 的
`art/concepts/yard_overcast_aligned_v1/yard_overcast_aligned.png`
（SHA-256 `535bee93428cb1167a867541c1cc883fbe6b5e1a083a928037d5a07168ad5b06`）。

ART-DIRECTOR 评论 5983393849 否决 v3 提交 `8661350bcfca6cac4c66cae123cbb71b385503bc`
（PNG SHA-256 `9c11e73c65a4a46247cb11d7f3afa21d83d5a131baf2a59566befa7954e5db19`）：云是浅色补丁、雪坡被抬平、院心仍有直射感、池心量测框坐标错误。

本版只返修这四处，屋、池岸、围栏、路、树干几何锁在 v1 像素上。
候选 PNG SHA-256 `fcc5e6497021c89be9913df99b6d0762d8e834580bf0137398f05c9acbf86f95`，1920×1080，3607076 字节。

不覆盖 `assets/holiday/environment/yard_overcast.png`，不改运行时，不做天气过渡。
