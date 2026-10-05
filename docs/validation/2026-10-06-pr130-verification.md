# #130 PR 阶段回归与 Web 导出

Agent-ID: CODEX-LEAD。实现基线 `8f464b25598421b448a2af9c10a6b0653bf11e1a`；独立分支 `work/codex-lead/pr130-validation`。随后整合 main `85fada2edb5be5c4930a7ccf651ad7bfa1473073`，保留 PM 与关系体验归档；仅解开决策台账末尾追加冲突，原内容均保留。

原发布工作流只在 main push / workflow_dispatch 执行，PR 评审期间没有对应自动回归。新增 `.github/workflows/verify-pr.yml`，不改 `publish-pages.yml` 或运行时代码。

## 行为与边界

- main 目标 `pull_request` 的默认 opened / synchronize / reopened 事件；采用 checkout 默认 proposed merge，不把单独 head 检查冒充与 main 的组合检查。代码发生变化即验证；仅 `docs/**` 和 `README.md` 的 PR 按现有发布规则跳过。
- `contents: read`；checkout `persist-credentials: false`。没有 `pull_request_target`、密钥引用、Pages 写权限、发布步骤或 artifact promotion。发布辅助测试内部只写各自临时本地 Git fixture，不向 GitHub 推送。
- 同 PR 新运行取消旧检查。job 最长 45 分钟，安装 10 分钟、daily 30 分钟、导出 5 分钟分别限时；超时/失败保持失败，不配置 continue-on-error。
- 安装与主线发布相同的 Godot 4.7.2 与 Web templates，执行两个既有 Python 发布辅助检查、`bash tools/verify_daily_life.sh` 和真实 release Web export，并确认 HTML / JS / WASM / PCK 非空。
- main 合并后仍由既有发布 workflow 重新验证并导出；PR 结果不代替 Actions / Pages / 公开 manifest 和 PCK 的上线验收。本切片未核查或设置 GitHub branch protection，未强制 required check；docs-only 跳过的检查也不承诺可直接设为 required。

## 验证状态

本地 `actionlint 1.7.7` 检查通过（退出 0，无诊断），YAML 解析与 12 项只读边界/主线命令一致性检查通过，`git diff --check` 通过。这些只证明静态配置；避免与同会话的游戏/browser 验收争用资源，未在本地运行 Godot、导出或浏览器。本 PR 在 GitHub 上的实际 Actions 通过及精确最终 SHA 独立审查是合入前置；未完成前不宣称此门禁已正式生效。具体检查结果附于本 PR。

没有玩家可见变化，无伪造截图或试听验收。#130 中每套可信完成标记、后续工程风险及其他模块完整验收继续按各原单处理，本文不作为关闭父单的依据。
