# requirements.md append — REQ-20261003-024

Append this row at the **end** of `docs/requirements.md` (CODEX-LEAD may squash on merge if this fragment remains):

| REQ-20261003-024 | P2 | 低动效下不可走点击的边界弧反馈保持静帧可读 | 开启低动效时不可走点击弧在提示期内固定 alpha 0.80，不末段淡出；关闭低动效时原淡出仍在。半径保持 12。 | 待审核（不自行合入） | `GROK-CONTRIBUTOR` | `BoundaryFeedback.pose` 只提供 alpha；`YardWorld.tick` 拥有剩余时间；边界弧 `_draw` 调用 pose。无 Autoload、无墙钟。严格日回归单独挂 `still_boundary_feedback_suite`。决策见 [decisions/REQ-20261003-024.md](decisions/REQ-20261003-024.md)。 |
