# PR460 main / Pages 来源链独立核验：通过

核验者：relationship45_qa。仅跟进自动原运行；未 dispatch、重试、取消或合并其他 PR，未启动本地引擎或浏览器。

源 main **9623ba22c8edc564e5c89dc6b0171324e9230764**，tree **df0321b4c3762cfe83b9262739016a782c6e0237**，父为870f4faebd6e28c7314e9db97cb39ae27819eded及已审 PR460 head8a401350fedc57e59db86649b57ffd747649144f。与已审最终提交及实际 PR CI 的树一致。

## 主线实际执行

[Run37384961406](https://github.com/narutojzm1-dot/youjia/actions/runs/37384961406)，push、attempt1、head精确9623ba22；job **112015859783** 全步骤success，完成于 **2026-10-05T23:03:59Z**。主线取源22:50:19—22:56:09Z实际350秒；这是耗时观察，不单凭此归因或修改发布流程。

已下载并读取完整实际运行日志，checkout `%H` 确为9623ba22。实际 daily **74 次 Godot 启动 =1 import +73 suites**；依据精确已审源码的入口顺序和完成格式逐段比对，**73/73**可信完成，disabled专项 **4400**、photo-arrival-mat **550**、包装器受控门禁 **50**，两项Node、Python保留11测试和真实本地publisher两构建fixture均通过。真实Web导出及最终publish均成功；daily/export/publish日志未发现SCRIPT ERROR/ERROR/FAIL，也未发现WARNING或资源加载失败诊断。没有用PR的成功代替main复验。

原始publish日志指定entry **game-9623ba2**，实际把构建推送至gh-pages，commit为 **16944e4fa02d280f8ff150b89e62ba76d1ec9f1c**，Git tree **79cd3df48226210e0c505f43ce1f7ea92e3b4523**。

按该精确Git提交读取`game-release.json`，sourceCommit完整等于9623ba22，entry为game-9623ba2，publishedAt **2026-10-05T23:03:50Z**。精确gh-pages树含PCK **game-9623ba2.pck /27,089,276B /Git blob SHA-1 f72b2ad4e258601218c2e5f2a7c1cbc3af0f3a72**，以及10个版本化`save-9623ba2/*.mjs`与147,966B许可页。注意：release/v1清单本身不含PCK SHA256；以上PCK是Git对象信息，不冒公开下载或SHA256核验。

## Pages 实际部署

[Pages Run37386309986](https://github.com/narutojzm1-dot/youjia/actions/runs/37386309986)，head精确16944e4，最终completed/success，updated **2026-10-05T23:04:54Z**。

- build job **112020339538**：success。
- deploy job **112020488228**：success。
- report-build-status job **112020488536**：success。

已读取完整Pages原始日志：build checkout `%H` 为16944e4；deploy的 **pages_build_version=16944e4fa02d280f8ff150b89e62ba76d1ec9f1c**，artifact_id **11379435599**；部署日志于 **2026-10-05T23:04:51.1378646Z**报告`Reported success!`。因此来源链是本次9623源→精确16944Pages提交→同源Pages构建和部署，没有混用其他版本的green状态。

## 安全摘要与证据

[safe-summary.json](safe-summary.json) 提供可供归档的来源链、运行/作业ID、计数与哈希；无signedURL、认证头或私人邮箱。目录另保存fresh API原始响应、Git清单与树、73项完整完成行比对、两个完整运行ZIP及逐层解析结果。

- main日志ZIP **109,375B /SHA256 af9b36201ba89137527ce9cf0c9d27d0ede0c720bdd688a3d208107b5b264105**。
- Pages日志ZIP **30,500B /SHA256 14c5b6c2d9f578823f27a2e9f4d8705ca3ba7c567709362b8c10158d8a2d6a6b**。

本任务只证明已合入源码通过主线回归/导出、推送及对应Pages部署。**未替代公开HTTP manifest、实际公开PCK的SHA256及Git来源核对、10模块/许可文件或正式普通浏览器后验**；这些由root继续执行。没有声称已真实体验线上版本或覆盖保存忙碌态、恢复、所有相册边界和#459焦点问题。

复核UTC：2026-10-05T23:06:27.296095+00:00
