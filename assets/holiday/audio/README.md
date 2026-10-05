# 院景首片音频

`bed_yard_*` 两条是 [#194](https://github.com/narutojzm1-dot/youjia/issues/194) 的候选分轨，给 [#195](https://github.com/narutojzm1-dot/youjia/issues/195) 播放。听验还没过，不是定稿，也不是已经听感通过。

| 文件 | 用途 | SHA-256 |
| --- | --- | --- |
| `bed_yard_env.ogg` | 环境循环 | `239efcb8235acb56e12450c2e40e409336c1c139403a07ee8b4803f621bde241` |
| `bed_yard_music.ogg` | 轻音乐循环 | `2a01d83a2c6dfb14181dfd6a53b9c249591e18ad03f57e8f70f6a9ba57afd86c` |
| `exploration_find_get.ogg` | 探索拾起成功的短音（[#155](https://github.com/narutojzm1-dot/youjia/issues/155)） | `126c91b6a0f0ed96adf85ad2f7d1457f5475ce2d47aefad60f799257aa0b7bdd` |

这两条的来源说明在 `art/concepts/audio_b_stems_v1/SOURCES.md`。没有脚步、动物叫或快门。

`exploration_find_get.ogg` 来自 GAME-PRODUCER [PR #359](https://github.com/narutojzm1-dot/youjia/pull/359) `0e07ef5eabcd5766726d1c9d95904b1ad8ef54e3` 的 `art/concepts/producer_discovery_audio_v1/discovery_soft.wav`（SHA256 `14d19c82019fe48ee7fa9b2d843e8bfc69fe155c59ef736e255ac40e8975aea3`，程序原创合成，0.95 秒单声道 48 kHz）。只做 Vorbis 转码（`ffmpeg -c:a libvorbis -q:a 6`），没有改电平：峰值约 −22 dBFS，偏轻，未听验，只供首片演示。
