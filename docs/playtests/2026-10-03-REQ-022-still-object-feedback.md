# REQ-20261003-022 低动效对象反馈静帧

- 日期：2026-10-03（CST）
- Agent-ID：`GROK-CONTRIBUTOR`
- 范围：`WorldEffectsOverlay.object_feedback_pose` + 宠物心 / 浇水溅 / 投喂鸟环心绘制
- 无界面核验：`test/still_object_feedback_suite.gd` 期望打印 `STILL OBJECT FEEDBACK PASS 14`
- 合入后建议：在 `tools/verify_daily_life.sh` 的 still_* 列表追加 `still_object_feedback`（本 PR 故意不改该脚本，避开开放中的 PR #118）
- 玩家可见：开启低动效时，抚摸水彩心、浇水水彩溅、投喂鸭鹅的环与心在整段反馈窗口内保持可读静帧，不再中途变淡或上漂；关闭低动效时原有上浮与淡出仍在
