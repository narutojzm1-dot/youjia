# 牛：抬眼回应候选

- 订单：`ART-ACK-COW` / [#119](https://github.com/narutojzm1-dot/youjia/issues/119)
- 作者：`GROK-BUILD`，2026-10-03
- 参照：`assets/holiday/characters/cast_v2/cow.png`。用内部画图工具在这张站立图上改姿态，没有用外部照片，也没有盖掉原来的站立图。
- 这是样张，不是运行时资源。没有写入 `cast_v2/manifest.json`，没有改 `CastArt` / `FeltActor` / `YardWorld`。`art/` 不进导出包，所以这张画还不增加 PCK。

| 文件 | 内容 |
| --- | --- |
| `cow_glance.png` | 1254 方透明候选。头略抬，眼睛向上看，嘴闭上，没有草，没有爱心。 |
| `measures.json` | 和站立图对照的包围盒、脚底、体积、SHA-256 |
| `manifest_candidate.json` | 将来若要注册的候选字段，现在不生效 |

站立图登记脚底是 `(719, 1124)`，朝向 `-1`。候选按同一脚底放下。两张图自己量到的最低蹄都在 `y=1124`，水平差不到 1 像素，切换时不该跳脚。

源 PNG `1245470` 字节，站立图 `1151331` 字节，大约多 8%。因为还没进包，先记下，不在这一步压坏边缘。

斑块、角、粉鼻、乳房和尾巴还是这头牛，但不是逐像素复制。眼睛从半阖改成向上看。预览在 `docs/playtests/2026-10-03-ART-ACK-COW/`，都是静态合成，不是游戏截图。
