# REQ-001 步态速度切片：Web 验收与发布

- PR：[ #27 提升角色默认行走速度](https://github.com/narutojzm1-dot/youjia/pull/27)
- 合并提交：`fce84fe6749549acba8b509d0f05ebebce286fbe`
- 最终 PR head：`4635ed4867e9574218f5aa3dc0a998d2afdff7ff`
- Owner：`CODEX-LEAD`
- 范围：sequence 步态位移倍率从 `39/96` 调至 `0.64`；默认 96 px/s 基准下约 `61.4 px/s`。步态相位仍由实际碰撞后移动距离推进。PR 不包含角色互动动作。

## 验证

- `npm run verify:locomotion`：通过，410 项步态检查以及交互和视口审计通过；30/60/120 Hz 下三秒位移为 167.2–167.9 世界像素，帧率间差异小于 1 像素。
- 全新 Web 导出载入 Chromium：HTTP 200、Canvas 就绪、无 JavaScript 错误；在 1280×720 复核键盘行走、停步回 idle 和左右转向镜像。
- 公开版本：验证/发布 Actions [37053610498](https://github.com/narutojzm1-dot/youjia/actions/runs/37053610498) 与 Pages 部署 [37053939567](https://github.com/narutojzm1-dot/youjia/actions/runs/37053939567) 均完成且成功。`game-release.json` 的 `sourceCommit` 为合并提交 `fce84fe6749549acba8b509d0f05ebebce286fbe`，`entry` 为 `game-fce84fe`，引擎为 Godot `4.7.2.stable.official.ed1daf0bf`。
- 从公开 Pages 下载 `game-fce84fe.pck` 并计算：12,776,620 字节；SHA-256 `8ee345ec1d1186db9b004aefebfc64e3ab8b724713e11e5ae097d56a3a6d1b9b`。

## 产品结论与边界

走路速度、起停和方向镜像已有 Web 实玩证据，速度切片可以验收。文档记录的轻微足部滑动仍是已知画面限制；“自然不自然”仍需制作人/玩家体验判断，不能由速度数字代替。未记录携草状态的浏览器人工复核；自动回归覆盖了携草相关路径。抚摸、招呼、拿取和喂食时的主角身体动作不在 PR #27 范围，REQ-001 保持进行中。

## 审查记录缺口

PR 讨论中存在独立审查对 SHA `5fc09f4db02a073c9e7d5c5bbb502d7ce2f53b95` 的批准记录；之后修复曾截断的 `test/locomotion_suite.gd`，最终 head 更新为 `4635ed4867e9574218f5aa3dc0a998d2afdff7ff`。最终 head 的验收评论写明独立审查仍在进行，未找到合入前针对该 SHA 的批准记录。PR 已经合入，本记录不将其改写成流程完整；需要补充对已合入版本的独立事后代码复核，并在后续 PR 按最终 SHA 重新审查。
