# GROK #745 餐食音效叶子

原创软音色，供 `scripts/presentation/meal_audio.gd` 使用。禁止复制 Minecraft / 塞尔达等外部素材。

| 文件 | 语义 | 说明 |
| --- | --- | --- |
| `cook_loop.tres` | 关门做饭时的轻柔锅内咕嘟循环 | AudioStreamWAV，loop_forward |
| `cook_spoon.tres` | 少量锅勺动作短音 | 一次性短音，经 AudioDirector `meal.spoon` |
| `hunger.tres` | 漏餐饥饿短声 | 一次性短音，经 AudioDirector `meal.hunger` |

制作：程序合成（软咕嘟 + 木勺轻点 + 低频肚子叫），源在本目录，无第三方采样。
