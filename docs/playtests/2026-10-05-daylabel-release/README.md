# PR345 公开标签验收

实际公开 source `3de05fcbeb4c59c4b6da336c32f81c6eb1ad74fa` / HTML `game-3de05fc`，每组运行前分别读取并断言manifest及HTML（原始值在result.json）。四组390×844、844×390与DPR2/3全部完成，浏览器进程退出0，console/pageerror均空。独立全新context，正常首页点击入院、暂停、Escape恢复、普通坐标点击、旋转视口；不注入世界状态。截图CSS尺寸，实际DPR与canvas backing size记录在JSON。

四组yard/pause/resize共12帧已人工查看：标签深字浅纸位于暂停钮下同宽，无目标提示重叠，旋转后布局恢复正确。普通坐标不保证都命中同一动物，不以animal帧宣布全动物功能通过。

额外观察：844-390-dpr3-pause.png自动散步提示纸片在暂停期间覆盖面板下方；Escape恢复正常。此为范围外Toast/暂停层级待核，不能把标签通过扩成整个暂停UI无缺陷。未测试实体手机、Safari、英文浏览器、未合入探索入口。

本次仅公开浏览器最小回归，不重跑daily。PCK与十模块公开源哈希由Leader独立核验，不在本报告冒称执行。

## 发布来源核验与额外问题

PR345最终 `558fd93895420f6fa2afd4aa7be56f2750549f4f` 经独立 CODEX-LEAD-REVIEW-PR-345 [APPROVE](https://github.com/narutojzm1-dot/youjia/pull/345#issuecomment-5992328893) 后合main `3de05fcbeb4c59c4b6da336c32f81c6eb1ad74fa`。[Actions37294473168](https://github.com/narutojzm1-dot/youjia/actions/runs/37294473168) / [Pages37294934698](https://github.com/narutojzm1-dot/youjia/actions/runs/37294934698) 均成功。实际公开PCK 22,003,872字节，SHA256 `77babe34098bd49f529f377d2f560e5e1ed2bc7391c8e8e56fe58624980699cb`，与部署raw一致；十个save-3de05fc模块实际下载/source/manifest一致，见[原始报告](public-release.json)。文档随后合入不冒改变实际已体验构建。

亲看四组yard/pause/resize共12图，根代理另看竖屏DPR3与横屏DPR3暂停图。天数有纸底、位于暂停按钮下，与目标提示/交互按钮分离；自然暂停/恢复/旋转可用。只是这项标签验收，不意味着整个暂停UI没有问题：DPR3横屏自动散步提示覆盖暂停面板下方（[实际截图](844-390-dpr3-pause.png)），另建[缺陷#348](https://github.com/narutojzm1-dot/youjia/issues/348)交Assistant待接收，不能据图推断音频状态错误或归因345。

未覆盖：实体手机触控、Safari、尚未合入322探索入口共存。173项本地原生与完整daily/导出见[集成记录](../2026-10-05-daylabel-integration/README.md)；这里的四组浏览器确为公开构建，不用本地图冒公网上线。普通UI修复不重复发重大里程碑邮件，日版本汇总按既有制度。
