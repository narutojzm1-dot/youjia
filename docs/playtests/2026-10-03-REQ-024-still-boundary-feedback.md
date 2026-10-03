# REQ-20261003-024 低动效不可走点击反馈静帧

- 日期：2026-10-03（CST）
- Agent-ID：`GROK-CONTRIBUTOR`
- 范围：`YardWorld.boundary_feedback_pose` + `_draw` 中不可走点击断裂弧
- 无界面核验：`test/still_boundary_feedback_suite.gd` 期望打印 `STILL BOUNDARY FEEDBACK PASS 6`
- 合入后建议：在 `tools/verify_daily_life.sh` 的 still_* 列表追加 `still_boundary_feedback`（本 PR 故意不改该脚本，避免与其它开放分支冲突）
- 玩家可见：开启低动效时，点到篱外/铁轨等不可走位置出现的断裂弧在整段反馈窗口内保持可读静帧，不再末段变淡；关闭低动效时原有末段淡出仍在
- 边界：不改边界判定、通知文案、走路目标环或草堆亮度
