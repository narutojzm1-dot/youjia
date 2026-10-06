# WORLD-BEIBEI 村边相遇、常住与成长候选

Owner CODEX-LEAD；#503/#504；分支 `codex/lead-beibei`。E 切片已由PR515合入并发布，最新证据见末尾“公开包核验”；上方候选制作过程保留历史时态，不将后续乌龟、鸡、鹅故事算作已实现。

## 玩法与存档

近郊前景路端出现“沿路去村边”，接现有 05 湖畔村落原画；可原路往返或随时回院。同一趟探索、原来的同行动物和三件提篮保持。沿村边石路靠近白色幼犬，停下看后可带 beibei 回家；没有强制收养。确认写入后幼犬才跟随，返院及中断重开都保留同一身份；再次来到村边不会复制一只。

`world_residents` 是独立、版本化的常住动物记录，不是库存物品。队列头依据当前 revision 生成完整快照，不覆盖未知根字段或并发物品变化。收养点击时在 SaveStore 内冻结已确认的相遇资格，明确拒绝后即使先回院也能重试同一个意图；重试不恢复旧探索记录。未知结果只解析原操作，不另发授予。未知/损坏居民 schema 保留原数据并拒绝写入。

成长实验参数：收养确认后的 1800 秒院内游戏时间（现行一天 600 秒，即三个完整游戏日），无离线倒计时、饥饿或死亡。按已确认的院内时钟触发，成长也等待自己的写入确认。成年后附近的 beibei 进入现有概率同行选择；幼犬只在首次收养这一趟跟随回家。绳牵羊驼的优先规则保持。

## 验证范围

- WORLD_RESIDENTS：43 项，包括结构/迁移、重复与修订号、成长边界、未知写入不授予、原操作解析、拒绝后重交、实际原生文件读回。
- BEIBEI_INTEGRATION：46 项，生产 SaveStore + Host + 两页场景 + YardWorld；真实文件收养/成长/重开，原同行者与篮位不丢，拒绝后冻结意图不覆盖新探索状态，幼犬/成年资格，成年同行原画，普通指针命中幼犬轮廓，中文/英文 390×844 与 568×320 按钮/字幕范围。
- 相关回归：探索核心 360、探索场景 296、同行 149、隐藏发现 92、背篓 Main 集成 66。
- 本目录 JPEG 为本机 Godot OpenGL 实际渲染的**受控夹具**：人物位置和成长时间由测试设置，不冒充普通操作走完三天，也不是物理手机。1280、390、568 的相遇/接回与院内幼年、成年姿态均有图。幼犬与人物/草泥马的站位已分开；整张原画不拆肢、不拉伸变形成成年。
- 本地普通 Web 已走通：第18天旧档→院门→近郊路端→村边石路→相遇收养→跟随回程→回院→刷新→第19天小院保留幼犬。第一遍发现站位遮挡，最终候选调整到路旁另一侧；最终正式 Web 再复核。
- 成长边界由控制游戏时钟的原生集成验证；不声称普通浏览器已连续玩满30分钟。最终本地导出/公开包和 CI 证据另补。

## 资源来源

两张 beibei 原始生成图与提示词、SHA256 保存在 `art/candidates/beibei-2026-10-07/`，运行文件在 `assets/holiday/characters/beibei/`，原文件逐字节复制并保留 alpha。幼犬高43、成年高72是实际世界像素校准值；同一白毛、垂耳、卷尾，无品种承诺。村边 PNG 逐字节复用仓库已有 `art/concepts/producer_world_20261005/05_lakeside_village.png`，没有重新生成地理。共享 PaintedPath 只抽出既有道路数学，NearPathLayout 静态入口兼容既有调用方。

点击修复前导出：Godot4.7.2 Web，PCK 35,461,140 bytes，SHA256 `7049d75f502696219dd1c740edf2415f7378d86e68d2324413c8836e3c50ed9e`。本机原生最终45项截图来自隔离目录 `youjia-basket-check-69c56f65-a9dc-4c6c-bb90-9d661aa00e38`；43/66/149/92回归来自 `youjia-basket-check-e025a1b3-210f-428f-9c89-0ed56fc744d4`。公开Linux包会有自己的构建哈希，不与本地包混称。

