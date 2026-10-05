# 探索「发现与获得」短展示：首片帧证据（CURSOR-CLOUD，#153 / #155）

契约：[exploration-find-reveal.md](../../architecture/exploration-find-reveal.md)。来源：用户经 GAME-PRODUCER 转达的 [#155 5993470040](https://github.com/narutojzm1-dot/youjia/issues/155#issuecomment-5993470040)。

## 怎么截的

真实近郊画卷 `near_path_scroll.gd` 与 `ExplorationHost`，用内存存档替身（不写真实存档）。在溪声停留点停下看、带上圆石，然后按固定时刻截帧；低动效另截一组。使用真实渲染器，在 Xvfb 下运行：

```
YOUJIA_CAPTURE_DIR=<dir> godot --path . --resolution 1280x720 --script tools/capture_find_reveal.gd
YOUJIA_CAPTURE_DIR=<dir> godot --path . --resolution 390x844  --script tools/capture_find_reveal.gd
```

每帧的位置、大小、透明度见 `land-capture-log.txt` / `port-capture-log.txt`。

## 帧

| 时刻 | 1280×720 | 390×844 |
|---|---|---|
| 停下看（展示前） | `land-motion-00-look.webp` | `port-motion-00-look.webp` |
| 0.18 s 升起中 | `land-motion-02-t0.18.webp` | `port-motion-02-t0.18.webp` |
| 0.80 s 停留展示 | `land-motion-04-t0.80.webp` | `port-motion-04-t0.80.webp` |
| 1.50 s 飞向提篮 | `land-motion-06-t1.50.webp` | `port-motion-06-t1.50.webp` |
| 低动效 0.40 s / 0.80 s | `land-calm-02/03-*.webp` | `port-calm-02/03-*.webp` |

看到的效果：

- 停留时物件和光晕都在人物头顶上方，不压人物头部和身体；名字行在物件上方，不压字幕，也不压底栏按钮。
- 竖屏下展示位置跟着人物，横向居中，左右都没有越出画面。
- 篮子里的文字在核心接受时就已更新，展示只是画面。
- 低动效下物件在同一位置淡入淡出，不位移、不缩放。

## 隔离测试

`test/exploration_slice_suite.gd` 的 `_find_reveal()` 在 1280×720 与 390×844 下覆盖：带上和换物各触发一次；放回、停下看、篮满、重复输入不触发；展示期间走动、暂停、接着走、回院都会立即收尾，篮子与存档不变；低动效没有位移；缺少音频资源时安静降级、不顶替其他声音。全量 `EXPLORATION SLICE PASS 180/180`（每次运行都用全新的 `XDG_DATA_HOME`）。

## 还没有的

- 没有声音：`assets/audio/sfx/exploration_find_get.ogg` 未交付，日志里 `sound file present false`。原创短音与独立物件贴图按契约 §4 由 GAME-PRODUCER 交付，到位后补 Web 实玩与听感。
- 物件还是 `KeepsakeArt` 代码占位画法。
- 时长、位置、大小都是候选值，等用户看过首片演示再定。
- 不是 #150 / #176 的 Web 持久化验收，也不是手机真机验收。
