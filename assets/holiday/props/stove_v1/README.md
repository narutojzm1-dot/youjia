# 院内灶台阶段原画 v1（候选）

Owner CODEX-LEAD；#700 / REQ-20261013-700-STOVE。源为内置 image_gen，2026-10-16 生成；不含外部游戏素材。资源制作/候选接入不等于用户验收、最终演出验收或公开上线。

- `stove-stages-watercolor-v1.png`：2172×724 RGBA，1,591,450 字节；原始透明图直接复制，未裁切、缩放、去底或重绘。SHA256 `4ca746beec6d1ef0c73b6107592c20bcea0619348dd9d8a98c7f86a937b9f0f4`。
- 三个 724×724 等宽 atlas 区域：石基、砌体、炉面完成。原画三阶段不是三份物品，显示石块数不代表材料成本。
- 接入 `yard_stove_view.gd`；同一地面锚，单一 Sprite2D 切 AtlasTexture。阴天调色、昼夜、遮挡和普通 Web 连续施工须在实际候选核验；既有照片存下具体 atlas 区域，后续施工不改旧照片。
- 制作选择：三阶段，每阶段1圆石/1AP/1建筑经验、16秒生产。用于可读性迭代，不宣称用户逐项指定，也不继承池岸候选参数为产品定值；无新菜谱/增益。

## 生成提示词（完整）

Use case: illustration-story. Asset type: a SINGLE transparent game sprite atlas for a tiny outdoor courtyard stone cooking stove in a hand-painted watercolor Alpine cottage game. Primary request: three construction stages of the EXACT SAME small rustic single-burner masonry stove, arranged in three equal horizontal cells in ONE wide image, left to right: (1) shallow oval foundation stones / low first course with empty center; (2) waist-low unfinished stone body with clearly visible dark arched firebox opening, open unfinished top; (3) completed same stone body with a simple dark iron cooking plate and one round burner opening on top and a short unobtrusive rear flue. No pot, food, fire, smoke or characters. Same isometric-ish 3/4 front camera at a slight downward 20-degree angle, firebox faces front slightly right. All 3 stages have exactly the SAME foundation width, footprint, centerline, ground baseline and perspective; later stages grow upward only. Composition: wide 3:1 canvas, EXACTLY 3 evenly spaced equal cells, one object fully inside each cell; generous fully transparent 8% margins, objects grounded at same baseline near 85% canvas height; no object spills between cells. Style: exquisite quiet European countryside picture-book watercolor, natural ochre/grey fieldstones, softened irregular ink edges, delicate visible granulation, subdued warm ivory mortar and soft cool-gray metal, painterly convincing volumes, not cartoon outlines, not 3D render. Match afternoon warm diffuse daylight upper-left, light contact shadow directly beneath each base, no large cast shadow. Background: actual alpha transparency, NOT white paper or checkerboard. Text: none, no labels, no borders, no decorations, no watermark. It must read as successive construction of ONE useful cooking stove even when each frame is displayed 80 pixels wide. Do not make 3 different designs, do not add huge chimneys, tools, soil squares, grass or stray detached stones.

工具：内置 image_gen，transparent_background=true；原输出 `exec-cad9d8d9-500e-4bd7-8bea-1acfb1d66eda.png`。非 CLI，原文件保留。
