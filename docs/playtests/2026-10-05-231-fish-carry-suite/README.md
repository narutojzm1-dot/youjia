# #231 钓鱼携鱼一致性：真实生产类复现/回归（GROK-CONTRIBUTOR）

初版基于 main `ab1007be903c0404ad2605414215bbff7e0a94c3`（分支从 `6e7435c382a9307925668f92afb849804dcd2a5d` 起）；修订 1 已合入 main `210c2c33`（含 #277 odd 通知文案）。Owner：GROK-CONTRIBUTOR 只承担测试子项（交接 [#231 5985809083](https://github.com/narutojzm1-dot/youjia/issues/231#issuecomment-5985809083)）；父缺陷修复与语义决策仍 CODEX-LEAD。

## 修订 1（回应 CODEX-LEAD-ASSISTANT REQUEST CHANGES [5986358795](https://github.com/narutojzm1-dot/youjia/pull/276#issuecomment-5986358795) 与 Leader [5986424860](https://github.com/narutojzm1-dot/youjia/pull/276#issuecomment-5986424860)）
1. **夹具重置顺序**：`_fresh` 改为先 `Main._clear_world()`（它会经 `YardWorld._save_progress` 把上一序列 day/elapsed/plant 写回 SaveStore），再把 SaveStore 数据重置为编解码默认值，最后 `_start_holiday()`（此时其内部 `_clear_world` 为空操作）。每个序列新增 3 条断言：世界与存档的 holiday_day / day_elapsed / plant 三项均等于默认值，日志记录上一序列 elapsed（如 22.5 → 0.0）证明未回灌。边界：这是测试内对内存存档数据的重置，生产代码不变。
2. **独立执行隔离**：套件启动即检查 `YOUJIA_TEST_ISOLATED_DATA` 必须等于 `XDG_DATA_HOME` 且 Godot user 目录位于其中，否则打印 REFUSED 并退出 2，不实例化 Main、不写存档（已验证：裸跑退出 2，临时 HOME 下 0 个存档文件；标记与 XDG 不一致同样拒绝）。新增独立入口 `bash tools/run_fish_carry_suite.sh`（临时 XDG，跑完即删）；`tools/verify_daily_life.sh` 在其既有临时 XDG 上导出同一标记。**不要用裸 `godot --script` 复跑本套件。**
3. **S7 文案行**：不再固定写“溜走”，改为输出当前 zh/en 实际文案；若仍含“溜走/slipped away”则记 FINDING，否则记 NOTE 注明原基线发现。当前 main 输出 zh“钓到一条奇怪的鱼。”/ en“Caught a peculiar fish.”，记为 NOTE；odd 携带 20 秒且可投喂的行为照旧断言（现状刻画，不代表 #231 已修复）。

## 变更说明
- 新增 `test/fish_carry_consistency_suite.gd`，挂入 `tools/verify_daily_life.sh` 套件循环（并导出隔离标记）；新增独立入口 `tools/run_fish_carry_suite.sh`。
- 需求表 #231 段落“尚待接收”的状态回写留给 CODEX-LEAD/GAME-PM（同 PR270 惯例），本 PR 不改共享 requirements/decisions，避免与 #251/#143 草稿冲突；接收回执见 #231 与 #242 评论。
- 不改 Main / YardWorld / 存档 / 动物反馈 / 本地化文案；不删除合法旧鱼；不为凑绿改期望。

## 方法与受控注入边界
- 实例化真实 `scenes/main.tscn`，`main._start_holiday()` 后每帧走 `Main._process(1/60)`（暂停门禁走真实路径）；通知 key 直接连 `YardWorld.notice_requested`，并读 `Main._notice_key`（HUD 实际显示键）。
- 抛竿、收杆、投喂只走 `request_pointer_action` / `request_primary_action`；人物与鸟都不瞬移。
- 注入仅两项：每个序列前 `seed()`；真实抛竿后可把随机 5–10 秒等咬钩的 `_fish_timer` 缩到 0.4 秒（只用于让旧鱼序列落在 20 秒携带窗内）。咬钩/空竿/鱼种仍由 YardWorld 自己的 `randf()` 分支决定。不使用假 Host、不模拟结果。

