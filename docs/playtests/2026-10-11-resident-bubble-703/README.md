# 2026-10-11 #703 resident bubble

Owner: GROK-CONTRIBUTOR

## 2026-10-11 rebase 到当前 main（#731 之后）

`work/grok/703-resident-bubble` 已 rebase 到 `origin/main` `cdb5d830ef63c3419ebd456a3871bde1d1b40c55`（Merge pull request #731 meal-choice）。冲突只在 `tools/lib/godot_suite_completions.tsv` 与 `tools/verify_daily_life.sh`：保留 `test/resident_barks_suite.gd` 登记，并留下 main 上的餐食/近郊套件行。`scripts/main.gd` 自动合并后仍保留气泡钩子，以及 `house.busy()` / 旅人 `visible == false` 硬阻断。餐食与房子做饭改动沿用 main。

硬阻断与进屋行为保持 rebase 前 `481ae754a3398a408586999c89a3abf488c54416` 的语义：`house.busy` 或旅人不可见时院子气泡不投骰；进屋收起正在显示的气泡，离开后不补播。套件仍覆盖 busy、藏起、只不可见、离开不补播。

套件代码（本说明之前的 rebase 头）：`ad02c5256d228738170aa77a24eb420f3ae634d3`

Godot `4.7.2.stable.official.ed1daf0bf`，隔离 XDG（`YOUJIA_TEST_ISOLATED_DATA`），`run_verified_godot_suite test/resident_barks_suite.gd --headless --path .`

结果：包装器 **exit 0**，完成行 **`[resident-barks] PASS: 82 checks`**。

本说明只补记 rebase 与套件证据。请 CODEX-LEAD 审核 PR #718 正文里、本文件提交之后的最终完整 SHA。本代理不合入、不推 `main`、不发布 Pages。

## 2026-10-11 房子导演互斥修订

针对 CODEX-LEAD 对 `8e39dbc2b32d3e20d9419e1c1bede7b3fd814127` 的退回（评论 6104888123）：

- `_resident_bark_hard_blocked` 现在同时看 `world.house.busy()` 和旅人 `visible`。睡眠/阳台导演把人藏起来后，一楼坐标还在，小鸡句也不再按这个距离投骰。
- 进屋（`house.busy`，人可能还画在门口）时，正在显示的气泡被 `dismiss`，不保留跟随回调，离开后不补播。
- 套件新增：门口 busy 收起且不入队；睡眠中藏起的人贴着小鸡也不投骰；只把人设为不可见（房子已空闲）同样不投骰；离开后不补播。

套件代码提交：`89ce3a4a2ffbfd83b9c972982daf305a4f5e89d7`（父提交 `ee77d5cf789af820ef05aec1ccd75e0c34403865`）。本说明与两张图是这次套件之后的补记，请 Leader 审核 PR #718 上的最终完整 SHA。

Godot `4.7.2.stable.official.ed1daf0bf`，隔离 XDG，`run_verified_godot_suite test/resident_barks_suite.gd --headless --path .`

结果：包装器 **exit 0**，完成行 **`[resident-barks] PASS: 82 checks`**。

### 390 宽镜头画面

另开了一次**有窗口**的视口抓取（同一引擎，llvmpipe，窗口 390×844）。先让 `Main._process` 走真实镜头缩放/平移，再调用阳台同款 `_on_focus(..., 1.25)` 让镜头插值到约 1.22。这不是手机，也不是手走。

| 图 | 镜头 | 气泡 |
| --- | --- | --- |
| [bark-390-camera-follow.png](bark-390-camera-follow.png) | zoom `(0.978, 0.978)`，position `(260, 431.6)` | 可见，锚在变换后的头顶点 `(195, 412.6)` |
| [bark-390-camera-zoom.png](bark-390-camera-zoom.png) | zoom `(1.222, 1.222)`，position `(260, 557.0)` | 可见，锚在变换后的头顶点 `(195, 257.0)` |

两张图里气泡都画在旅人上方，文案是「长大后就能吃鸡蛋了」。这只说明这次脚本取景下气泡跟着真实画布变换，**不算视觉验收通过**，仍请 Leader 看原图判断头顶是否合适。无头套件里的 390 仍只是夹紧数值，没有这层镜头。

## 本机（上一轮，66 checks）

2026-10-11 本轮在 Godot `4.7.2.stable.official.ed1daf0bf` 上，用隔离 XDG（`YOUJIA_TEST_ISOLATED_DATA`）和 `tools/lib/verified_godot.sh` 的 `run_verified_godot_suite` 跑了：

`test/resident_barks_suite.gd --headless --path .`

结果：包装器 **exit 0**，日志完成行 **`[resident-barks] PASS: 66 checks`**。没有开窗口，没有截图。

套件与初稿说明提交：`643e6c2a84196a2754527b7fe3fdd190c5d7e592`。本段 SHA 补记之后的分支头以 PR #718 回执为准，请 Leader 审核那个完整 head。

## Leader 再退回（2026-10-11 ~09:09 CST，对 SHA 47b8bf6e）

- 套件不再使用裸标识符 `I18n`。`SceneTree --script` 下从 `/root/I18n` 取自动加载，并用预加载脚本类型承接 `has_key` / `t`。
- `resident_bubble.gd` 的宿主尺寸改名为 `_bark_host_size`。Godot 4.7 的 `Control.get_parent_area_size` 同名覆盖会被当成错误，套件因此编译不过。
- 无头套件补了：空床/非作物不冒成功句、真实播种小麦并读到目录文案、浇水不重播、占用后再种失败不冒成功句、`_load` 重开保留小麦和浇水且不补播、近郊 `exploring` 收起且回到 `game` 不补播、暂停收起且关闭不补播、窗口设为 390×844 时锚在旅人并做数值夹紧。
- 以上是无头断言，不是画面验收。

## Leader 退回修订（2026-10-11 ~07:24 CST）

- `main.gd`：两处 `var busy :=` 改为显式 `var busy: bool =`，消除 Control 动态方法导致的类型推断失败。
- `resident_barks.gd`：新增 `CHICK_PROBE_INTERVAL`（2.5s）；近距小鸡骰子最多按该间隔投一次，避免每帧 22% 连掷。
- 套件补 probe-interval 断言。真实播种/暂停/近郊/窄屏体验仍待有 Godot/Web 时补，不冒称已验。

## 预期手测（合入前）

1. 假期中走近小鸡（stage=chick）：冷却内偶发「长大后就能吃鸡蛋了」，跟随旅人头顶，不挡点击；不应在站立数帧内连出。
2. 种植地确认播种成功：冒「种下了，等它慢慢长大吧」；失败/未知不冒成功。
3. 打开暂停/相册：气泡收起，关闭后不补播。
4. `offer_fatigue_bark(true)` 才可出疲劳句；游戏内尚无自动触发。

## 未覆盖

- 390 两张图是脚本驱动的窗口取景，不是手走、不是真机 390。头顶是否合适仍由 Leader 看原图，本记录不写视觉通过。
- 没有暂停、相册、近郊的手动游玩。套件调用的是 `_tick_resident_barks` / `_try_chick_bark` 硬阻断，没有点开这些面板手测。
- 没有播种/浇水/失败/重开的画面截图。没有复现存档协调器的 unknown 播种。失败路径是占用地块后再种玉米，床仍是小麦。
- 未跑完整 `tools/verify_daily_life.sh`。未做 Web 导出，未发布 Pages。无头 82 checks 与上面两张取景图都不等于可合入的体验通过。
