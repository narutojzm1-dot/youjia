# 草泥马翻找姿态候选

Owner CODEX-LEAD，#503 D 隐藏发现。2026-10-07 使用内置 imagegen 编辑既有 `assets/holiday/characters/cast_v2/llama_smirk.png`，生成单张透明完整姿态；原站姿保留。候选 `llama-search-v1.png` 已看图：四脚、卷毛与角色面貌保留，鼻子下降到地面，图像未裁脚。尚未完成同尺度叠图、脚点/绳端标定、实际场景接入与回归，不能称为已上线。

## Exact prompt

Edit target: the supplied existing game llama painting. Create ONE whole-body alternate animation cel of precisely this same cream and warm golden curly-fleece llama, same mature body proportions, same cheeky face identity, same painterly gouache/watercolor rendering and warm lighting. It is gently lowering its long neck and nose to sniff and nudge fallen leaves on the ground in front of its front hooves (leaves themselves must NOT be painted; render only the animal). Keep the body, four planted hooves, rump and tail the same size and orientation as the reference, rump left and head toward right, three-quarter side view. Bend the neck naturally forward/down from shoulders so the curious muzzle is near hoof ground level, ears upright, relaxed eyes, mouth closed. Not a baby, not a sheep, not a squashed/scaled whole body. Maintain all four clear separated feet and a stable horizontal ground baseline. Whole figure fully visible with generous transparent margins, no crop, no ground/shadow/rope/objects/text/grid. A single animal on genuinely transparent alpha background. Preserve organic curly fur edges; no white halo. Intended as an alternative whole-painted cel, not a sprite sheet.

透明度检查：主轮廓 alpha>8 边界为 (66,207)-(1238,1081)，极低 alpha 毛边延伸到画布底部；后续锚点不可直接使用所有非零 alpha 的边界。原字节保留，未处理或批准运行时尺度。

2026-10-07 接入进展：完整原字节接入 assets/holiday/characters/cast_v2/llama_search.png；按背部至蹄底和蹄距而非头顶高度使用0.91比例、(475,1063)脚点与(837,737)低头绳端。已核对生产场景原生画面、普通Web翻找显现及79→92项回归；当前仍为待最终PR/公开核验的运行时候选。原站姿未替换。
