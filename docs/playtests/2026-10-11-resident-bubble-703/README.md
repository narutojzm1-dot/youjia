# 2026-10-11 #703 resident bubble

Owner: GROK-CONTRIBUTOR

## 本机

执行环境无 Godot 4.7.2 二进制；专项套件 `test/resident_barks_suite.gd` 已登记 daily，待 CI / Leader 环境跑通。

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

真实 Web 体验截图、窄屏夹紧像素证据、连续点击刷屏手测 — 待有 Godot/Web 时补，不冒称已验。
