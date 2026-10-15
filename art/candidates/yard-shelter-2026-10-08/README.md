# 棚门候选，尚未接入

Owner: CODEX-LEAD；来源：用户 #565 的牛羊居棚、开门放出、夜晚归棚要求。

内置 imagegen，编辑目标 `assets/holiday/environment/yard_sunny.png`。原图1920×1080，输出1672×941；不得全图替换正式底板。

- `gate-open-v1.png`：尝试门扇向棚内打开。门洞/门柱对齐未验收，不用于生产。
- `gate-clean-v2.png`：去掉门扇，补其后的草地。需要局部配准、晴阴接缝与独立门扇；不等同门已经能开。

完整提示（v1）：

> Use case: precise-object-edit. Asset type: pixel-aligned open-gate state for a 2D watercolor game environment. Edit target is the provided 1920x1080 sunny courtyard painting. Change ONLY the small X-braced wooden livestock gate in the right foreground pen (roughly x1330–1405 y665–747). Swing this gate inward into the pen to leave a clearly open passage; paint the grass/earth previously hidden by the closed gate. Keep both gate posts and all surrounding fence rails EXACTLY in their existing positions. The same gate is visible swung inward at a convincing perspective, hinges fixed to its original post. Preserve every other part of the original painting, its canvas size, camera perspective, watercolor grain, warm daylight, colors, house, mountains, trees, shed, pond, and every fence line outside the gate. No people, animals, text or UI. No redesign, reframing, camera shift, global relighting or changes elsewhere. This is an aligned alternate state, not a new scene.

完整提示（v2）：

> Precise-object-edit for game asset. Output must be 1920x1080, same framing as this image. Edit ONLY the X-braced gate between the two posts in the right-hand pen, centered around original image pixel (1360,700). Remove that gate leaf entirely, paint only the few pixels of grass and earth that were hidden behind it. Keep BOTH posts completely unchanged in their exact original locations (left near1325, right near1408) and every fence rail outside this small gap unchanged. This is a gate-leaf-removed clean plate, no new gate elsewhere, no moved posts, no larger entrance. Preserve the original image outside this small object exactly including color, sunlight, fine watercolor texture, all buildings mountains and pond. No additional objects, text, people or animals; no global repaint or resizing.

接续必须完成：门口专用连通路径、栏杆前景遮挡、牛羊棚内位置、开门放出/夜归优先级、草食与牵引互斥、持久化失败/重开恢复，以及晴阴/昼夜/窄屏真实游戏验证。当前 FENCE_GATE 仍只是草叶反馈；禁止以旧 pen_and_lawn 多边形直接扩大草坪冒充归棚。

## v3 独立门扇候选（2026-10-08 13时）

`gate-leaf-v3.png` 为内置 imagegen 参考同一 sunny 原画输出的透明独立门扇，原样复制；尚未配准、验收或接入。输出的宽窄比例及门框竖木需要与原画门柱核对，不能仅有透明背景便宣称可用。

完整提示：

> Use case: background-extraction / precise-object-edit. Edit target: supplied watercolor courtyard. Extract ONLY the small X-braced wooden livestock gate LEAF visible in the right pen at original image x1338..1404, y655..747. Make a standalone game sprite on genuinely transparent background. Preserve its exact narrow trapezoidal frontal perspective, aged brown wood grain, simple rectangular frame and diagonal X brace, original watercolor brushwork and lighting. Exclude both fixed gate posts, all fixed fence rails, grass, landscape and cast background; transparent holes between its wooden planks. Center this one gate leaf with a small transparent margin, enlarged enough to preserve fine painted wood detail. The silhouette and perspective must match that exact gate, not a new design. No arch, handle ornament, text or extra object. This is the closed leaf that will later rotate about the left hinge in a 2D scene; do not draw an open gate or change the viewpoint.
