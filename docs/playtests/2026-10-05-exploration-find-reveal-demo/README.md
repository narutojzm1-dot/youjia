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

## 动态音画录制

制作人要求先动态同看（[#155 5994990147](https://github.com/narutojzm1-dot/youjia/issues/155#issuecomment-5994990147)），所以用 `tools/record_find_reveal_demo.gd` 加 Godot Movie Maker 录了画面和混音。场景是真实画卷与宿主（内存存档替身），院景音乐和环境声照常播放，与正式游戏外出时一致。路线：从出门处沿路走到坡路草边（slope），停下看，带上松果（11.83 s）；再走到树荫（shade），带上落羽（21.47 s），往回走。全长约 28 秒，1280×720 与 390×844 各一条，放在本目录 `videos/` 下：`find-reveal-demo-1280x720.mp4`、`find-reveal-demo-390x844.mp4`，以及短音 +12 dB 的对照 `*-get-plus12db.mp4`。

```
godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie out.avi --script tools/record_find_reveal_demo.gd
```

Movie Maker 会按项目的窗口尺寸覆盖（1280×720）录制，不认 `--resolution`。竖屏那条是在项目根目录临时放一个 `override.cfg`，把 `display/window/size/*` 设成 390×844 录的，录完已删除。

**电平实测**：用 `YOUJIA_DEMO_SILENT=1` 再录一条不放拾起短音的，两条逐样本相减，就是短音在混音里的实际贡献（相减后其余时段为零，说明录制是确定的）：

| 时刻 | 拾起短音（每 0.1 s RMS） | 同时刻音乐+环境声 |
|---|---|---|
| 松果 11.8–12.1 s | −33 到 −36 dB | −20 到 −22 dB |
| 落羽 21.5–21.7 s | −32 到 −35 dB | −19 到 −20 dB |

短音比背景低 13–15 dB，很可能被音乐和环境声盖住。电平归 GAME-PRODUCER 定，运行时默认不改。为了方便对照，另录了一组 `YOUJIA_DEMO_GET_DB=12`（只在这次录制里把短音播放增益提高 12 dB）。

画面：独立视频审阅确认两条视频的顺序和时刻都对：物件正确，篮子文字依次更新为「松果」「松果、落羽」，没有闪烁或跳变，走路贴着路面、没有滑步或瞬移，底栏按钮始终没被遮住。它还说“纸片盖住人物”，逐帧复核（`port` 11.85–13.5 s）后这一说法不成立：停留阶段纸片在人物头顶上方，只在升起的约 0.15 秒里、以及落羽飞向提篮时，会短暂经过人物上方。制作人说的“展示纸片视觉较强”要动态看过再定。

## 按制作人抽检返修（v2）

[GAME-PRODUCER-REVIEW-PINECONE](https://github.com/narutojzm1-dot/youjia/pull/375) 看过 `10c4de1` 的两帧后，提了两条：

- 展示纸片改为稍深、低饱和的暖灰，减少背景纹理对白羽的干扰；
- 竖屏的篮子名称加一块稳定的小底板。

这一版两条都已做，人物脚点和尺度不动。

- **展示纸片：** 改为暖灰 `FindReveal.DISC`（0.76, 0.72, 0.66），不透明度从 0.82 提到 0.94。路面纹理基本透不上来，白羽和浅松果都比浅奶色底时更清楚。墨边和名字标签不变。
- **篮子名称：** 文字后面加了一块纸色小底板。底板每帧都画，宽度跟着文字走，横竖屏都有，空篮时同样有。竖屏原先“落羽”两字压在草和石头上，现在能读清。

同一工具、同一种子重截的帧（只截与返修相关的 0.80 s 停留帧）：

| 内容 | 1280×720 | 390×844 |
|---|---|---|
| 落羽 0.80 s | `v2-land-feather-04-t0.80.webp` | `v2-port-feather-04-t0.80.webp` |
| 松果 0.80 s | `v2-land-pine-04-t0.80.webp` | `v2-port-pine-04-t0.80.webp` |
| 圆石（占位）0.80 s | `v2-land-motion-04-t0.80.webp` | `v2-port-motion-04-t0.80.webp` |
| 低动效 0.80 s | `v2-land-calm-03-t0.80.webp` | `v2-port-calm-03-t0.80.webp` |

上面的旧帧和 `videos/` 下不带 v2 的视频都是改前版本，保留作对照。

v2 合入 main `089d453` 后重录了动态演示，背景已换成制作人清底的近郊图（PR #393 / #410）：

- `videos/find-reveal-demo-v2-1280x720.mp4`（SHA256 `a3802e5bf034071094c5dcc3ad4ee3e679646901f17a9f51dee5b1bb98334b2e`）
- `videos/find-reveal-demo-v2-390x844.mp4`（SHA256 `17dbfc42d40256938795d1a98986eb8dfe807c63a47467d3ab337eca6beaba0b`）

路线、种子和时刻与 v1 相同：11.83 s 带上松果，21.47 s 带上落羽，全长 27.83 s。两条都是 H.264 + AAC 128k，短音电平未改，这次没有另录 +12 dB 对照。

隔离测试新增 6 项（横竖屏各 3 项）：篮子名称的底板包住文字；底板不出屏；展示纸片的颜色是低饱和、偏暖、比原来深。

## 测试与回归

`EXPLORATION SLICE PASS 227/227`（v2 合入 main 后；合入前 191/191，改前 185/185）；`bash tools/verify_daily_life.sh` 全量通过（每次都用全新的 `XDG_DATA_HOME`）。

## 边界

- 在 GAME-PRODUCER 标记候选可进运行时、或用户看过后决定之前，Draft 不合入。
- 圆石候选 PR #285 仍带宽柔影、未通过审查，没有接入。
- v1 帧和视频里，原画画着的松果和落羽还没清底，路边会出现“画里一个、程序一个”的情况。v2 视频用的是 main 上的清底图，这个问题已经没有了。
- 不是 Web 实玩、手机真机或 #150 / #176 验收。
