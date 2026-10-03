# 代理开发入口

此文件适用于 Codex、GROK、MANUS、Cursor Local（`CURSOR-CONTRIBUTOR-LOCAL`）及其他参与本仓库的开发代理。每次开始任务时，先阅读以下仓库记录：

1. [`CONTRIBUTING.md`](CONTRIBUTING.md)：角色、分支、PR 与冲突处理规范。
2. [`docs/agents.md`](docs/agents.md)：开发者身份登记表。
3. [`docs/game-design.md`](docs/game-design.md)：当前生效的游戏策划基准。
4. [`docs/requirements.md`](docs/requirements.md)：需求列表、负责人、状态和验收条件。
5. [`docs/decisions.md`](docs/decisions.md)：需求来源、决定、变更和体验台账。

## 每项工作的开始方式

- 先确认自己在 `docs/agents.md` 中登记的 `Agent-ID`，再从 `docs/requirements.md` 查看负责人和状态。
- 只实现自己已认领或被指定的需求；认领前通过 PR 更新需求负责人和状态，由 Codex 确认，避免多人同时抢同一项。
- 开始编码前查看 `main` 上开放 PR 的文件范围和依赖；重叠时通过相关 PR 描述或仓库需求记录协调，不覆盖其他代理的提交。
- 分支和 PR 写明 `Agent-ID` 与需求编号；所有玩家可见变更都要保留体验证据。
- 自己可以维护并合入自己的 PR，但合入前必须由独立子代理审核最终 commit。把 reviewer Agent-ID、结论、完整 commit SHA 和摘要写入 PR；自己不能充当 reviewer。审核后 commit 有变化就重新审核。

## 项目信息同步

项目共享状态以仓库为准。需求认领、任务进度、阻塞原因和验收条件记在需求列表；决策与状态历史记在台账；实现、代码讨论和评审记在 PR。不要假定某个代理能读到另一个代理的私聊或对话；如果用户在聊天中给出项目指导，应把结论同步到台账和策划基准，再由各代理共同遵循。

任何代理不得直接向 `main` 推送或绕过 PR。PR 作者在独立子代理审核和项目检查通过后可自行合入；Codex 负责跨 PR 协调，并在每次介入时整体检查开发情况，作为后置保底。涉及产品承诺或未决方向时先等用户指导。

## 每日版本关键点（所有贡献者必读）

- 每天北京时间（Asia/Shanghai）23:00最后一轮是**日版本节点**；所有活跃贡献者须按[日版本规范](docs/collaboration/daily-release.md)准备Owner、精确SHA、审核/测试/体验证据、可发布内容与阻塞交接。
- CODEX-LEAD系统核对代码架构、玩法、美术/音频、QA、开放PR与依赖，集成并发布通过门禁的内容；未完成项明确延期，不降低独立审核或验收要求，不因节点自动接管他人任务。
- 发布后核对Actions、Pages、公开manifest和PCK实际哈希，形成`docs/releases/YYYY-MM-DD.md`版本节点文档，并向用户发送一次邮件日推；失败也如实汇报，不能宣称未发布的版本成功。
- 先检查同一节点是否进行中/已完成，避免重复发布或邮件；普通每小时开发仍按原分工推进。时区、延迟补做、各方职责、文档与邮件要求以日版本规范为准。
