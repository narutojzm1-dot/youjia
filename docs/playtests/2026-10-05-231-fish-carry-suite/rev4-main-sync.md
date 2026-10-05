# #276 修订 4：同步 main `f32a1f2`（含 #291 发现 7 修复），只验证、不改测试

Owner：GROK-CONTRIBUTOR（仅测试子项）。本文件是修订 4 的变更说明；README 的修订 1–3 记录保持原样。

- 合入 main `f32a1f204a764d7c0baf4f12cd18a3e796f4e704`（含 #291 `7649912`：活动钓竿优先于默认投鱼；#293/#295 存档容量；#296 钓鱼发布证据）。
- 唯一冲突是 `tools/verify_daily_life.sh` 套件行。做法与修订 2 相同：先临时去掉本 PR 的 `fish_carry_consistency`（`3919f17`），经 update-branch 无冲突合并（`154e83e`），再在新提交里把它挂回 main 那一行的末尾。保留 main 新增的 `fishing_active_hud`，`YOUJIA_TEST_ISOLATED_DATA` 不变。
- 测试代码与 `f3cef33` 完全相同，没有为凑绿改期望。
- 合并后的树（= `154e83e` + 本提交）完整严格 `bash tools/verify_daily_life.sh` **退出 0**（Godot 4.7.2，1132 行，SHA256 `440a6188f2564d9e8e4c320aefb563537e7be0883978c6e8f0aade3e1eb9e04b`）：yard snapshot 10 checks、fishing active HUD 10 checks 0 failures、fish-carry 85 checks []。摘要见 [daily-summary.log](daily-summary.log)，序列日志见 [fish-carry.log](fish-carry.log)。

## 与 #291 的交叉核对
- S2 日志里 `primary_while_carrying` 从 `action.toss_fish` 变成了 **`action.fish_waiting`**：携鱼再抛竿时，主操作已经显示进行中的钓竿。
- S2 其余断言（miss 后旧鱼保留、计时不重置、miss 后默认回到“把鱼扔过去”）全部仍通过，和 #291 自己的回归一致。
- 所以 README 里的**发现 7 在原生层面已由 #291 修复**。本 PR 不重复 #291 的断言，只记录日志的变化。

## 未做
- 没有在含 #291 的线上构建上重跑同岸 Web 序列（Leader 已在 #296 归档自然再抛竿证据）。
- 原帧二进制仍未入库（原因见 README 修订 3 与 PR 评论 5988107051）。
