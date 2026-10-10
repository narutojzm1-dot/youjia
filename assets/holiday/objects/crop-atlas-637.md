# #637 作物原画来源

## 原始完整提示词

### Wheat

Use case: illustration-story. Asset type: one transparent 2D watercolor game sprite atlas for a wheat crop in a finely painted alpine cottage game. Entire atlas 1536 wide by 1024 high, three isolated related states arranged in three equal vertical columns on real transparent alpha, large generous separation, no text or borders: left a small rooted green wheat seedling with 5 narrow leaves; middle a mature compact clump of 5 golden wheat stems and unmistakable full wheat ears, showing entire plant and stem bases; right a small naturally scattered handful of beige elongated wheat grains (not millet, not rice), about 20 grains. Soft hand-painted watercolor/gouache botanical detail, warm muted ochre and sage palette, natural diffuse daylight, grounded slightly elevated three-quarter view. All subjects completely within their columns with margin. No soil patch, no backdrop, no cast shadow outside each small subject, no pot, no frame, no labels, no 3D render, no pixel art. Preserve attractive readable shapes at small in-game sizes. These are stages and harvest grains of the SAME wheat plant, not separate unrelated assets.

### Corn

Use case: illustration-story. Asset type: one transparent 2D watercolor game sprite atlas for maize / sweet corn in a finely painted alpine cottage game. Entire atlas 1536 wide by 1024 high, three isolated related states arranged in three equal vertical columns on real transparent alpha, generous separation, no text or borders: left a small rooted young corn seedling with 3 broad green leaves, fully visible including stem base; middle one compact mature corn plant with broad green leaves, one recognizable partly peeled golden corn ear attached at middle height and a small tassel, entire plant fully visible; right a small naturally scattered handful of about 18 golden yellow corn kernels, recognizably plump irregular maize seeds, not millet, not rice. Soft detailed hand-painted watercolor/gouache botanical style, warm muted golden ochre and sage green, natural diffuse daylight, slightly elevated three-quarter view. Each subject confined to its own third of the atlas with margins, no overlaps between thirds. Transparent backdrop with no soil, pot, horizon, labels, borders or cast shadows outside subject. No 3D render, no pixel art. Attractive readable silhouettes at tiny in-game size. These are stages and harvested kernels of the SAME maize plant.


CODEX-LEAD，2026-10-10，内置imagegen，transparent_background=true，非CLI。两张PNG均1536×1024 RGBA，直接复制生成原件，未脚本重绘、抠图或改alpha。runtime AtlasTexture仅采样各状态/地上苗叶，等比缩放；原图非显示RGB中可见的光晕大部分alpha为0，实际背篓验证以最终合成效果为准。麦苗45世界像素、成熟麦68、玉米苗45、成熟玉米88；根部不画在土上。青草复用既有GrassArt。

wheat: exec-26de8a7b-8cff-4bc6-8d28-304dc4497e28.png; SHA256 60cb7f663558c0cfc58a098c5395a03e05cb8f97def7c1b2eebf922b445c6a4e

corn: exec-fa60cb11-1164-4baf-81ff-c17034c0b80a.png; SHA256 ae696018ad34444508312596fec59013e0d71751ec0e416e1a892b821986b42e
