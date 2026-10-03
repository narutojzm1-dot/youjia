# QA-EXP-20261003-003 · Web 加载画面

Agent-ID: CODEX-LEAD-ASSISTANT。范围/认领：[issue167](https://github.com/narutojzm1-dot/youjia/issues/167)、[PR183](https://github.com/narutojzm1-dot/youjia/pull/183)。2026-10-04 北京时间，本记录为候选验证，正式发布证据合入后在实现 PR 补记。

## 变化与来源

仅修改 web/loading.html 的表现层：用现有晴天院子与暖纸遮罩替换模板科幻封面，文字/进度/按钮同游戏配色，错误长行可换行。JS启动协议字节完全相同，SHA256 `dcff609ba16d611b75e1e9b8539961ef3d959d492d5bdfcaae0e95a7da49aa7e`；版本标识、下载/未知总量/卡住提示、错误/重试、首帧握手与canvas焦点不变。

来源 `assets/holiday/environment/yard_sunny.png`，SHA256 `7f29181eac79c89b18eff65fe1a18c37230573b55f8c8993a0365dc480219d73`（沿用已批准资源和原仓库来源，不生成新画）。只转换为1280×720 JPEG、quality72、optimize：192,571 bytes，SHA256 `3a255dfacfff6125fe8100cf7d8cda8fbd1c0a74bfce7009cb35460bffbbf26d`，直接嵌入HTML，无额外图片网络请求。未压缩HTML从154,637变为355,887 bytes，净增201,250 bytes；实际传输取决于服务器压缩。PCK成本必须以正式包实测，不能将HTML净增冒称PCK净增。

## 测试来源

- 加载壳逻辑：`node test/loading_shell_test.cjs` PASS（字节进度、未知总量、卡住提示、首帧先后、错误类型）。`git diff --check`通过。
- 原生工具链：Godot4.7.2 headless正常Web导出 exit0；未重新做原生图形实玩，不把导出算全游戏回归。合入后现有CI完整回归另记。
- 浏览器受控壳：真实候选HTML/CSS，临时Engine桩控制进度与失败，不修改正式文件。1280×720、844×390、390×844的25%进度、失败详情及重试均实际绘制，所有可见标题/状态/详情/进度/按钮/构建标识包围盒均在视口内；点击重试真实导航成功；引擎就绪后仍保留壳、首帧事件到达后才隐藏，每种尺寸均通过。不是实际冷下载性能样本。
- 正常Web游戏：候选的真实Godot导出在1280×720浏览器等待首帧并点击进入院子，pageerror=[]。该次本地timings为engineScriptReady73ms、downloadComplete367ms、firstFrame/engineReady2392ms，受本地机器/热资源影响，不作为公网性能承诺。

受控实际截图（展示本切片，不作为正式上线证据）：

![桌面加载进度](2026-10-04-QA-EXP003-loading/desktop-progress.jpg)

![横屏失败与重试](2026-10-04-QA-EXP003-loading/landscape-failure.jpg)

![竖屏加载进度](2026-10-04-QA-EXP003-loading/portrait-progress.jpg)

## 后续门禁

最终完整SHA独立审核、CI完整回归/部署、公开manifest/HTML/PCK核对和公网冷加载画面仍须在实现PR记录。GAME-QA保留复测职责，父报告编号修订归原作者。本轮不是全游戏连续心流测试，不改变已获批准的体验边界。
