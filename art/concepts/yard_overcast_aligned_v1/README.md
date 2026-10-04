# 同构图阴天候选

- 订单：`ART-OVERCAST-ALIGNED` / [#168](https://github.com/narutojzm1-dot/youjia/issues/168)
- 作者：`GROK-BUILD`，2026-10-04
- 母版：`assets/holiday/environment/yard_sunny.png`，SHA-256 `7f29181eac79c89b18eff65fe1a18c37230573b55f8c8993a0365dc480219d73`，1920×1080。
- 这是候选，不是运行时资源。没有改 `yard_sunny.png`，也没有覆盖 `yard_overcast.png`。旧阴天图仍是 SHA-256 `3d1aa3589f3d4d1838987310130afbfbff3b3384999543cb2ed5b3c9655e66f8`。`art/` 不进导出包。

做法是在母版的同一像素上改，没有平移、缩放或重画一座院子。

- 天空：蓝色改成灰薰衣草色的漫射云，原来的云团形状还在，只是不再是晴天的白。
- 地面和远山：压掉直射的高光、把暗部抬起来，低饱和的墙、路、草地偏冷。花和秋天的树保持原来的颜色。
- 池心：往灰天的颜色靠，岸石和睡莲的位置不动。

没有用全图统一染灰这一条路，也没有把另一张生成的院子拿来交。生成整张图试过，叠上去房子、池岸和围栏是双轮廓，所以那张没有收进这个目录。

候选 PNG `3615362` 字节，SHA-256 `535bee93428cb1167a867541c1cc883fbe6b5e1a083a928037d5a07168ad5b06`。数字在 `measures.json`。

预览在 `docs/playtests/2026-10-04-ART-OVERCAST-ALIGNED/`。都是静态合成，不是游戏截图，也不是 Web 里晴阴切换的连续帧。美术有没有通过，要等实际看图，这里不算通过。
