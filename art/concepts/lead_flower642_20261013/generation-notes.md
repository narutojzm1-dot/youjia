# 原花圃净底返修候选（2026-10-13）

Owner：CODEX-LEAD，接续 #642 / PR699；使用内置 `image_gen`，未使用 CLI 或自建图像 API。此目录保留原始生成字节，**候选，尚未作为合格美术启用**。原作者候选 `ab97c0388c3cbed80c0cc683e66840410a7ce35a` 保留在祖先中。

输入：正式 `assets/holiday/environment/yard_sunny.png`、`yard_overcast_aligned.png`（1920×1080）及 #642 用户三框截图 `image-8.png`。截图只定义三处花组，不是允许改其他物件或底图的指示。晴天生成另参考本轮阴天净底的空盆位置，不采用其光照。

| 原始生成结果 | 本目录文件 | 实际尺寸 |
|---|---|---|
| `exec-54e48c0b-516b-40a9-911c-c8fc49cc5725.png` | `clean_overcast_v1.png` | 1672×941 |
| `exec-75f9057d-f750-4d26-809d-65a001d43232.png` | `clean_sunny_v1.png` | 1672×941 |

生成图不是精确像素保真全幅替换。只允许在三处互不覆盖的形状内按实际纹理尺寸采样；其余生产背景维持原字节，恢复时撤去补绘以露出原花。特别保留左路边未圈小盆、门盆盆壁、池石和其他岸边普通草。全部八种组合、晴阴过渡、照片与重开仍须实际检查。现已发现盆口/盆壁局部重描、晴天略偏黄、池盆背后残留长茎等问题，不能凭无明显方块就宣称验收通过。

## 阴天 v1 最终生成提示

```text
Use case: precise-object-edit. Project game texture repair. Image 1 is the exact edit target, the existing OVERCAST watercolor courtyard background at 1920x1080. Image 2 is ONLY a crop reference showing which three existing flower groups the user wants removable, with red boxes; do NOT reproduce any red boxes. Return ONE full-frame 1920x1080 (same composition/aspect/camera) overcast courtyard texture. Make only these three local removals: (A) lower left flower bed below the left window, approximately target pixels x0-250 y610-910: remove the tall pink and blue flowering plants and their leafy flower stems, reveal believable existing stone wall footing and matching ordinary green grass; preserve surrounding rocks and stepping stones, preserve the left tree and ivy higher on wall. (B) potted flowering plant immediately LEFT of the main door, x280-365 y610-691: remove ONLY its foliage and blossoms, keep the original empty terracotta pot, adjacent little pot, wall and doorway geometry exactly registered. (C) flowering plant on the foreground pond-side stone at x640-715 y830-935: remove ONLY its flowering leafy plant, keep the original empty terracotta pot and the same rocks/pond edge. Reconstruct underlying surfaces faithfully as if these exact original plants were gently lifted away. CRITICAL invariants: all pixels and objects outside these three areas should remain unchanged; do not reposition, change crop, restyle, resize architecture, rocks, path, pots, mountains, sky or any other plant. Keep the very same muted overcast lighting and local pigment colors and paper grain; DO NOT brighten, warm, desaturate globally, draw blue-gray rectangular blocks, add borders, blur seams, draw new flowers, or change any pot shape. Match each local wall/grass/stone to its immediately adjacent target pixels with invisible edges and no straight patch perimeter. This is a registered replacement texture for a game, not a new composition. No text, no characters, no red boxes.
```

## 晴天 v1 最终生成提示

```text
Use case precise-object-edit. Image 1 is the exact SUNNY courtyard edit target, originally1920x1080. Image2 only shows the three flower groups selected by user in red rectangles; do NOT draw these markings. Image3 is a reference for which plants are absent/which empty pots retained; DO NOT copy its overcast lighting. Output one full sunny 1920x1080 frame with same geometry/camera and the original SUNNY color and sunlight of image1, making ONLY three local plant removals. A: ground pink hydrangea-like flowers and tall blue iris-like flowers along the far lower-left cottage wall, x0–250 y610–910: remove these blooms, all their tall stems and flower-bed leaves, leaving original foundation, irregular small ordinary grass and rocks in exactly same positions; preserve left tree, higher ivy and window. B: flowering foliage in the large terracotta pot immediately left of main door, x280–365 y610–691: keep both existing empty clay pots, preserving size/shape/positions, remove just plant. C: flowering plant in the terracotta pot resting on foreground stone at left of pond, x640–715 y830–935: make this exact pot empty with visible dark soil rim, preserve all pot geometry, stones and pond-edge geometry; do not leave plant stalks behind/inside pot. Preserve every unrelated plant and flower including right side of door, window boxes, far right, and shore plants. Reconstruct only directly occluded wall/ground with matching adjacent original paint and grain. Crucial same composition and registration: no architecture edits, no crop changes, no new objects, no global color/contrast changes, no large rectangular retouching patches or edge seams; no artificial smooth fills or new little flowers. Keep unmodified areas from image1 unchanged. Clean three local areas only; no characters/text/watermarks/red boxes. This will be sampled as local patches to composite over original sunny scene.
```

提示词中的请求尺寸与实际返回尺寸不同，运行时以实际1672×941为准，不把文字请求当作文件规格。当前美术通过状态由原PR记录，未发送新美术完成邮件，也不将候选描述成已上线。

## 池边局部 v2

整幅阴天 R2 `exec-71d1c80e-c20f-4618-97cd-b977a19275a1.png` 仍留高茎；R3 `exec-3aa3a36d-6d59-49a4-b832-a88849dbf031.png` 留右侧斜茎并出现类似第二盆口的橙弧，均未采用。改为编辑 v1 的原像素局部裁剪，避免继续改变整幅画面。裁剪仅作为图像工具输入，没有程序补画。

