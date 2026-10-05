# 拾起短展示 + 制作人候选资源：首片演示帧（CURSOR-CLOUD，#153 / #155，Draft）

在 [拾起短展示程序切片](../2026-10-05-exploration-find-reveal/README.md) 上接入 GAME-PRODUCER 的候选松果（PR #361）、落羽（PR #364）和原创短音（PR #359）。资源只供演示，来源 SHA 与处理方式见 `assets/holiday/exploration/README.md`、`assets/holiday/audio/README.md`。截帧方式与上一份相同（`tools/capture_find_reveal.gd`，真实渲染器，Xvfb，内存存档替身）；这次另外按停留点找出会遇到松果和落羽的种子。

## 帧

| 内容 | 1280×720 | 390×844 |
|---|---|---|
| 停在松果处 | `land-pine-00-look.webp` | `port-pine-00-look.webp` |
| 松果停留展示 0.80 s | `land-pine-04-t0.80.webp` | `port-pine-04-t0.80.webp` |
| 松果飞向提篮 1.50 s | `land-pine-06-t1.50.webp` | `port-pine-06-t1.50.webp` |
| 停在落羽处 | `land-feather-00-look.webp` | `port-feather-00-look.webp` |
| 落羽停留展示 0.80 s | `land-feather-04-t0.80.webp` | `port-feather-04-t0.80.webp` |
| 圆石（仍为占位画法）0.80 s | `land-motion-04-t0.80.webp` | `port-motion-04-t0.80.webp` |

看到的效果：

- 展示时松果和落羽都认得出来。展示垫在带淡墨边的圆形纸片上；只有半透明亮光晕时，白色落羽会被冲淡，所以改成了纸片。名字在纸色小标签上，压在繁复原画上也能读。
- 停留时纸片和标签在人物头顶上方，不压人物，也不压字幕和底栏。
- 路边的落羽仍然几乎看不见（`land-feather-00-look`），与制作人在 #155 的判断一致。这一版不放大路边物件，先靠停下看时的字幕和拾起展示；路边尺寸要等制作人给出同深度尺寸再校准。
- 提篮里松果能认出，落羽偏淡。

## 声音

`exploration_find_get.ogg` 能加载，拾起成功时播放一次（隔离测试 `the delivered get sound loads and plays once`）。暂停时立即停止，恢复后不补播；走动或接着走时让它放完。这里没有人工听验：电平按原稿未改，峰值约 −22 dBFS，偏轻，需要和环境音乐一起实际试听。

## 测试与回归

`EXPLORATION SLICE PASS 185/185`；`bash tools/verify_daily_life.sh` 全量通过（每次都用全新的 `XDG_DATA_HOME`）。

## 边界

- 在 GAME-PRODUCER 标记候选可进运行时、或用户看过后决定之前，Draft 不合入。
- 圆石候选 PR #285 仍带宽柔影、未通过审查，没有接入。
- 原画里画着的松果和落羽还没清底，路边会出现“画里一个、程序一个”的情况。
- 不是 Web 实玩、手机真机或 #150 / #176 验收。
