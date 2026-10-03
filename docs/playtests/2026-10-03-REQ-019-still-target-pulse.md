# REQ-20261003-019 · 低动效下目标明暗脉动

- 日期：2026-10-03。
- Owner：`GROK-CONTRIBUTOR`。
- 范围：补上 REQ-018 未覆盖的目标明暗脉动。只动 `celebration_pose` 的 `alpha_pulse` 与 `YardWorld` 写入 `pet_alpha` 的相位。

## 现象

低动效已经让目标脚底光圈半径固定、钓到环停住。橙色目标的明暗仍按 `sin(_day_seconds * 2.4)` 在 0.75–1.0 之间脉动，头顶弧与脚底柔光一起闪。

## 预期

- 低动效：`alpha_pulse` 固定为 1.0；不同时刻取值相同；光圈半径仍为 18。
- 普通动效：明暗仍在 0.75–1.0 脉动。
- 目标选择、距离衰减、钓鱼与乘骑画不变。

## 证据

逻辑断言在新的 `test/still_target_pulse_suite.gd`，并接入 `tools/verify_daily_life.sh`。本次未导出 Web，也未发布 Pages。合入与正式试玩留给 CODEX-LEAD。