晴阴各自原图均 1672×941，裁剪框 `(435,645,697,845)`，右下排除，输入 262×200；全图 UV 矩形为 `(0.26016746411483255, 0.6854410201912858, 0.15669856459330145, 0.21253985122210414)`。运行时只在池边原有形状中采用局部 UV 映射，左侧和门前两组仍用 v1，不更换正式底图。

| 原始结果 | 文件 |
|---|---|
| `exec-f63a05bd-a61b-487a-bee7-275ae20f4e8d.png` | `pond_overcast_v2.png` |
| `exec-efd142fd-66e7-465f-9310-0e49c70fef40.png` | `pond_sunny_v2.png` |

两张局部原始输出实际均为 **1435×1096**。阴天 SHA256 `72856c313891c1611e2f2d3c2c0c3a27740105620ea29b57a60a77f943bdc58f`，晴天 `b62f6da5db9cd1cd1440d418a7de6271d33df8ec68588375160b05bea2aeb455`；不能把262×200的输入尺寸误记成输出尺寸。

### 阴天局部完整提示

```text
Edit this small landscape game background crop. This is the empty state after the player removes the ENTIRE FLOWERING PLANT. Remove the whole large fan of long upright green stems and leaves behind and to the left and right of the central empty terracotta bowl, all the way down to the ground. Leave NO tall leaf, NO flower stalk, NO stems of that plant, NO new pot or orange arc behind the existing bowl. Replace the removed plant area with the existing short low grass, plain earth and unobstructed pale pond bank stones. Preserve exactly the composition and footprint of the ONE existing large empty terracotta bowl, including its wide rim, dark interior soil, round outer wall, position and size. Keep the existing large pale stone to its left, the stone supporting it, all pond rocks to its right, the sliver of pond water, and low ground grass outside the removed plant. This is overcast soft light watercolor artwork; retain its palette and paper texture. The crop must keep its exact framing and relative object positions, aspect ratio 262:200. Do not add any new object, flower, pot, high vegetation, wall or border. Output only the edited crop.
```

### 晴天局部完整提示

第二张参考图为刚生成的阴天空态，仅借其清除范围，保持首张晴天光照。

```text
Edit the FIRST sunny game background crop into the empty-plant state. The SECOND image is reference for what must be removed: it is the matching overcast empty state. Remove ALL the large upright fan of green stems and long leaves behind the central terracotta bowl, down to the ground. There should be no tall flower stalk or residual long plant leaves behind or beside the bowl. Use unobstructed low grass and earth behind it. Keep the FIRST image's bright golden sunny lighting and original color palette, crisp watercolor style, exact camera framing and all object geometry. Preserve the ONE existing empty terracotta bowl including rim/body/soil/size/position, the large rock on its left, the rock supporting it, pond bank stones to its right and water. Never add a second pot or orange arc behind the bowl. Do not reproduce the overcast tone of the second image; match the warm sunlight of the first. Keep all low ordinary grass outside the removed flowering clump. Same framing and aspect ratio 262:200. Output only the edited sunny crop, no labels or borders.
```

局部结果仍需 GPU 实景检查边缘、晴阴衔接、照片冻结后才能作为可用美术，生成成功不等于运行验收。

## 晴天局部 v3 低反差候选

局部 v2 放回场景后晴天过饱和、高反差，不能直接作为通过；运行材质降低饱和后的版本又显灰绿。另由内置图像工具制作低反差原始候选 `exec-7f2ae18f-44d3-4bb2-8a09-9045ad916dda.png`，保留几何和空态，以最初晴天原像素裁剪作颜色参考。纹理缩小采样须使用合适的 mipmap，不能将高分辨率生成纹理的采样闪点当成原画细节。

实际文件 1435×1096，SHA256 `903c618bbde7d7bb2e06b20d0ba761c2240551b3536f415e2498e5bbfede7fe4`。

```text
Color and texture match ONLY the FIRST crop to the SECOND low-contrast game watercolor reference. Preserve FIRST crop geometry and all object positions exactly, including ONE empty clay bowl and the clear grassy space behind it, and DO NOT restore any of the tall plants from image2. First image is far too saturated bright yellow and dark green with overly sharp black-green contrast and overly sharp paper flecks. Bring its whole pigment range down to the quiet, pale, muted grey-gold olive and beige, soft midtone contrast and gentle diffuse watercolor texture of image2. The surrounding game art is soft and delicate, not vivid or high contrast. Particularly the grass should have no vivid yellow, no deep green, and no very bright white grain highlights. Keep sunny lighting but softly washed and pale. Keep the terracotta bowl the same position and shape but less orange and less contrast, with soft natural edges. Preserve all rocks, pond stonework and water exactly; no new objects. Match image2 palette without copying its tall flower plant. Output only the updated crop with original framing, aspect ratio 262:200.
```

## 本轮静态检查结论

2026-10-13 CODEX-LEAD 实看 RTX4070 合成：最终选用左/门 `clean_*_v1`，池边 `pond_sunny_v3` / `pond_overcast_v2`；正确 mipmap 缩小采样后锐噪消失。随后把池边右上遮罩外扩到原图 `(730,790)→(742,847)→(747,869)`，原本漏出的蓝紫长茎已清除，保留白石、盆体及池后未选花丛。最终晴阴组合未见硬直边、空缝或明显盆岩位移；局部地面笔触仍略柔，是已知轻微差异。

这只允许进入普通场景运行验收，不表示已合入、公开发布或用户已验收。早期失败资源继续作为过程候选保留；运行版本不得回退使用高饱和 v2 晴天或整幅 R2/R3。保存、旧照片和真实 Web 操作证据见最终 PR，而非用本静态结论替代。
