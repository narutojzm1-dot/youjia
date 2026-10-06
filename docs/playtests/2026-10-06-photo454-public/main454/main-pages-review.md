# PR454 a0bb 主线及 Pages 运行核验：成功

核验者：relationship45_qa。只读跟进原运行，未触发、重试或取消工作流，未启动引擎或浏览器。

源提交 `a0bb75e38e59032a6df72a2122af4403c3c3e816`，tree `8394f116f24295b0800824e90db1cf56d9334c1d`，双父 `67c87f08c673c18b33fd14ddfe8be54991024f3c` 与已审查 PR454 head `d9302cdce4a7293d14df773ba50d7c5f231291c4`，树与实际 PR CI 一致。

## 主线运行

[Run37379761014](https://github.com/narutojzm1-dot/youjia/actions/runs/37379761014)，push、attempt1、head精确a0bb；job111998390379全部12步骤success。已实际下载并读取完整日志，主线严格daily再次运行73次Godot（import1+suite72），逐段核72/72准确完成行；50受控门禁、新mat550、两项Node、retention11、本地publisher fixture、真实Web导出及最终publish均通过，daily/export/publish日志无错误、警告或资源加载失败诊断。

publish原始日志明确entry `game-a0bb75e`，实际将gh-pages从b9c3d92推进到 **`29a434c286067c24db55e2adcf2b31e2d9cceb69`**。按该精确Git提交读取`game-release.json`，其sourceCommit为完整a0bb、entry为game-a0bb75e、publishedAt为2026-10-05T22:11:56Z。此处读取的是已发布Git提交中的清单，不冒充公开HTTP清单验收。

## Pages 运行

[Pages Run37380911155](https://github.com/narutojzm1-dot/youjia/actions/runs/37380911155)，head精确29a434c，attempt1，最终completed/success，updated2026-10-05T22:12:53Z。

- build job112002364268：success。
- report-build-status job112002504298：success。
- deploy job112002504340：success。

已实际读取完整Pages运行日志：build checkout `%H` 为29a434c；deploy请求 `pages_build_version` 为同一29a434c，artifact_id为11373024606；部署日志于22:12:51.2374372Z报告 `Reported success!`。因此没有把PR455或其他新构建当作a0bb的Pages结果。

## 证据与边界

本归档保留[精简来源链](release-chain-summary.json)及两个原运行日志ZIP的长度/哈希；完整运行日志可由上述Actions链接获取。本文件保留核验者当时的范围，不用该主线审阅替代另行公开HTTP及浏览器核验。

- main ZIP108,806 bytes，SHA256 `bef878514e17b445b2280cf269f372d3543370a8190835c59f65ffc419bcd751`。
- Pages ZIP27,904 bytes，SHA256 `e0f26cc8478804213908047df5418714ec015758bfb2349a956bee899447532b`。
- 精简来源链：`release-chain-summary.json`。

已通知root可继续公开HTTP manifest、实际PCK/模块哈希及普通浏览器验收。本子任务未执行这些公开校验，不声称已体验，也不把Actions/Pages成功替代公开字节验证。
