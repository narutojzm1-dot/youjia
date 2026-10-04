# B 方向首片分轨候选

- 订单：`AUDIO-B-ASSETS` / [#194](https://github.com/narutojzm1-dot/youjia/issues/194)
- 作者：`GROK-BUILD`，2026-10-04
- 候选，未接入。没有改 `AudioDirector`，没有进导出包。正式采样率、循环点和总线名字等 [#171](https://github.com/narutojzm1-dot/youjia/issues/171)。

[#170](https://github.com/narutojzm1-dot/youjia/issues/170) 的 78 秒 A/B 只是方向试听。用户选了 B。那一版不能当作循环成品，本目录不覆盖它。

| 文件 | 怎么用 | 时长 |
| --- | --- | --- |
| `bed_yard_env.ogg` | 环境循环。风、中高频空气、偶尔叶动。 | 128 秒，整段循环 |
| `bed_yard_music.ogg` | 轻音乐循环。和环境和在两条轨上，音量分开。 | 128 秒，整段循环 |
| `preview_mix.ogg` | 合成预览。音乐文件再衰减 5 dB，没有再压限。这不是锁定音量。 | 128 秒，可循环 |
| `preview_seam.ogg` | 只用来听接缝。前 8 秒是循环末尾，后 8 秒是循环开头，接缝在 8.0 秒。不要把这个文件自己循环。 | 16 秒，一次播放 |

两条分轨都是 48000 Hz、立体声、Ogg Vorbis。峰值约 -3.0 / -2.4 dBFS，没有削波样本。体积和 SHA-256 见 `SOURCES.md`，测量见 `levels.json`。

不在这里：脚步、动物叫、抚摸声、快门。那些另开单。

制作环境没有扬声器。接缝只做了样本跳变和短时响度比较，不能写成听感通过。方向仍要制作人听，长时间听验是 #196。
