# #231 钓鱼携鱼一致性：真实生产类复现/回归（GROK-CONTRIBUTOR）

基于 main `ab1007be903c0404ad2605414215bbff7e0a94c3`（运行时同 d480b969；分支从 `6e7435c382a9307925668f92afb849804dcd2a5d` 起，其间 #275 仅文档）。Owner：GROK-CONTRIBUTOR 只承担测试子项（交接 [#231 5985809083](https://github.com/narutojzm1-dot/youjia/issues/231#issuecomment-5985809083)）；父缺陷修复与语义决策仍 CODEX-LEAD。

## 变更说明
- 新增 `test/fish_carry_consistency_suite.gd`，挂入 `tools/verify_daily_life.sh` 套件循环。
- 需求表 #231 段落“尚待接收”的状态回写留给 CODEX-LEAD/GAME-PM（同 PR270 惯例），本 PR 不改共享 requirements/decisions，避免与 #251/#143 草稿冲突；接收回执见 #231 与 #242 评论。
- 不改 Main / YardWorld / 存档 / 动物反馈 / 本地化文案；不删除合法旧鱼；不为凑绿改期望。

## 方法与受控注入边界
- 实例化真实 `scenes/main.tscn`，`main._start_holiday()` 后每帧走 `Main._process(1/60)`（暂停门禁走真实路径）；通知 key 直接连 `YardWorld.notice_requested`，并读 `Main._notice_key`（HUD 实际显示键）。
- 抛竿、收杆、投喂只走 `request_pointer_action` / `request_primary_action`；人物与鸟都不瞬移。
- 注入仅两项：每个序列前 `seed()`；真实抛竿后可把随机 5–10 秒等咬钩的 `_fish_timer` 缩到 0.4 秒（只用于让旧鱼序列落在 20 秒携带窗内）。咬钩/空竿/鱼种仍由 YardWorld 自己的 `randf()` 分支决定。不使用假 Host、不模拟结果。

## 序列与结果（Godot 4.7.2，58 checks，failures=[]）
| # | 序列 | 实际观察 |
|---|---|---|
| S1 | 全新档无鱼，咬钩不收杆 | `notice.fishing.miss`，carry 为空；主操作非 toss_fish；点鸭鹅不投喂（点池中鸭子会落到抛竿） |
| S2 | 携一条 small 时点池塘再抛竿、咬钩不收 | 携鱼中点池塘**仍可再抛竿**；miss 后旧鱼保留 small，计时 20.00→13.38 继续递减不重置；HUD 最后通知 `notice.fishing.miss`，提示 `hud.hint.carrying_fish`，仍可投喂 |
| S3 | 20 秒到期 | carry 清空，`notice.fishing.release` 恰一次不重复；之后点鸭鹅无投喂、无抚摸通知 |
| S4 | 自动接近途中到期（剩 0.5 秒时点 143px 外的鸟） | 到期取消 toss 接近与选中，人物停下，无投喂，release 一次 |
| S5 | 携鱼时暂停 30 秒再恢复 | 暂停期间计时冻结、主操作被忽略；恢复 1 秒后 20.00→19.00 |
| S6 | 投喂成功后连点 | 只一次 `notice.toss_fish.duck`，carry 归零，后续无 release；多余点击落到最近的马 `notice.pet.horse`（抚摸爱心，不是投鱼） |
| S7 | 钓到“奇怪的鱼” | 文案 `奇怪的鱼。盯了你一眼，溜走了。`（en: "...then slipped away."），但 carry=odd 20 秒且可投喂鸭/鹅 |

完整严格 `tools/verify_daily_life.sh`（含本套件）本地退出 0；完整日志 488 行 SHA256 `b83a0d7760b3ab9b7074c5e1d7cb30e4c18d5e84263b13e5a6255caeb4271b4a` 未入库（经 API 提交，体积受限），各套件汇总行见 [daily-summary.log](daily-summary.log)，本套件输出 [fish-carry.log](fish-carry.log)；评审请以复跑为准。

## 发现（交 CODEX-LEAD 决定，不在本 PR 修）
1. **S7 最贴近玩家原话“鱼溜走后仍可喂鹅”**：`notice.fishing.caught.odd` 说鱼“溜走了”，实际却进入携带并可投喂。最小建议：只改该条 zh/en 文案为“钓到/拿着”的含义（或 odd 不入携带二选一，由 Leader 定）。
2. S2：已有鱼时 miss 文案与无鱼时完全相同，未说明手里那条还在；且携鱼时点池塘仍会再抛竿（主操作按钮是投鱼，指针路径是钓鱼）。最小建议：携鱼时 miss 用区分文案（如“这条跑了，手里那条还在”）。
3. S6：投喂后多余点击会抚摸附近的马，出现爱心，可能被读成“又喂了一次”；属现有主操作回退，非重复消费。
4. 到期、途中到期、暂停、重复消费均未发现缺陷。

## 未覆盖 / 下一产物
- 真实 Web 复现（无鱼失败 / 有旧鱼失败 / 到期三序列）本轮未做，下一轮补 Web 导出 + Chromium 记录；本 PR 仅为原生 headless 证据，不冒充 Web/真机/实听。
