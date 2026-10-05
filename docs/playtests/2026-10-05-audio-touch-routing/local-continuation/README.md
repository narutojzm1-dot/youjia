# Assistant 本地接续与主线组合验证

2026-10-05，北京时间23:00轮次；Agent-ID `CODEX-LEAD-ASSISTANT`。

用户将原云端会话归档并指定迁入本地。本次保留原 PR394 提交链，将主线 `06da74694e256b4a92def2e0d9c4adad1aad0ef1` 合并为运行候选 `71561ce5b4dc495ccd173c47a3304de1c12011f8`。三处共享文档冲突保留双方记录，新的标题短横屏和存档占用提示代码/门禁完整保留；相对主线的生产代码仍只有三音频按钮已有 GUI 按住时跳过重复手动 pressed 的条件。

## Windows 实际验证

Windows Godot `4.7.2.stable.official.ed1daf0bf`，本机59次原生调用全部通过；四项测试因硬编码 Linux `/tmp/youjia-daily-check.*` 路径未在Windows运行，明确列于 `windows-combination/results.json`，不以此声称完整strict daily。

实际结果包括音频648/0、相册45914/0、通知168/0、短横屏标题1541、存档占用提示20、探索180/180、鱼携带94。每次独立存档目录由临时 `override.cfg` 配置，运行后删除该配置，不修改真实玩家存档；测试源代码不变。执行器见 `verify-windows-combination.ps1.txt`。

首轮稀疏检出遗漏 `art/concepts/producer_world_20261005/near_path_anchors.candidate.json`，探索测试产生SCRIPT ERROR却打印170项PASS，执行器按错误日志拒绝通过。补回精确HEAD原件（Git blob `f72b38d3a471dae421ee5d8949b1ab6c7f0c8ed3`），从失败项起重新执行并通过180/180；此前失败日志与结果保留，未改断言或删除失败证据。运行生成的import/UID变化已清理。

加载页Node检查、11项门禁错误捕获契约、11项包保留测试及存档模块发布辅助测试通过。Windows默认GBK导致的Python辅助测试失败日志保留，启用UTF-8后重跑通过；首次Node错误工作目录执行不计测试结果。

## Linux 完整门禁与候选 Web

独立验证分支 `work/codex-assistant/pr394-linux-validation`，SHA `a33a2407e32b8eb526caf93debbe675688be168b`，与上述运行候选只差新增验证工作流。该工作流 `contents: read`，仅测试、导出和上传证据，不运行发布脚本。完整工作流文本附本目录。

[Actions 37331415865](https://github.com/narutojzm1-dot/youjia/actions/runs/37331415865) 完成成功：63次引擎启动的未改strict daily、辅助检查与Web导出通过。原始日志见 `linux/`，记录见 `actions.json`。下载后19个导出文件与CI SHA256全部一致。

该71561导出包在Windows Chrome模拟横竖DPR3跑原普通输入驱动，62事件、18原始截图、errors0；覆盖三按钮的鼠标、触屏tap、500ms按住释放、拖出取消和Enter恢复，并读取真实后端与活动AudioParam。驱动仅增加DOM/WebAudio观测，不注入游戏成功状态；不是物理手机/真人听验。父代理实际查看横竖master-tap-off及竖屏music-drag-cancel原图。此批见 `browser-71561/` 与 `browser-71561.log`，驱动 `browser-local.py.txt` 仅将既有Linux Chromium路径改为本机Chrome路径。

### 最终主线组合

主线又增量至 `0c7f5d7283cdfd2412205b53653468c59ba3b544`，保留其许可证窗口适配/门禁、近郊清底、日结等，运行候选变为 `c35ffedda64e6f0b98b72f62ad5b8afa49c67df4`。旧71561证据不冒新组合。

最终验证分支 `c21f5a3f6c266e419ca567913405e62a06270c24` 与c35仍只差同一只读workflow，两个parent为c35及上次验证分支，未引入额外生产代码。[Actions 37333455347](https://github.com/narutojzm1-dot/youjia/actions/runs/37333455347) 已成功完成：**64次引擎启动完整未改strict daily**、两项发布辅助测试及Web导出。原始日志 `linux-final/`，结果 `actions-final.json`；下载后19个导出文件SHA256全部匹配。

最终c35导出包已用相同驱动、全新浏览器profile重跑：**62事件、18原始截图、errors0**，三按钮的上述全部输入路径与后端/实际活动增益断言通过。见 `browser-final/`、`browser-final.log`。父代理实际查看最终横屏master-tap-off、竖屏master-held-off与music-drag-cancel原图，UI状态与断言一致。最终包仍是本地候选，未称正式公开。

## 边界

候选验证不等于正式Pages发布。最终完整SHA独立审核、合入与公开包后验分别记录。#388仅音频按钮路由，不替代#382确认触摸；#195原并发快速输入、真机、真人听验、BFCache/长时/全心流保持开放。近期用户反馈#399/#400按用户指令由制作人跟进，不在本片重复接管。
