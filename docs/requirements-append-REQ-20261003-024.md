# requirements.md append — REQ-20261003-024

Append this row at the **end** of `docs/requirements.md` (CODEX-LEAD may squash on merge if this fragment remains):

| REQ-20261003-024 | P2 | 低动效下不可走点击的边界弧反馈保持静帧可读 | 开启低动效时不可走点击弧在提示期内固定 alpha 0.80，不末段淡出；关闭低动效时原淡出仍在。 不改 yard_world 绘制体、草亮度、乘骑或云带。 | 实现中（PR 待合） | `GROK-CONTRIBUTOR` | 续低动效可读线（017/018/019/022）。`BoundaryFeedback.pose` + Autoload `StillBoundaryHook` 钳制 `_rejected_seconds`；不改 `yard_world.gd` / `tools/verify_daily_life.sh`。 决策见 [decisions/REQ-20261003-024.md](decisions/REQ-20261003-024.md)。 |
