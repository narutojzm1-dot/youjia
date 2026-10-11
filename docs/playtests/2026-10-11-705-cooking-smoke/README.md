# #705 做饭烟囱叶子：屋顶上能看见的一缕（GROK-CONTRIBUTOR）

这是组件演示，不是主流程做饭。没有挂 Main，没有餐食导演事件，没有成长、睡眠或存档改动。下面的画面只说明隔离场景里烟囱叶子在院子原画上的样子。**不能写成观感通过**，也不能代替 CODEX-LEAD 看这些帧之后的结论。

证据、套件与画面提交：`3b2ac3ed8cd6631981053507435e9340880cbecd`。其后若只有一笔把该 SHA 写入本文的提交，审核 head 以 PR #723 评论中的最终完整 SHA 为准。

## 这次改了什么

- 烟比上一版更看得清：暖灰更深、软圆身体更大、大约每秒 5 缕，往天上走。寿命渐变仍从 0 起到末尾 alpha 0。
- 默认锚点改为 `Vector2(286, 122)`。这是 `yard_sunny.png`（1920×1080）缩到院子世界 1280×720 后，烟囱帽顶的位置。Leader 仍可用 `set_chimney_anchor` 覆盖。
- `set_cooking` / `set_paused` / `set_night_tint` / `ui.reduced_motion` 契约不变。重复 `set_cooking(true)` 仍是空操作，不重启、不增加节点。
- 隔离场景 `scenes/presentation/cooking_smoke_demo.tscn` 铺同一张晴天院子。N 只乘原画夜色并调用 `set_night_tint`。视口窄于 1280（含宽 390）时相机关在烟囱上。按键仍是 C 做饭、P 暂停、N 夜色、M 减少动态。

## 跑过的命令

Godot `4.7.2.stable.official.ed1daf0bf`。隔离数据目录与 `tools/verify_daily_life.sh` 相同。套件走 `run_verified_godot_suite`。导入在套件之前，导入 wrapper 退出码 0。没有重跑完整 `verify_daily_life.sh`。

```bash
export GODOT=/tmp/youjia-godot-472/Godot_v4.7.2-stable_linux.x86_64
state=$(mktemp -d /tmp/youjia-daily-check.XXXXXX)
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
source tools/lib/verified_godot.sh
run_verified_godot "$state/import.log" --headless --path . --editor --import --quit
run_verified_godot_suite "$state/run.log" test/cooking_smoke_suite.gd --headless --path .
```

套件日志 [suite.log](suite.log)：`[cooking-smoke] PASS: 38 checks`。日志里没有 `SCRIPT ERROR` / `ERROR:` / `FAIL`。38 项含软圆中心与四角、寿命渐变末尾 alpha、做饭中切夜色、减少动态时做饭标志保持、重复 `set_cooking(true)` 不增加节点，以及默认锚点落在屋顶带（y < 180，x 在 220 与 340 之间）。

画面用 Xvfb + `--rendering-driver opengl3`（llvmpipe），`--fixed-fps 20`，脚本 `tools/capture_cooking_smoke.gd`。时间轴：先空闲一帧，然后 `set_cooking(true)`，约 3.0 秒截做饭中，约 3.5 秒 `set_cooking(false)` 后再截，约 4.5 秒截淡出。1280 昼另存了 10fps、约 5.1 秒的 [day-1280-cook-cycle.mp4](day-1280-cook-cycle.mp4)（x264 crf 16）。这是组件演示的时钟，不是玩家做饭。

## 帧

| 文件 | 内容 |
| --- | --- |
| [day-1280-idle.png](day-1280-idle.png) | 1280×720 昼，尚未做饭 |
| [day-1280-cooking-3s.png](day-1280-cooking-3s.png) | 做饭约 3 秒 |
| [day-1280-stopped-3.5s.png](day-1280-stopped-3.5s.png) | 约 3.5 秒停发后的下一帧，缕还在 |
| [day-1280-fading-4.5s.png](day-1280-fading-4.5s.png) | 停发约 1 秒后，缕变淡 |
| [night-1280-cooking-3s.png](night-1280-cooking-3s.png) | 1280×720 夜色乘在原画上 |
| [night-1280-stopped-3.5s.png](night-1280-stopped-3.5s.png) | 夜色停发后的下一帧 |
| [day-390-cooking-3s.png](day-390-cooking-3s.png) | 宽 390、高 720 昼 |
| [day-390-stopped-3.5s.png](day-390-stopped-3.5s.png) | 同上，停发后 |
| [night-390-cooking-3s.png](night-390-cooking-3s.png) | 宽 390、高 720 夜 |
| [day-390x844-cooking-3s.png](day-390x844-cooking-3s.png) | 宽 390、高 844 昼 |

作者看过这些帧，并量了烟囱上方天空相对空闲帧的像素差（三通道绝对差之和）：1280 昼做饭约 3 秒，框 (240,20)–(360,130) 平均约 36、最大 259，约 4366/13200 像素差超过 12；同框 4.5 秒淡出平均约 19。屋身框 (180,220)–(420,420) 与空闲帧差为 0。390 宽昼天空框平均约 48（720 高）和约 43（844 高）。1280 夜同一天空框平均约 6.2、最大 129，约 2648 像素有差，对比弱于白天。mp4 解出的 3 秒帧与源 PNG 在同一天空框的差数量级一致（平均约 34）。这些数字只说明烟在烟囱上方、没有改屋身像素，不是观感通过。

## 仍要 Leader / QA 看的

- 真实做饭开始/结束事件仍未接入。本目录是组件演示。
- 夜色对比弱于白天。390 宽是隔离相机裁在烟囱上，不是 Main 的手机 HUD。
- 渲染是 llvmpipe，不是玩家显示器，也没有真机。
- 合入与 Pages 仍由 CODEX-LEAD 处理。Grok 不自行合入。