## 序列与结果（Godot 4.7.2，修订 1：85 checks，failures=[]；初版 58）
| # | 序列 | 实际观察 |
|---|---|---|
| S1 | 全新档无鱼，咬钩不收杆 | `notice.fishing.miss`，carry 为空；主操作非 toss_fish；点鸭鹅不投喂（点池中鸭子会落到抛竿） |
| S2 | 携一条 small 时点池塘再抛竿、咬钩不收 | 携鱼中点池塘**仍可再抛竿**；miss 后旧鱼保留 small，计时 20.00→13.38 继续递减不重置；HUD 最后通知 `notice.fishing.miss`，提示 `hud.hint.carrying_fish`，仍可投喂 |
| S3 | 20 秒到期 | carry 清空，`notice.fishing.release` 恰一次不重复；之后点鸭鹅无投喂、无抚摸通知 |
| S4 | 自动接近途中到期（剩 0.5 秒时点 143px 外的鸟） | 到期取消 toss 接近与选中，人物停下，无投喂，release 一次 |
| S5 | 携鱼时暂停 30 秒再恢复 | 暂停期间计时冻结、主操作被忽略；恢复 1 秒后 20.00→19.00 |
| S6 | 投喂成功后连点 | 只一次 `notice.toss_fish.duck`，carry 归零，后续无 release；多余点击落到最近的马 `notice.pet.horse`（抚摸爱心，不是投鱼） |
| S7 | 钓到“奇怪的鱼” | 基线 6e7435c 文案 `奇怪的鱼。盯了你一眼，溜走了。`（en: "...then slipped away."），但 carry=odd 20 秒且可投喂鸭/鹅；#277 后当前文案 `钓到一条奇怪的鱼。` / `Caught a peculiar fish.`，携带与投喂行为不变 |

修订 1：合入 main 210c2c33 后完整严格 `tools/verify_daily_life.sh`（含本套件 85 checks）本地退出 0；完整日志 497 行 SHA256 `7fd94e5e6c448dae6b948208905b67f9c69e23ba36ac8774ced6b34c575e3096` 未入库（经 API 提交，体积受限；初版 488 行 `b83a0d77…`），各套件汇总行见 [daily-summary.log](daily-summary.log)，本套件输出 [fish-carry.log](fish-carry.log)；评审请以复跑为准。

## 发现（交 CODEX-LEAD 决定，不在本 PR 修）
1. **S7 最贴近玩家原话“鱼溜走后仍可喂鹅”**（原基线发现）：`notice.fishing.caught.odd` 曾说鱼“溜走了”，实际却进入携带并可投喂。CODEX-LEAD 已在 #277 只改 zh/en 文案；本套件现输出实际文案供复核；odd 是否入携带仍由 Leader 定。
2. S2：已有鱼时 miss 文案与无鱼时完全相同，未说明手里那条还在；且携鱼时点池塘仍会再抛竿（主操作按钮是投鱼，指针路径是钓鱼）。最小建议：携鱼时 miss 用区分文案（如“这条跑了，手里那条还在”）。
3. S6：投喂后多余点击会抚摸附近的马，出现爱心，可能被读成“又喂了一次”；属现有主操作回退，非重复消费。
4. 到期、途中到期、暂停、重复消费均未发现缺陷。

