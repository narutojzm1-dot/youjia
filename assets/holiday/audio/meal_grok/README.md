# GROK #745 餐食音效叶子

原创软音色，供 `scripts/presentation/meal_audio.gd` 使用。禁止复制 Minecraft / 塞尔达等外部素材。

| 文件 | 语义 | 说明 |
| --- | --- | --- |
| `cook_loop.tres` | 关门做饭时的轻柔锅内咕嘟循环 | AudioStreamWAV，loop_forward |
| `cook_spoon.tres` | 少量锅勺动作短音 | 一次性短音，经 AudioDirector `meal.spoon` |
| `hunger.tres` | 漏餐饥饿短声 | 一次性短音，经 AudioDirector `meal.hunger`。2026-10-12 R3 再返修 |

制作：程序合成（软咕嘟 + 木勺轻点 + 饥饿短声），源在本目录，无第三方采样。

## 2026-10-12 饥饿第 13 条 R3（参考真实肚子咕噜后再合成）

用户再听 R2（`e87ebdbb…`）仍认为「肚子咕噜声不对」，要求先参考真实肚子咕噜（borborygmi）再返修。R2 未获批准，继续禁播。

声学参考（只作合成目标，**未采样**任何外部录音）：
- 真实肠鸣是气液在软腔里的不规则湿咕噜，不是干净正弦气泡
- 可辨识能量多在约 100–500 Hz 的湿腔突发，带向下滑的共鸣；不是几乎全在 80 Hz 以下的闷垫

本 R3：约 0.92 秒；轻腹垫 + **四声错落的湿腔咕噜**（噪声经腔体整形，共鸣向下滑），无尖锐点击。uid 不变。`cook_loop` / `cook_spoon` 字节锁定未改。
