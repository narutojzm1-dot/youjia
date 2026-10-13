# #642 小院三处花草分层返修候选

Owner: CODEX-LEAD；分支 `codex/lead-flower-beds-642`。**仅本地资源/合成候选，未接入游戏、未发布、未完成花圃玩法。**

采用内置 imagegen（非CLI）：background-extraction生成真alpha三组花草图集；precise-object-edit分别补绘三处晴天去花区域；lighting-weather对每块晴天结果按原阴天局部参考补绘对应阴天版。没有覆盖原背景和旧照片纹理，未增加花种ID、刷新率或花区容量。后续还需原画接缝/残留、逐区移除/重种、保存恢复/旧照片兼容及近郊采花接口验收。

资源：

- `yard_flower_groups_v1.png`：2048×768 RGBA，三组原场景花草；左/门左/池塘左依次排开。alpha=0的像素682524/1572864，周边采样为0，没有画入棋盘格。图集列并非严格等宽：预览暂用x0..750、750..1400、1400..2048分区，不能直接按三等分切割。
- `{left,door,pond}_clear_patch_v1.png`：晴天局部去花补绘。
- `{left,door,pond}_clear_patch_overcast_v1.png`：对应阴天局部补绘。
- `contact-preview.jpg`：RTX4070 Compatibility原生Canvas合成；左上原画、右上晴天清除、左下放回独立植物、右下阴天清除。椭圆遮罩/接缝仅预览参数，不是最终可交付玩法或正式照片冻结结果。
- `preview.gd`：复现原生合成的工具脚本，只在本地运行，Image.load_from_file不适用于导出，不能当正式接入。
- `manifest.json`：输入裁切范围、文件尺寸/哈希及生成提示集合。

局部输入来自原晴/阴图的原生Image.get_region，只截取参考、不重画：left Rect2i(0,590,270,340)、door Rect2i(250,590,120,115)、pond Rect2i(550,795,190,150)。所有坐标为1920×1080原图坐标，正式世界是1280×720，必须除1.5后接线。保留盆、石、路径和房屋，不把整个右下角或旧三个摆件点当花区。

第一次整图去花候选有叶片残留、局部位移，已淘汰。后续换成局部输入后得到本组候选，但未以“生成了PNG”冒称正式美术/运行验收通过。共享回院容量保护已独立PR696，不混入这条未完成资源线。


## Expanded left crop v2, 2026-10-10
Original 270x340 crop/mask left iris remnants. New 370x440 source crop at (0,570) generated as separate sunny/overcast candidates with built-in imagegen; original seven assets unchanged. See expanded-v2-manifest.json for hashes/provenance. preview-expanded-v2.gd uses full patch with 3px edge feather; it is a native Image.load_from_file preview, not export/runtime code. Sun/cloud full-context comparison remains pending edge/registration acceptance; no candidate is a published garden feature. Persistent original-layout/controller candidate is separately PR699.