## 修订 2：真实 Web 自然输入三序列（Leader [5986917049](https://github.com/narutojzm1-dot/youjia/pull/276#issuecomment-5986917049)）
- 构建：线上 Pages `game-5d6da70`（= main 5d6da70，本 PR 不改玩法），下载 index/js/wasm/pck 本地静态服务（哈希见 [web/live-build.sha256](web/live-build.sha256)）；Playwright 无头 Chromium 1280×720，swiftshader WebGL。每序列新浏览器上下文 = 全新存档。
- 输入只有画布鼠标点击：点池塘水面（选中并走过去）、点 HUD 主操作按钮（垂钓/收杆/投鱼）。不注入、不 JS 进游戏、不缩短计时、不 seed；咬钩/空竿/鱼种全由线上构建随机。按钮文字识别仅用于决定何时点“收杆！”（`_label`，见脚本）；通知与目标文案为逐帧截图人工读出。
- 脚本 [web/browser.py.txt](web/browser.py.txt)，逐帧/点击时间线 [web/web-sequences.json](web/web-sequences.json)。截图因 API 只能提交文本未入库，评审请用脚本复跑（单次约 1 分钟/序列）。

| 序列 | 实际观察（Web） |
|---|---|
| A 无鱼失败 | 点池塘→走到北岸，目标“水塘·垂钓”；点按钮抛竿→“鱼线落进水里。等吧。”，按钮“等着……”；等待中多点一次只得“还没动静。水也很耐心。”（不取消）；约 10 秒后“有动静——快收杆！”/按钮“收杆！”，不收→约 6 秒后“跑了。没关系。”。此后目标与主操作变为最近的“草泥马·牵着草泥马走走”，没有投鱼目标（carry 为空的可见表现）。 |
| B 有旧鱼 | 抛竿→约 10 秒咬钩→点“收杆！”→“钓到了，小小的，亮亮的。”，目标立即变“大鹅·把鱼扔过去”。**携鱼时点池塘水面不会再抛竿**，而是边界提示“这里不能落脚，沿院子里的草地走吧。”（原生 S2 经 `request_pointer_action` 携鱼可再抛竿，Web 水面点击却没有；推测与携鱼时目标选择不返回钓鱼有关，未核实，交 Leader）。未投喂，约 20 秒后“鱼拍拍尾巴，溜回水里了。”一次，目标回“水塘·垂钓”，再点按钮正常抛竿，无投鱼/抚摸。**Web 自然点水面达不到“有旧鱼再 miss”分支**；改点岸边人物脚下的补测没走到抛竿，原因未分析，未完成。 |
| C 到期 | 抛竿→约 9 秒咬钩→收杆→“钓到一条奇怪的鱼。”（#277 后文案），odd 进入携带：约 20 秒内目标一直是“大鹅·把鱼扔过去”；到期“鱼拍拍尾巴，溜回水里了。”恰一次，目标回“水塘·垂钓”；之后点主操作是抛竿（“鱼线落进水里。等吧。”），无投鱼、无抚摸。 |

Web 新发现（交 CODEX-LEAD 决定，本 PR 不修）：
5. **携鱼时点水面得到“这里不能落脚”**：玩家想再钓一条时提示像走错路，且与原生 S2 指针路径表现不一致；本轮 Web 未能触发“有旧鱼再 miss”。
6. **草泥马会挤到钓鱼点抢主操作**：run3 W1 第 009 帧按钮为“垂钓”，约 1 秒后点下时主操作已换成草泥马，结果“草泥马跟着你，沿着草地走。”而不是抛竿；之后再点水面得到“这里不能落脚”。另两次 W1 复跑与岸边补测也都没走到抛竿，未逐帧分析原因，只记为未完成，不算证据。

## 未覆盖 / 下一产物
- Web 三序列：无鱼失败、到期已在线上构建自然输入复现；“有旧鱼再 miss”在 Web 经水面点击不可达（发现 5），岸边补测未完成。未做真机/触屏/实听。
- 修订 2 合入 main `4f8e7221`（经 update-branch；为无冲突合并先临时还原 daily 套件行，再同时保留 `yard_snapshot` 与 `fish_carry_consistency` 及 `YOUJIA_TEST_ISOLATED_DATA`）。合入 5d6da70 后完整严格 daily 退出 0（543 行，SHA256 `1d99336f55802f73dfb774298a3413fcd1195629d4e085f596870b915abba991`，含 yard snapshot 10 checks、fish-carry 85 checks []）；4f8e722 相对 5d6da70 只增文档。
