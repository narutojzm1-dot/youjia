# 水塘故事原画与 F1 接入

Owner：CODEX-LEAD；来源：用户本会话的 beibei 找乌龟、鸡龟友谊和鹅龟争执故事；关联 #503 / #504。2026-10-07 使用内置 image_gen 制作，保留未经裁切、重绘或背景处理的原始透明输出。提示词与 SHA256 / 尺寸 / alpha 外框见同目录文件及 manifest.json。

| 文件 | 原始输出 | 状态 |
| --- | --- | --- |
| turtle-v1.png | exec-d9979276-0703-479a-b16b-96cfc0eec312.png | 历史候选：壳偏高、腿偏粗，陆龟观感过重，不选用 |
| turtle-v2.png | exec-c59269ae-4dc8-4d62-9876-76eede6a83df.png | 参考 v1 编辑：降低壳背，展开较细的水栖脚；当前水塘龟候选，不指定科学物种 |
| chick-v1.png | exec-be765b8b-9c65-4559-9473-46bc80ab0e79.png | 淡黄绒羽、尖喙、分离细趾；避免与院内鸭子混淆 |
| hen-v1.png | exec-6d41c379-ba81-4613-add2-e04daffffc6e.png | 参考雏鸡编辑为同一个体成年母鸡：体态、羽层、鸡冠变化，不是放大幼体 |
| beibei-search-v1.png | exec-14c8e040-1db5-40ab-a824-485824dd19a7.png | 以 E 已接入成年犬为参考编辑，低头探查、近侧前爪轻抬；完整四肢姿势，尚待探索动作接入 |

## 实际尺寸检查

`tools/capture_pond_candidates.gd` 在真实 Godot 小院背景放置完整画作：乌龟宽 90、成年鸡高 56、雏鸡高 25 世界像素。原生 OpenGL 1280×720 截图与日志证明这三张图可在玩家尺度下区分；这只是受控原画比例检查，画面中的水边落点不代表已完成水线遮罩或行为接入。

原生截图本机路径：`C:/Users/Zengm/.codex/visualizations/2026/10/07/pond-candidates/pond-candidates-1280.jpeg`。运行日志：临时目录 `youjia-pond-art-b0880767-4455-40d2-a046-f2a0d6a46a4f`。

补入 beibei 探查姿势后再跑原生比例检查：使用与成年犬相同的 72/1089 像素缩放和地面锚点，不把低头图拉高。新截图 `native-scale-1280.jpeg` 与 `native-scale.log` 存在本目录，执行目录 `youjia-pond-art-9656b650-6750-4b43-8f2a-e749800e0f70` 无引擎错误。

## 下一步边界

先交付成年 beibei 在村边水岸发现乌龟、带回水塘和重开保留身份，再接小鸡与小米、成长、鸡龟同行和鹅龟偶遇。居民身份沿用已交付的持久化队列；动物不是可复制的物品堆叠。水塘故事不得覆盖 beibei 已有档案，也不得占用另一只同行动物的控制权。

F1 本地候选已接入成年 beibei 探查、确认后显示乌龟、接回水塘岸边及居民存档迁移。运行时 `assets/holiday/characters/pond/turtle.png` 与 turtle-v2、`assets/holiday/characters/beibei/search.png` 与 beibei-search-v1 字节一致，完整画作直接使用；以运行时岸边截图为准，不沿用上面的早期浮水比例检查作为玩法证据。

小鸡/成年鸡仍只是后续资源。水中游动遮挡、喂小米、鸡成长或动物关系行为尚未交付；这些原画不是整个 F 已完成的证据。骑乘及拒绝等动作应另有合适完整姿势或清楚的自然动作设计，不拉伸静态原画充当动作。
