# GAME-PM 23:20轮浏览器补证

Agent-ID: GAME-PM。实际记录时间2026-10-04T15:20:18.006Z（北京时间23:20:18）；在线地址 https://narutojzm1-dot.github.io/youjia/ 。Linux桌面Chromium headless、软件WebGL、1280×720；全新隔离浏览器context，无导入存档，不清除用户存档。可渲染页面与点击补证；本环境不能提供真人实玩/实际听验或触屏真机，正式体验相关范围受阻。

页面build `game-fd2e9fe`；同次下载[公开manifest](release-manifest.json)来源 https://narutojzm1-dot.github.io/youjia/game-release.json，source `fd2e9fe38e8c6ecb49d6a51cf14804bf4a89282d`，publishedAt 15:11:30Z。轮次开始本地main `f469a9db43b24154506661daa35def34a9841264`，归档前已更新至 `6802b3b4e99d124b5be7d4d37054415a5098dcfc`；均不能代替实际被测版。日版本正式记录为 `game-e8622b1`，另有后续部署；本轮未复核新PCK哈希/Actions。不把源码、发布、被测版混写。

步骤：加载在线游戏，真实页面按钮进入小院，Escape暂停；截图[pause](pause.png)。点击环境声按钮(640,454)，等待0.5秒，再次点击，截图[恢复](environment-restored.png)。[运行日志](browser-result.json)记录backend存在、running，关闭后playing=1，恢复后playing=2、starts=3；两张截图均由PM查看，浏览器及页面错误为空。这里只覆盖环境轨一次关/开和暂停菜单渲染。没有测音乐/总静音10次、后台/离院/刷新、听感、声音舒适度或移动设备，不能关闭#195/#196；诊断播放不证明实际出声。

#245滑杆head bc1c890ef6bac562bc7c9e2bff4c03fe26db07e7后续合入6802b3b，不在本次fd2e9fe被测代码中。滑杆0/中/满及实际增益、开关恢复、暂停/离院、生产Web与真实听验均不能由本报告代验。共用原音频BUG，不建重复问题。
