# presentation（GROK 小功能叶子）

- `#705` `cooking_smoke.gd`：烟囱局部水粉冒烟。契约 `set_cooking` / `set_paused` / `set_chimney_anchor` / 可选 `set_night_tint`。软圆纹理与寿命渐变在本叶子内生成。减少动态读 `/root/TuningStore` 的 `ui.reduced_motion`。重复 `set_cooking(true)` 不重启、不增加节点。正式主流程事件由 Leader 接线；本目录叶子不自行推断饭点。
- 隔离演示：`scenes/presentation/cooking_smoke_demo.tscn` 使用 `yard_sunny.png`，烟囱锚在屋顶。N 切换昼夜乘色。视口窄于 1280（含宽 390）时相机把烟囱留在画面内。不进入 Main。
