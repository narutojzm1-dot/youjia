# 马与草泥马卧姿候选（#565）

Owner CODEX-LEAD，2026-10-08。等待雨天 PR603 的正式发布流水线期间准备；这两张不是已接入资产，不代表马/草泥马已经避雨。原文件完整保留，不覆盖现有角色。

内置 image_gen，透明输出；输入分别为现有 cast_v2/horse.png 与 cast_v2/llama_idle.png，已先查看原画。视觉核对保留马的栗色、长鬃与额头白斑，草泥马的金色卷毛、粉耳和脸。1254×1254 RGBA；低透明像素扩展至图边，接地/缩放不能直接把非零alpha包围盒当作实形，需要实际运行适配后验收。

| 文件 | SHA256 | alpha≥8 的可见边界 |
| --- | --- | --- |
| horse-rest-v1.png | 6685572f196a0716ecc8d55ae34ce17a350bfe3acfa97c4d59f858f6f3bbe151 | 47,180 → 1243,1097 |
| llama-rest-v1.png | c1ad20592dd3e68f9193b8510a42399310475aac7c0a180cb68208cdf6a3214f | 75,39 → 1173,1222 |

后续由同一Owner完成适用的解剖/尺寸检查、接地锚点、棚内位置/路径、牵绳优先级和天气转晴恢复、照片及存档兼容、普通体验。不得把透明噪点直接扩大角色比例，不把候选准备当完整交付。当前没有为资源调整代码或创建另一个在途功能分支。

## 实际生成提示

Horse: Use case: identity-preserve. Asset type: transparent 2D game animal rest sprite. Edit target: the existing chestnut horse illustration provided. Create exactly this same horse peacefully lying down in a natural sternal resting posture, belly and folded legs resting on an invisible level ground, neck upright but relaxed, head facing left in the same three-quarter view, gently closed sleepy eyes. Preserve the chestnut coat, small irregular white forehead star, gray muzzle, long dark brown wavy mane and tail, friendly original proportions and detailed hand-painted textured brushwork. Leg anatomy must be plausible with four legs folded, no standing legs, no extra limbs. Full body and all mane/tail inside frame, generous transparent margin. No scenery, straw, floor, shadow, props, text, borders, or watermark. Real alpha transparency. This is a pose change for the same game character, not a new horse or a 3D render.

Llama: Use case: identity-preserve. Asset type: transparent 2D game animal rest sprite. Edit target: existing golden cream curly wool llama illustration provided. Create exactly this same character peacefully resting in a natural camelid kush posture: belly on invisible flat ground, all four legs neatly tucked beneath its body, tall neck relaxed and upright, head facing right in the same three-quarter view, eyes gently closed. Preserve the warm golden cream wool curls, pink inner tall ears, pink cheeks and nose, dark brown hooves, playful original face and detailed soft hand-painted textured brushwork. Natural camelid folded anatomy; no standing legs, no extra limbs. Entire body ears and tail inside frame with clear transparent margins. No scenery, straw, floor, shadow, props, text or watermark. Actual alpha transparency, a posture variant of the same game character, not a different animal or a 3D render.
