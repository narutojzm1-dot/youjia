# 自主园艺首片原画

Owner：CODEX-LEAD。2026-10-17 使用内置 image_gen（imagegen 技能）新生成的透明 PNG，未替换既有原花草。单张2172×724图集等宽三格：野花种荚、播种后的幼苗小畦、同一小畦开花。运行时使用 AtlasTexture 区域，不拉伸或程序重画花朵；阴天/昼夜沿院景环境色，照片冻结格号和色彩。

首片仅一个固定花畦，位置、1份花种/1AP/1园艺XP/12秒工序、三天后开花及坡地发现权重1均为制作人可调参数，非用户逐项指定。它不开放新花种目录、插花或自由摆放，不转换原三组花草，也不改近郊八格农田。

原始生成提示词（内置工具；透明背景参数 true）：

> Use case: illustration-story. Asset type: one game sprite atlas, transparent RGBA, for a cozy hand-painted Chinese countryside picture-book game, viewed from slightly above at 3/4 perspective. Make a single horizontal atlas of exactly THREE equally sized square cells. Each cell isolated with wide transparent padding; no labels or text. Cell 1: a tiny natural brown opened seedpod with a few small dark flower seeds, lying on the ground, clearly readable as found wildflower seeds (not a commercial packet). Cell 2: small freshly planted oval earth patch with a few tiny green shoots. Cell 3: SAME oval earth patch in same position and perspective, grown into a modest compact cluster of cream and muted blush wildflowers, green leaves, about 5 simple small blossoms. Warm watercolor paper grain inside the painted subjects, soft uneven edges, earthy natural palette, delicate dark fine brush marks, no thick black outlines, no shiny game UI, no border, no text, no background, no hard rectangular shadow or white matte, no glowing outline. Keep earth patch low profile, shallow ellipse, same width in cell 2 and 3, plausible contact shading inside patch. Every subject wholly inside its own cell, no overlaps between cells. One horizontal production-ready game atlas, three cells; alpha truly transparent.

源图保存于本目录 `flower-garden-atlas-v1.png`；最终像素以该文件哈希为准。资源完成、运行接入、公开发布各阶段分别回原PR记录，未回复预览不等于用户验收。
