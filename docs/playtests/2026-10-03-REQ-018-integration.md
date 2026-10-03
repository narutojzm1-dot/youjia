# REQ-018 集成验收与首次发布记录

- 功能 Owner：`GROK-CONTRIBUTOR`；集成验证/发布记录：`CODEX-LEAD`。
- PR #108 最终 SHA `245a0ad4a6273ed79bedf61588cb2237003783ce`，对照 main `eec95661495a0a38f9e9ae244e9d0a2cbb56d637`。
- 范围：低动效时目标脚底圈半径固定；钓到庆祝环固定姿态、不飞碎点。普通模式公式/3.2 秒时长、钓鱼规则和存档不变。

## 验证

Godot 4.7.2 完整 `verify:daily` 退出 0。独立 reviewer `CODEX-LEAD-REVIEW-PR-108` 在独立 worktree 导入无脚本错误，复跑 `still_catch` 6 项、`interaction_photo` 90 项通过；REQ017 保存/JSON/回放/旧快照路径保留。[审核记录](https://github.com/narutojzm1-dot/youjia/pull/108#issuecomment-5967520071)。

普通 Web 导出/Chromium 1280×720 首帧、点击进入院子成功，无页面/控制台错误。[普通院子](2026-10-03-REQ-018-integration/normal-yard.png)。候选 PCK 13,815,408 字节，SHA-256 `e3dc8908bac559f55c658f5f25b14546fd3d97871a1b876b215b3bbe6c320678`，是本地候选而非正式发布哈希。

受控 Web 实际实例化 WorldEffectsOverlay，令 target/catch 在 0.2/0.8 两个相位绘制到 SubViewport；8 项实际像素断言通过：低动效跨时刻像素相同，普通动效像素不同，四种样本均可见。独立 reviewer 另启 Chromium 复验 8 项，零失败/零浏览器错误。[受控对照](2026-10-03-REQ-018-integration/controlled-web.png)。

**验证限制：** 受控 target 固定 pet_alpha=1，只隔离半径变化；世界既有 pet_alpha 明暗脉动仍在，不声称整枚目标标记完全静止。此测试也不是自然钓到鱼的流程实玩。当前原生图形显示无法连接 X11，缺少安装 Xvfb 权限，未完成原生实际像素截图；本轮使用目标平台 Web 实际绘制与原生完整 headless 回归覆盖，独立 reviewer 明确接受。

## 复现受控绘制

验收夹具随文档保存为 [controlled_render.gd](2026-10-03-REQ-018-integration/controlled_render.gd) 和配对场景。正常游戏导出排除 docs，不加载夹具。

有原生显示时运行：`godot --path . res://docs/playtests/2026-10-03-REQ-018-integration/controlled_render.tscn -- --quit-after-test`。Web 验收使用临时工程副本，把 main_scene 指向该场景，并临时移除 docs 导出排除项；导出到独立目录后恢复配置，浏览器等待 `window.stillCatchResult` 为 8 checks、空 failures。不要把受控副本当正式游戏发布。

## 合入与发布

PR #108 已合入 `26c93c84eb8685674f2448e851d0461007ee231a`。正式发布已核验，以下为首次发布证据。


- [Actions 37111927956](https://github.com/narutojzm1-dot/youjia/actions/runs/37111927956) 完整回归/导出/发布成功；[Pages 37112060101](https://github.com/narutojzm1-dot/youjia/actions/runs/37112060101) 成功。
- 2026-10-03 17:10 左右（Asia/Shanghai），公开 manifest sourceCommit 为同一合入提交、entry/data-build 为 `game-26c93c8`。公开 PCK 13,815,408 字节，SHA-256 `4b089708ea20c44c85651504aa2f014f8d494c9b67818a27e7f7a0458c850138`，与 gh-pages 对应文件的独立下载字节/哈希一致。
- 公网 Chromium 1280×720 正确版本收到首帧，点击标题进入院子，无页面/控制台错误。[公开院子](2026-10-03-REQ-018-integration/public-yard.png)。公网只检查版本/启动，不伪称自然钓鱼或重做受控绘制。
- 正式哈希与本地候选分别记录；文档更新不意味着新的游戏运行时版本。REQ018 完成，后续版本不覆盖本首次证据。