普通触屏实玩额外发现并修复了动物点击白名单漏 dog：原先按钮/键盘可选中但点击轮廓只走路。已在46项集成中加入真实轮廓中心经 YardInteraction.pointer 命中检查；最终原生通过目录 `youjia-basket-check-4a32143a-790c-4486-bb32-dfaa4c6c95ff`。此前45项原生截图仍是相同画作/布局，不作为本次点击修复的唯一证明。

点击修复后的最终 Web 导出：35,461,140 bytes，SHA256 `ef06c6d7ea744c39a6c6c4ea66b36b6953818dee6d8ff4e9c4146cdd239e70f7`。

## 合入与普通游戏成长补验

PR [515](https://github.com/narutojzm1-dot/youjia/pull/515) 最终 head `fc99e0504afb35b578d1231e0ba7cc9fa84a90be`，与本地 `4b5e6b809f398e6e0f87653b65a27f9b1d5cb8d1` 同树 `61c29a90eda868d56ea28361a6723b06be91b8a0`。CI [37539343562](https://github.com/narutojzm1-dot/youjia/actions/runs/37539343562) 成功，日志确认 WORLD_RESIDENTS 43 / BEIBEI_INTEGRATION 46 均零失败；合入提交 `53ec80ca7367efbd2db1cbc69558e10808f5e719`。

随后同一个普通本地 Web 存档继续正常运行到第22天，beibei 已由幼犬换成成年画作；刷新页面、重新进入小院后仍为成年，并可打招呼。此补验未注入存储或调快浏览器时钟，因此补齐先前“普通浏览器尚未等到成长”的限制；精确1800秒边界仍以受控测试断言为准。浏览器进入院子的控制接口两次报告鼠标发送超时，但随后截图证明点击已执行，游戏页面正常；未将控制工具超时当成游戏失败，也未盲目重复点击。

普通浏览器证据在 `web/`：`web-grown-day22.jpeg` / `web-grown-reopened-day22.jpeg`；此前幼犬重开和390抚摸分别见 `reopened-puppy.jpeg` / `pet-390.jpeg`。这些是桌面浏览器视口验证，不是物理手机测试。公开版本验证见后续章节。

## 公开包核验

发布 [37540602480](https://github.com/narutojzm1-dot/youjia/actions/runs/37540602480) 与 Pages [37541709630](https://github.com/narutojzm1-dot/youjia/actions/runs/37541709630) 均成功；发布日志再确认43/46项零失败。Pages提交 `91379fe48384a7f590e72971a27f7c3f5ef59c0e`。

实际从公开站点下载 `game-release.json`、HTML、PCK和10个存储模块：源提交 `53ec80ca7367efbd2db1cbc69558e10808f5e719`，入口 `game-53ec80c`，PCK **35,460,784 bytes**，SHA256 `73348fdb6eea03ac154493365db6df27a1ac8d8e45ff6fd66a1f887377105381`，Git blob `f46678e1e53f06ab4f3db6f5982d5b9f99fd32f1` 与 gh-pages 树一致；HTML入口和全部存储模块哈希一致。详见 `public/verification.json`，此为Linux公开构建，不与上面的本地Windows包混用。

正式站点普通旧档（第5天、背篓已有松果1）：重载看见 `game-53ec80c` →出院时附近羊实际概率同行→前景路端进入村边→看见路旁幼犬→确认收养→沿石路行走同时保留羊和幼犬→回院→刷新页面重新入院后仍有同一幼犬→打开背篓旧松果仍为1。全程未写浏览器存储或注入游戏状态，控制台 warn/error 为空。截图依次为 `public/meeting.jpeg`、`following-with-sheep.jpeg`、`returned.jpeg`、`reopened.jpeg`、`old-basket-preserved.jpeg`。公开站点此次验证收养与兼容，不冒称在公开档又完整等待30分钟成长；普通成长另见上面的本地同代码导出验证。
