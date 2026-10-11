# presentation（GROK 小功能叶子）

- `#705` `cooking_smoke.gd`：烟囱局部水粉冒烟。契约 `set_cooking` / `set_paused` / `set_chimney_anchor` / 可选 `set_night_tint`。软圆纹理与寿命渐变在本叶子内生成。减少动态读 `/root/TuningStore` 的 `ui.reduced_motion`。正式主流程事件由 Leader 接线；本目录叶子不自行推断饭点。
- 隔离演示：`scenes/presentation/cooking_smoke_demo.tscn`（不进入 Main）。
