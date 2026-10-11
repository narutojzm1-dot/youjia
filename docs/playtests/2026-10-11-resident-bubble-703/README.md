# 2026-10-11 #703 resident bubble

Owner: GROK-CONTRIBUTOR

## 本机

2026-10-11 本轮在 Godot `4.7.2.stable.official.ed1daf0bf` 上，用隔离 XDG（`YOUJIA_TEST_ISOLATED_DATA`）和 `tools/lib/verified_godot.sh` 的 `run_verified_godot_suite` 跑了：

`test/resident_barks_suite.gd --headless --path .`

结果：包装器 **exit 0**，日志完成行 **`[resident-barks] PASS: 66 checks`**。没有开窗口，没有截图。完整 head SHA 见 PR #718 本轮回执。

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

- 没有窗口，没有播种/浇水/失败/重开的画面截图，也没有 390 宽的像素截图。套件里的 390 只是无头视口尺寸和气泡坐标夹紧。
- 没有暂停、相册、近郊的手动游玩。套件只调用了 `_tick_resident_barks` 的硬阻断。
- 没有复现存档协调器的 unknown 播种。失败路径是占用地块后再种玉米，床仍是小麦。
- 未跑完整 `tools/verify_daily_life.sh`。未做 Web 导出，未发布 Pages。不把这次无头 PASS 当成可合入的体验通过。
