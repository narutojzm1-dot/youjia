# GROK #745 餐食音效叶子

原创软音色，供 `scripts/presentation/meal_audio.gd` 使用。禁止复制 Minecraft / 塞尔达等外部素材。

| 文件 | 语义 | 说明 |
| --- | --- | --- |
| `cook_loop.tres` | 关门做饭时的轻柔锅内咕嘟循环 | AudioStreamWAV，loop_forward |
| `cook_spoon.tres` | 少量锅勺动作短音 | 一次性短音，经 AudioDirector `meal.spoon` |
| `hunger.tres` | 漏餐饥饿短声 | 一次性短音，经 AudioDirector `meal.hunger`。2026-10-12 只重做这一条 |

制作：程序合成（软咕嘟 + 木勺轻点 + 饥饿短声），源在本目录，无第三方采样。

2026-10-12 饥饿第 13 条返修：旧 `hunger.tres` 能量几乎全在 80 Hz 以下，听感是闷响，不像肚子饿。新资源仍是 `hunger.tres`（uid 不变），约 0.64 秒，软起软收。低频蠕动垫底，两声空腔气泡向下滑（约 440→130 Hz，再约 300→90 Hz）。没有尖锐瞬态，不是外部采样。`cook_loop.tres` 与 `cook_spoon.tres` 未改。
